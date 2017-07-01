import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/src/cupertino/button.dart';

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

class ChatScreen extends StatefulWidget {
  @override
  State createState() => new ChatScreenState ();
}

class ChatScreenState extends State<ChatScreen> with TickerProviderStateMixin {
  final TextEditingController _textController = new TextEditingController();
  final List<ChatMessage> _messages = <ChatMessage>[];

  Widget _createComposer() {
    return new IconTheme(
        data: new IconThemeData(color: Theme
            .of(context)
            .accentColor),
        child: new Container(
            margin: const EdgeInsets.symmetric(horizontal: 8.0),
            child: new Row (
              children: <Widget>[
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
                  child: new ListView.builder(
                      padding: new EdgeInsets.all(8.0),
                      reverse: true,
                      itemCount: _messages.length,
                      itemBuilder: (_, int index) => _messages[index]
                  )
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
    for (ChatMessage message in _messages) {
      message.animController.dispose();
    }
    super.dispose();
  }

  void _handleOnSubmitted(String value) {
    _textController.clear();

    setState(() {
      _isComposing = false;
    });


    ChatMessage message = new ChatMessage(
      text: value,
      animController: new AnimationController(
          vsync: this,
          duration: new Duration(microseconds: 1000)
      ),
    );
    setState(() {
      _messages.insert(0, message);
    });
    message.animController.forward();
  }
}

const String _name = "Your Name";
bool _isComposing = false;

class ChatMessage extends StatelessWidget {
  ChatMessage({this.text, this.animController});

  final String text;
  final AnimationController animController;

  @override
  Widget build(BuildContext context) {
    return new FadeTransition(
        opacity: new CurvedAnimation(
            parent: animController,
            curve: Curves.fastOutSlowIn),
      child: new Container(
        margin: new EdgeInsets.symmetric(vertical: 10.0),
        child: new Row (
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            new Container(
              margin: new EdgeInsets.only(right: 16.0),
              child: new CircleAvatar(
                child: new Text (_name [0]),
              ),
            ),
            new Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                new Text(_name, style: Theme
                    .of(context)
                    .textTheme
                    .subhead),
                new Container(
                  margin: const EdgeInsets.only(top: 5.0),
                  child: new Text(text),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }


}