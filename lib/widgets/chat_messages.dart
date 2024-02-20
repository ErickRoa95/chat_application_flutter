import 'package:chat_app/widgets/message_bubble.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ChatMessages extends StatelessWidget{
  const ChatMessages({super.key});

  @override
  Widget build(BuildContext context){
    final authenticatedUser = FirebaseAuth.instance.currentUser;

    return StreamBuilder(
      // Listener that will hear for any changes on chat collection.
      stream: FirebaseFirestore.instance
        .collection('chat').orderBy('createdAt', descending: true).snapshots(), 
      builder: (ctx,chatSnapshot){
        if(chatSnapshot.connectionState == ConnectionState.waiting){
          return const Center(
            child: CircularProgressIndicator(),
          );
        }
        // checking if chat collection is empty or not
        if (!chatSnapshot.hasData || chatSnapshot.data!.docs.isEmpty){
          return const Center(
            child: Text('No messages yet'),
          );
        }

        final loadedMessages = chatSnapshot.data!.docs;

        return ListView.builder(
          padding: const EdgeInsets.only(bottom:40, left: 13, right:13,),
          reverse: true, // push everything to the bottom
          itemBuilder: (ctx,index){
            final chatMessage = loadedMessages[index].data();
            final nextChatMessage = index + 1 < loadedMessages.length 
              ? loadedMessages[index + 1].data()
              : null ;

            final currentMessageId = chatMessage['userId'];
            final nextMessageId = nextChatMessage != null 
              ? nextChatMessage['userId']
              : null;

            final nextUserIsSame = currentMessageId == nextMessageId;

            if(nextUserIsSame){
              return MessageBubble.next(
                message: chatMessage['text'],
                isMe: chatMessage['userId'] == authenticatedUser!.uid,
              );
            }else{
              return MessageBubble.first(
                userImage: chatMessage['userImage'],
                username: chatMessage['username'],
                message: chatMessage['text'],
                isMe: chatMessage['userId'] == authenticatedUser!.uid,
              );
            }
          },
          itemCount: loadedMessages.length,
        );
      }
    );
  }
}