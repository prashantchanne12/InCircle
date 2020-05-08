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
          return circularProgress();
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

  @override
  Widget build(BuildContext context) {
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
                title: Padding(
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
                leading: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: CircleAvatar(
                    backgroundColor: kPrimaryColor,
                    backgroundImage: CachedNetworkImageProvider(photoUrl),
                  ),
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(left: 10.0),
                  child: Text(
                    'Check out messages',
                    style: TextStyle(
                      fontFamily: 'mont',
                    ),
                  ),
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
  }
}

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
