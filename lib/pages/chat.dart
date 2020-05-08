import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:in_circle/constants.dart';
import 'package:in_circle/model/user.dart';
import 'package:in_circle/pages/profile.dart';
import 'package:in_circle/widgets/progress.dart';

import 'home.dart';

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

  buildSearchBar() {
    return AppBar(
      backgroundColor: Colors.white,
      automaticallyImplyLeading: false,
      elevation: 1.0,
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
        child: Text(
          widget.username,
          style: TextStyle(
            color: kPrimaryColor,
            fontFamily: 'mont',
            fontWeight: FontWeight.w900,
          ),
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

  bool getData = true;
  User chatUser;
  getReceiverInfo() async {
    DocumentSnapshot documentSnapshot =
        await userRef.document(widget.profileId).get();
    User sender = User.fromDocument(documentSnapshot);
    setState(() {
      chatUser = sender;
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
                  await getReceiverInfo();
                  messageTextController.clear();

                  DocumentSnapshot documentUser = await _firestore
                      .collection('chat_tiles')
                      .document(currentUser.id)
                      .get();

                  DocumentSnapshot documentSender = await _firestore
                      .collection('chat_tiles')
                      .document(widget.profileId)
                      .get();

                  if (documentSender.exists && documentUser.exists) {
                    _firestore
                        .collection('messages')
                        .document(chatId)
                        .collection('chats')
                        .add({
                      'text': messageText,
                      'userId': currentUser.id,
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
                      'time': FieldValue.serverTimestamp(),
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
      appBar: buildSearchBar(),
      body: buildChatScreen(),
//          searchResultsFuture == null ? buildNoContent() : buildSearchResults(),
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
        List<MessageBubble> messageBubbles = [];
        if (!snapshot.hasData) {
          return circularProgress();
        } else {
          final messages = snapshot.data.documents;

          for (var message in messages) {
            final messageText = message.data['text'];
            final messageSender = message.data['userId'];

            final messageBubble = MessageBubble(
              text: messageText,
              sender: messageSender,
              isMe: currentUser.id == messageSender,
            );
            messageBubbles.add(messageBubble);
          }
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

  MessageBubble(
      {@required this.sender, @required this.text, @required this.isMe});
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
        ],
      ),
    );
  }
}
