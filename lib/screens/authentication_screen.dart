import 'dart:io';

import 'package:chat_app/widgets/user_image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';

final _firebase = FirebaseAuth.instance;

class AuthScreen extends StatefulWidget{
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState()=> _AuthScreenState(); 
}

class _AuthScreenState extends State<AuthScreen>{
  var _isLogin = true; //login mode 
  final _formKey = GlobalKey<FormState>();
  var _enteredEmail = '';
  var _enteredPassword = '';  
  var _enteredUsername = '';
  File? _userImageSelected;
  var _isAuthenticating = false;

  void _submit() async {
    final isValid = _formKey.currentState!.validate(); // formKey get current status of Form. 
    if(!isValid || !_isLogin && _userImageSelected == null){
      return;
    }

    _formKey.currentState!.save(); // formKey save the current status of Form. 
    try {
      setState(() {
        _isAuthenticating = true;
      });

      if (_isLogin){
        // Log user in
        final userCredentials = await _firebase.signInWithEmailAndPassword(email: _enteredEmail, password: _enteredPassword);
        print(userCredentials);
      }else{ //sign up method
        final userCredentials = await _firebase.createUserWithEmailAndPassword(
          email: _enteredEmail, 
          password: _enteredPassword
        );
        // Upload file to Firebase Storage
        final storageRef = FirebaseStorage.instance.ref()
          .child('user_images').child('${userCredentials.user!.uid}.jpg');
        await storageRef.putFile(_userImageSelected!);
        final imageUrl = await storageRef.getDownloadURL();
        print(imageUrl);
        await FirebaseFirestore.instance.collection('users')
          .doc(userCredentials.user!.uid).set({
            'image_url':imageUrl,
            'username': _enteredUsername,
            'email': _enteredEmail,
          });
      }
    } on FirebaseAuthException catch(err){
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(err.message ?? 'Authentication Failed.' ),
        )
      );
      setState(() {
        // This stop the laoding spinner and enable the buttons. 
        _isAuthenticating = false;
      });
    }
  }
  @override
  Widget build(BuildContext context){
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primary,
      appBar: AppBar(
        title: const Text('FlutterChat'),
      ),
      body:  Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                margin: const EdgeInsets.only(
                  top:30,
                  bottom:20,
                  left: 20, 
                  right: 20
                ),
                width: 200,
                child:  Image.asset('assets/images/chat.png'),
              ),
              Card(
                margin: const EdgeInsets.all(20),
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (!_isLogin ) UserImagePicker(onPickImage: (pickedImage){
                                _userImageSelected = pickedImage;
                          }),
                          TextFormField(
                            decoration: const InputDecoration(
                              labelText: 'Email Address'
                            ),
                            autocorrect: false,
                            keyboardType: TextInputType.emailAddress,
                            textCapitalization: TextCapitalization.none,
                            validator:(value){
                              if(value == null || value.trim().isEmpty || !value.contains('@')){
                                return 'Please enter a valid email address';
                              }
                              return null;                            
                            },
                            onSaved: (newValue) => _enteredEmail = newValue!,
                          ),
                          if (!_isLogin)
                            TextFormField(
                              validator: (value){
                                if (value == null || value.isEmpty || value.trim().length < 4){
                                  return 'Valid Username of at least 4 characters';
                                }
                                return null;
                              },
                              enableSuggestions: false,
                              decoration: const InputDecoration(
                                labelText: 'Username'
                              ),
                              onSaved: (newValue) => _enteredUsername = newValue!,
                            ),
                          TextFormField(
                            decoration: const InputDecoration(
                              labelText: 'Password'
                            ),
                            obscureText: true,
                            validator: (value){
                              if(value == null || value.trim().isEmpty || value.length < 7){
                                return 'Password must be at least 7 characters long';
                              }
                              return null;
                            },
                            onSaved: (newValue) => _enteredPassword = newValue!,
                          ),
                          const SizedBox(height: 12),
                          if (_isAuthenticating ) const CircularProgressIndicator(), 
                          if (!_isAuthenticating)
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                              ),
                              onPressed: _submit,
                              child: Text(_isLogin 
                                ? 'Login'
                                : 'Sign-up'
                              ),
                            ),
                         if (!_isAuthenticating)
                          TextButton(
                              onPressed: (){
                                setState(() {
                                  _isLogin = !_isLogin;
                                });
                              },
                              child: Text(_isLogin 
                                ? 'Create an account'
                                : 'I already have an account'
                              ),
                            ),
                        ],
                      )
                    )
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}