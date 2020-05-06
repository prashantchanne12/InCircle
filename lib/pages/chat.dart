import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:in_circle/constants.dart';
import 'package:in_circle/model/user.dart';
import 'package:in_circle/widgets/progress.dart';
import 'package:in_circle/pages/activity_feed.dart';

import 'home.dart';

class ChatScreen extends StatefulWidget {
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  TextEditingController searchController = TextEditingController();
  Future<QuerySnapshot> searchResultsFuture;

  buildSearchBar() {
    return AppBar(
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildSearchBar(),
      body:
          searchResultsFuture == null ? buildNoContent() : buildSearchResults(),
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
            height: 2.0,
          )
        ],
      ),
    );
  }
}
