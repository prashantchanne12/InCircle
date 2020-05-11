import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:in_circle/constants.dart';
import 'package:in_circle/model/user.dart';
import 'package:in_circle/pages/profile.dart';
import 'package:in_circle/widgets/progress.dart';

import 'home.dart';

// TODO 2: Handle last active
// TODO 2.1 : Delete the chat tiles on unfollow
// TODO 3: UI update in upload, give confirmation that post is uploaded
// TODO 4: fix bug in create account
// TODO 5: Self Distructable on-off
// TODO 6: Check internet connectivity
// TODO 7: Add black theme
// TODO 8: Add security to firebase

class ChatScreen extends StatefulWidget {
  final String profileId;
  final String username;
  final String photoUrl;

  ChatScreen({
    this.profileId,
    this.username,
    this.photoUrl,
  });

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

final _firestore = Firestore.instance;

class _ChatScreenState extends State<ChatScreen> {
  String messageText;
  final messageTextController = TextEditingController();
  TextEditingController searchController = TextEditingController();
  Future<QuerySnapshot> searchResultsFuture;
  String chatId = '';
  bool getData = false;
  User chatUser;
  bool user1 = false;
  bool user2 = false;
  bool isSeen = false;

  @override
  void initState() {
    super.initState();
    userRef
        .document(widget.profileId)
        .get()
        .then((DocumentSnapshot documentSnapshot) {
      print('Receiver info called');
      User sender = User.fromDocument(documentSnapshot);
      setState(() {
        chatUser = sender;
      });
    });

    _firestore
        .collection('chat_tiles')
        .document(currentUser.id)
        .get()
        .then((DocumentSnapshot documentSnapshot) {
      print('user 1');
      if (!documentSnapshot.exists) {
        setState(() {
          user1 = false;
        });
      } else {
        setState(() {
          user1 = true;
        });
      }
    });

    _firestore
        .collection('chat_tiles')
        .document(widget.profileId)
        .get()
        .then((DocumentSnapshot documentSnapshot) {
      print('user 2');
      if (!documentSnapshot.exists) {
        setState(() {
          user2 = false;
        });
      } else {
        setState(() {
          user2 = true;
        });
      }
    });

    setState(() {
      getData = user1 && user2;
    });

    setState(() {
      isSeen = true;
    });
  }

  getOnline() {
    return StreamBuilder(
      stream: userRef.document(widget.profileId).snapshots(),
      builder: (context, snapshots) {
        if (!snapshots.hasData) {
          return circularProgress();
        }

        User _user = User.fromDocument(snapshots.data);
        return _user.online
            ? Row(
                children: <Widget>[
                  Container(
                    child: Icon(
                      Icons.brightness_1,
                      color: Colors.green[500],
                      size: 15.0,
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.only(left: 5.0),
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Active now',
                      style: TextStyle(
                        fontFamily: 'mont',
                        fontSize: 14.0,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ],
              )
            : Container(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Offline',
                  style: TextStyle(
                    fontFamily: 'mont',
                    fontSize: 14.0,
                    color: Colors.black,
                  ),
                ),
              );
      },
    );
  }

  buildNamedBar() {
    return AppBar(
      backgroundColor: Colors.white,
      automaticallyImplyLeading: false,
      elevation: 1.0,
      leading: IconButton(
        icon: Icon(Icons.arrow_back),
        onPressed: () {
          Navigator.pop(context);
        },
        color: kPrimaryColor,
      ),
      title: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => Profile(
                profileId: widget.profileId,
              ),
            ),
          );
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Text(
                  widget.username,
                  style: TextStyle(
                    color: kPrimaryColor,
                    fontFamily: 'mont',
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            getOnline(),
          ],
        ),
      ),
    );
  }

  clearSearch() {
    searchController.clear();
  }

  handleSearch(String query) {
    Future<QuerySnapshot> users = userRef
        .where('displayName', isGreaterThanOrEqualTo: query)
        .getDocuments();

    setState(() {
      searchResultsFuture = users;
    });
  }

  buildNoContent() {
    final Orientation orientation = MediaQuery.of(context).orientation;
    return Container(
      child: Center(
        child: ListView(
          shrinkWrap: true,
          children: <Widget>[
            SvgPicture.asset(
              'assets/images/search.svg',
              height: orientation == Orientation.portrait ? 300.0 : 200,
            ),
            Text(
              'Find Users To Chat',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: kPrimaryColor,
                  fontFamily: 'mont',
                  fontSize: 35.0,
                  fontWeight: FontWeight.w600),
            )
          ],
        ),
      ),
    );
  }

//  User chatUser;
//  getReceiverInfo() async {
//    print('getReciverInfo Called');
//    DocumentSnapshot documentSnapshot =
//        await userRef.document(widget.profileId).get();
//    User sender = User.fromDocument(documentSnapshot);
//    setState(() {
//      chatUser = sender;
//    });
//  }

  getChatTilesInfo() async {
    print('getChatTilesInfo Called');
    DocumentSnapshot documentUser = await _firestore
        .collection('chat_tiles')
        .document(currentUser.id)
        .get();

    DocumentSnapshot documentSender = await _firestore
        .collection('chat_tiles')
        .document(widget.profileId)
        .get();

    setState(() {
      getData = documentUser.exists && documentSender.exists;
    });
  }

  buildChatScreen() {
    // we are appending smaller to greater
    // -1 : first string is smaller
    //  1 : first string is greater and 2nd is smaller
    //  0 : both are equal
    if (currentUser.id.compareTo(widget.profileId) == -1) {
      setState(() {
        chatId = currentUser.id + widget.profileId;
      });
    } else {
      setState(() {
        chatId = widget.profileId + currentUser.id;
      });
    }
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        MessagesStream(
          profileId: widget.profileId,
          chatId: chatId,
        ),
        Container(
          decoration: kMessageContainerDecoration,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Expanded(
                child: TextField(
                  controller: messageTextController,
                  onChanged: (value) {
                    messageText = value;
                  },
                  style: TextStyle(color: Colors.black, fontFamily: 'mont'),
                  decoration: kMessageTextFieldDecoration,
                ),
              ),
              FlatButton(
                onPressed: () async {
                  messageTextController.clear();

                  if (getData) {
                    _firestore
                        .collection('messages')
                        .document(chatId)
                        .collection('chats')
                        .add({
                      'text': messageText,
                      'userId': currentUser.id,
                      'receiverId': widget.profileId,
                      'isSeen': false,
                      'time': FieldValue.serverTimestamp(),
                    });
                  } else {
                    _firestore
                        .collection('chat_tiles')
                        .document(currentUser.id)
                        .collection('chat_users')
                        .document(widget.profileId)
                        .setData({
                      'id': widget.profileId,
                      'time': FieldValue.serverTimestamp(),
                      'photoUrl': chatUser.photoUrl,
                      'username': chatUser.username,
                    });

                    _firestore
                        .collection('chat_tiles')
                        .document(widget.profileId)
                        .collection('chat_users')
                        .document(currentUser.id)
                        .setData({
                      'id': currentUser.id,
                      'time': FieldValue.serverTimestamp(),
                      'photoUrl': currentUser.photoUrl,
                      'username': currentUser.username,
                    });

                    _firestore
                        .collection('messages')
                        .document(chatId)
                        .collection('chats')
                        .add({
                      'text': messageText,
                      'userId': currentUser.id,
                      'receiverId': widget.profileId,
                      'isSeen': false,
                      'time': FieldValue.serverTimestamp(),
                    });

                    setState(() {
                      getData = true;
                    });
                  }
                },
                child: Text(
                  'Send',
                  style: kSendButtonTextStyle,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildNamedBar(),
      body: buildChatScreen(),
    );
  }
}

class MessagesStream extends StatelessWidget {
  final String profileId;
  final String chatId;

  MessagesStream({this.profileId, this.chatId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('messages')
          .document(chatId)
          .collection('chats')
          .orderBy('time', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        _firestore
            .collection('messages')
            .document(chatId)
            .collection('chats')
            .orderBy('time', descending: true)
            .where('isSeen', isEqualTo: true)
            .getDocuments()
            .then((QuerySnapshot querySnapshot) {
          querySnapshot.documents.forEach((DocumentSnapshot documentSnapshot) {
            Timer(Duration(seconds: 15), () {
              if (documentSnapshot.exists) {
                documentSnapshot.reference.delete();
              }
            });
          });
        });

        List<MessageBubble> messageBubbles = [];
        if (!snapshot.hasData) {
          return circularProgress();
        } else {
          snapshot.data.documents.forEach((DocumentSnapshot documentSnapshot) {
            final messageReceiver = documentSnapshot.data['receiverId'];
            if (messageReceiver == currentUser.id) {
              _firestore
                  .collection('messages')
                  .document(chatId)
                  .collection('chats')
                  .document(documentSnapshot.documentID)
                  .updateData({
                'isSeen': true,
              });
            }
          });

          snapshot.data.documents.forEach((DocumentSnapshot documentSnapshot) {
            final messageText = documentSnapshot.data['text'];
            final messageSender = documentSnapshot.data['userId'];
            final messageReceiver = documentSnapshot.data['receiverId'];
            final isSeen = documentSnapshot.data['isSeen'];

            final messageBubble = MessageBubble(
                text: messageText,
                sender: messageSender,
                isMe: currentUser.id == messageSender,
                isReceiver: messageReceiver == currentUser.id,
                isSeen: isSeen);
            messageBubbles.add(messageBubble);
          });
        }

        return Expanded(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 20.0, horizontal: 10.0),
            child: ListView(
              reverse: true,
              children: messageBubbles,
            ),
          ),
        );
      },
    );
  }
}

class MessageBubble extends StatelessWidget {
  final String sender;
  final String text;
  final bool isMe;
  final bool isReceiver;
  final bool isSeen;

  MessageBubble(
      {@required this.sender,
      @required this.text,
      @required this.isMe,
      @required this.isReceiver,
      @required this.isSeen});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(10.0),
      child: Column(
        crossAxisAlignment:
            isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: <Widget>[
          Material(
            elevation: 2.0,
            borderRadius: isMe
                ? BorderRadius.only(
                    topLeft: Radius.circular(30.0),
                    bottomLeft: Radius.circular(30.0),
                    bottomRight: Radius.circular(30.0))
                : BorderRadius.only(
                    topRight: Radius.circular(30.0),
                    bottomRight: Radius.circular(30.0),
                    bottomLeft: Radius.circular(30.0),
                  ),
            color: isMe ? kPrimaryColor : Colors.white,
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(vertical: 10, horizontal: 20.0),
              child: Text(
                text,
                style: TextStyle(
                  fontFamily: 'mont',
                  fontSize: 15.0,
                  color: isMe ? Colors.white : Colors.black,
                ),
              ),
            ),
          ),
          Container(
            padding: EdgeInsets.only(right: 5.0, top: 5.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: <Widget>[
                isSeen && isMe
                    ? Icon(
                        Icons.check_circle,
                        color: Colors.green,
                        size: 18.0,
                      )
                    : Container(
                        alignment: Alignment.centerRight,
                      ),
                isSeen == false && isMe == true
                    ? Icon(
                        Icons.check_circle_outline,
                        color: Colors.green,
                        size: 18.0,
                      )
                    : Container(
                        alignment: Alignment.centerRight,
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
