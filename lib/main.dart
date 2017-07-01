import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/src/cupertino/button.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'dart:async';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_database/ui/firebase_animated_list.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

import 'dart:math';
import 'dart:io';


final google_sign_in =  new GoogleSignIn();
final analytics = new FirebaseAnalytics();
final auth = FirebaseAuth.instance;
final messageRef = FirebaseDatabase.instance.reference().child("messages");
const String _name = "Your Name";
bool _isComposing = false;

void main() {
  runApp(new ChatApp());
}

final ThemeData IOSTHEME  = new ThemeData(
  primarySwatch: Colors.orange,
  primaryColor: Colors.grey[100],
  primaryColorBrightness: Brightness.light
);

final ThemeData DefaultTheme =  new ThemeData(
  primarySwatch: Colors.purple,
  accentColor: Colors.orangeAccent [400],
);

class ChatApp extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      title: 'SimpleChat',
      theme: defaultTargetPlatform == TargetPlatform.iOS         //new
          ? IOSTHEME                                              //new
          : DefaultTheme,
      home: new ChatScreen (),
    );
  }
}

Future<Null> _checkLogin () async {
  GoogleSignInAccount user = google_sign_in.currentUser;
  if (user == null) {
    user = await google_sign_in.signInSilently();
  }
  if (user == null) {
    await google_sign_in.signIn();
    analytics.logLogin();
  }
  if (auth.currentUser == null) {
    GoogleSignInAuthentication credentials =
        await google_sign_in.currentUser.authentication;
    await auth.signInWithGoogle(
        idToken: credentials.idToken,
        accessToken: credentials.accessToken
    );
  }

}


class ChatScreen extends StatefulWidget {
  @override
  State createState() => new ChatScreenState ();
}

class ChatScreenState extends State<ChatScreen> {
  final TextEditingController _textController = new TextEditingController();
  Widget _createComposer() {
    return new IconTheme(
        data: new IconThemeData(color: Theme
            .of(context)
            .accentColor),
        child: new Container(
            margin: const EdgeInsets.symmetric(horizontal: 8.0),
            child: new Row (
              children: <Widget>[
                new Container (
                  margin: new EdgeInsets.symmetric(horizontal: 4.0),
                  child: new IconButton(
                      icon: new Icon(Icons.photo_camera),
                      onPressed: () async {
                        await _checkLogin();
                        File imageFile = await ImagePicker.pickImage();
                        int random = new Random ().nextInt(100000);
                        StorageReference storageRef = FirebaseStorage
                            .instance.ref().child("image_$random.jpg");
                        StorageUploadTask task = storageRef.put(imageFile);
                        Uri downloadUrl = (await task.future).downloadUrl;
                        _sendMessage(mediaUrl: downloadUrl.toString());
                      }),
                ),
                new Flexible(child: new TextField(
                  controller: _textController,
                  onChanged: (String text) {
                    setState(() {
                      _isComposing = text.length > 0;
                    });
                  },
                  onSubmitted: _handleOnSubmitted,
                  decoration: new InputDecoration.collapsed(
                      hintText: 'Type a message'),
                ),
                ),
                new Container(
                  margin: new EdgeInsets.symmetric(horizontal: 4.0),
                  child: Theme.of(context).platform == TargetPlatform.iOS ?
                    new CupertinoButton (
                      child: new Text('Send'),
                      onPressed: _isComposing ? () =>  _handleOnSubmitted(_textController.text)
                          : null,)
                    :
                    new IconButton(
                        icon: new Icon(Icons.send),
                        onPressed: _isComposing ? () =>
                            _handleOnSubmitted(_textController.text)
                            : null),
                )
              ],
            )
        )
    );
  }


  @override
  Widget build(BuildContext context) {
    return new Scaffold(
        appBar: new AppBar(
            title: new Text('Simple Chat'),
            elevation: Theme.of(context).platform == TargetPlatform.iOS ? 0.0 : 4.0,
        ),
        body: new Container(
          child: new Column(
            children: <Widget>[
              new Flexible(
                  child: new FirebaseAnimatedList(
                      query: messageRef,
                      sort: (a, b) => b.key.compareTo(a.key),
                      padding: new EdgeInsets.all(8.0),
                      reverse: true,
                      itemBuilder: (_, DataSnapshot snapshot, Animation<double> animation) {
                        return new ChatMessage(
                          snapshot :snapshot,
                          animation: animation,
                        );
                      }
                  ),
              ),
              new Divider(height: 1.0,),
              new Container(
                decoration: new BoxDecoration(
                    color: Theme.of(context).cardColor
                ),
                child: _createComposer(),
              )
            ],
          ),
          decoration: Theme.of(context).platform == TargetPlatform.iOS
            ? new BoxDecoration (border : new Border (top: new BorderSide (color : Colors.grey [200])))
            : null,
        )
    );
  }


  @override
  void dispose() {
    super.dispose();
  }

  Future<Null> _handleOnSubmitted(String value) async {
    _textController.clear();

    setState(() {
      _isComposing = false;
    });


    await _checkLogin();
    _sendMessage(text: value);
  }

  void _sendMessage({String text, String mediaUrl}) {
    messageRef.push().set({
        'text':text,
        'senderName':google_sign_in.currentUser.displayName,
        'profileUrl':google_sign_in.currentUser.photoUrl,
        'mediaUrl':mediaUrl
    });
    analytics.logEvent(name: "Send Message");
  }
}

class ChatMessage extends StatelessWidget {
  ChatMessage({this.snapshot, this.animation});

  final DataSnapshot snapshot;
  final Animation animation;

  @override
  Widget build(BuildContext context) {
    return new SizeTransition(
        sizeFactor: new CurvedAnimation(
            parent: animation,
            curve: Curves.easeInOut),
      child: new Container(
        margin: new EdgeInsets.symmetric(vertical: 10.0),
        child: new Row (
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            new Container(
              margin: new EdgeInsets.only(right: 16.0),
              child: new GoogleUserCircleAvatar(snapshot.value["profileUrl"]),
            ),
            new Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                new Text(snapshot.value["senderName"], style: Theme
                    .of(context)
                    .textTheme
                    .subhead),
                new Container(
                  margin: const EdgeInsets.only(top: 5.0),
                  child: snapshot.value['mediaUrl']!= null ?
                  new Image.network (
                    snapshot.value['mediaUrl'],
                    width: 250.0,
                  ):
                  new Text(snapshot.value['text']),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}