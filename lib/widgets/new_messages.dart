import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class NewMessages extends StatefulWidget{
  const NewMessages({super.key});

  @override
  State<NewMessages> createState() => _NewMessagesState(); 
}

class _NewMessagesState extends State<NewMessages>{
  var _messageController = TextEditingController();

  @override
  void dispose() {
    // TODO: implement dispose
    _messageController.dispose();
    super.dispose();
  }

  void _submitMessage() async {
    // close keyboard after sending message.
    FocusScope.of(context).unfocus();

    final enteredMessage = _messageController.text;

    if(enteredMessage.trim().isEmpty){
      return;
    }
    //send to Firebase
    final currentUser = FirebaseAuth.instance.currentUser!;
    final userDocument = await FirebaseFirestore.instance.collection('users')
      .doc(currentUser.uid).get();
    FirebaseFirestore.instance.collection('chat')
      .add({
        'text': enteredMessage,
        'createdAt': Timestamp.now(),
        'userId': currentUser.uid,
        'username': userDocument.data()!['username'],
        'userImage': userDocument.data()!['image_url']
      });
    // clear input after sending message. 
    _messageController.clear();
  }
  
  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Padding(
      padding: const EdgeInsets.only(left: 15, right: 1, bottom: 14),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: const InputDecoration(labelText: 'Send a message...'),
              textCapitalization: TextCapitalization.sentences,
              autocorrect: true,
              enableSuggestions: true,
            ),
          ),
          IconButton(
            color: Theme.of(context).colorScheme.primary,
            icon: const Icon(Icons.send),
            onPressed: _submitMessage,
          ),
        ]
      ),
    );
  }
}