import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:in_circle/constants.dart';
import 'package:in_circle/model/user.dart';
import 'package:in_circle/pages/activity_feed.dart';
import 'package:in_circle/pages/home.dart';
import 'package:in_circle/widgets/progress.dart';
import 'package:in_circle/pages/chat.dart';

class ChatTiles extends StatefulWidget {
  @override
  _ChatTilesState createState() => _ChatTilesState();
}

Firestore _firestore = Firestore.instance;

class _ChatTilesState extends State<ChatTiles> {
  TextEditingController searchController = TextEditingController();
  Future<QuerySnapshot> searchResultsFuture;
  bool isSearch = false;

  getChatUsers() async {
    QuerySnapshot querySnapshot = await chatTilesRef
        .document(currentUser.id)
        .collection('chat_users')
        .orderBy('time', descending: true)
        .getDocuments();

    List<ChatTilesItem> chatTiles = [];

    querySnapshot.documents.forEach((DocumentSnapshot documentSnapshot) {
      chatTiles.add(ChatTilesItem.fromDocument(documentSnapshot));
    });

    return chatTiles;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: isSearch ? buildSearchBar() : buildNamedAppbar(),
      body: isSearch && searchResultsFuture != null
          ? buildSearchResults()
          : FutureBuilder(
              future: getChatUsers(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return circularProgress();
                }
                return ListView(
                  children: snapshot.data,
                );
              },
            ),
    );
  }

// searchResultsFuture == null ? buildNoContent() : buildSearchResults(),

  buildNamedAppbar() {
    return AppBar(
      elevation: 0.0,
      backgroundColor: Colors.white,
      automaticallyImplyLeading: false,
      title: Text(
        'Chats',
        style: TextStyle(
          fontFamily: 'mont',
          fontSize: 22.0,
          color: kPrimaryColor,
          fontWeight: FontWeight.bold,
        ),
      ),
      actions: <Widget>[
        Padding(
          padding: const EdgeInsets.only(right: 10.0),
          child: IconButton(
            icon: Icon(
              Icons.search,
              size: 28.0,
              color: kPrimaryColor,
            ),
            onPressed: () {
              setState(() {
                isSearch = true;
              });
            },
          ),
        ),
      ],
    );
  }

  buildSearchBar() {
    return AppBar(
        elevation: 1.0,
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        title: TextFormField(
          controller: searchController,
          decoration: InputDecoration(
            hintStyle: TextStyle(
              fontFamily: 'mont',
            ),
            hintText: 'Search for a user',
            filled: true,
            prefixIcon: Icon(
              Icons.search,
              color: kPrimaryColor,
              size: 28.0,
            ),
            suffixIcon: IconButton(
              icon: Icon(
                Icons.clear,
                color: kPrimaryColor,
              ),
              onPressed: clearSearch,
            ),
          ),
          onFieldSubmitted: handleSearch,
        ));
  }

  clearSearch() {
    searchController.clear();
    setState(() {
      isSearch = false;
    });
  }

  handleSearch(String query) {
    Future<QuerySnapshot> users = userRef
        .where('displayName', isGreaterThanOrEqualTo: query)
        .getDocuments();

    setState(() {
      searchResultsFuture = users;
    });
  }

  buildSearchResults() {
    return FutureBuilder(
      future: searchResultsFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return CircularProgressIndicator();
        } else {
          List<UserResult> searchResults = [];
          snapshot.data.documents.forEach((doc) {
            User user = User.fromDocument(doc);
            UserResult userResult = UserResult(user);
            searchResults.add(userResult);
          });
          return ListView(
            children: searchResults,
          );
        }
      },
    );
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
}

class ChatTilesItem extends StatelessWidget {
  final String id;
  final String username;
  final String photoUrl;

  ChatTilesItem({
    this.id,
    this.username,
    this.photoUrl,
  });

  factory ChatTilesItem.fromDocument(DocumentSnapshot doc) {
    return ChatTilesItem(
      id: doc['id'],
      username: doc['username'],
      photoUrl: doc['photoUrl'],
    );
  }

  /*
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
   */

  getRecentChat() {
    String chatId = '';
    // we are appending smaller to greater
    // -1 : first string is smaller
    //  1 : first string is greater and 2nd is smaller
    //  0 : both are equal
    if (currentUser.id.compareTo(id) == -1) {
      chatId = currentUser.id + id;
    } else {
      chatId = id + currentUser.id;
    }
    return StreamBuilder(
      stream: _firestore
          .collection('messages')
          .document(chatId)
          .collection('chats')
          .where('isSeen', isEqualTo: false)
          .snapshots(),
      builder: (context, snapshots) {
        if (!snapshots.hasData) {
          return Text(
            'Checking...',
            style: TextStyle(fontFamily: 'mont'),
          );
        } else {
          int count = 0;
          snapshots.data.documents.forEach((DocumentSnapshot documentSnapshot) {
            final messageReceiver = documentSnapshot.data['receiverId'];
            if (messageReceiver == currentUser.id) {
              count = count + 1;
            }
          });
          return RichText(
            text: TextSpan(
              style: TextStyle(fontFamily: 'mont', color: Colors.black54),
              children: <TextSpan>[
                TextSpan(
                    text: count == 0 ? 'No' : '$count',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                TextSpan(text: ' new messages'),
              ],
            ),
          );
        }
      },
    );
  }

  /*
  Text(
            count == 0 ? 'No new messagses' : '$count new Messages',
            style: TextStyle(fontFamily: 'mont', color: Colors.black),
          );
   */

/*
RichText(
  text: TextSpan(
    text: 'Hello ',
    style: DefaultTextStyle.of(context).style,
    children: <TextSpan>[
      TextSpan(text: 'bold', style: TextStyle(fontWeight: FontWeight.bold)),
      TextSpan(text: ' world!'),
    ],
  ),
)
 */

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: userRef.document(id).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return circularProgress();
        }
        User _user = User.fromDocument(snapshot.data);
        return Padding(
          padding: EdgeInsets.only(bottom: 2.0),
          child: Column(
            children: <Widget>[
              Container(
                color: Colors.white,
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => ChatScreen(
                                  profileId: id,
                                  username: username,
                                  photoUrl: photoUrl,
                                )));
                  },
                  child: ListTile(
                    title: Row(
                      children: <Widget>[
                        Padding(
                          padding: const EdgeInsets.only(left: 10.0),
                          child: Text(
                            username,
                            style: TextStyle(
                              fontFamily: 'mont',
                              fontSize: 18.0,
                              color: Colors.black,
                            ),
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.only(left: 4.0),
                          child: _user.online == true
                              ? Icon(
                                  Icons.brightness_1,
                                  color: Colors.green[500],
                                  size: 15.0,
                                )
                              : Text(''),
                        ),
                      ],
                    ),
                    leading: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: CircleAvatar(
                        backgroundColor: kPrimaryColor,
                        backgroundImage: CachedNetworkImageProvider(photoUrl),
                      ),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(left: 10.0),
                      child: getRecentChat(),
                    ),
                  ),
                ),
              ),
              Divider(
                color: Colors.blueGrey,
                height: 1.0,
              ),
            ],
          ),
        );
      },
    );
  }
}

//   User _user;
//    userRef.document(id).get().then((DocumentSnapshot documentSnapshot) {
//      _user = User.fromDocument(documentSnapshot);
//      print(_user.displayName);
//    });
//    print(_user);

class UserResult extends StatelessWidget {
  final User user;

  UserResult(this.user);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Column(
        children: <Widget>[
          GestureDetector(
            onTap: () {
              showProfile(context, profileId: user.id);
            },
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.grey,
                backgroundImage: CachedNetworkImageProvider(user.photoUrl),
              ),
              title: Text(
                user.displayName,
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Text(
                user.username,
                style: TextStyle(
                  color: Colors.black,
                ),
              ),
            ),
          ),
          Divider(
            color: Colors.white54,
            height: 1.0,
          )
        ],
      ),
    );
  }
}
