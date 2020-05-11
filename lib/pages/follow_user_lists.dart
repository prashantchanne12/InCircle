import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:in_circle/constants.dart';
import 'package:in_circle/pages/home.dart';
import 'package:in_circle/pages/profile.dart';
import 'package:in_circle/widgets/progress.dart';

class FollowList extends StatefulWidget {
  final String profileId;
  final bool isFollow;

  FollowList({@required this.profileId, @required this.isFollow});

  @override
  _FollowListState createState() => _FollowListState();
}

class _FollowListState extends State<FollowList> {
  buildFollowers() {
    return FutureBuilder(
      future: widget.isFollow
          ? followersRef
              .document(widget.profileId)
              .collection(widget.isFollow ? 'userFollowers' : 'userFollowing')
              .getDocuments()
          : followingRef
              .document(widget.profileId)
              .collection(widget.isFollow ? 'userFollowers' : 'userFollowing')
              .getDocuments(),
      builder: (context, snapshots) {
        if (!snapshots.hasData) {
          return circularProgress();
        }
        List<UserTile> userTiles = [];
        snapshots.data.documents.forEach((DocumentSnapshot documentSnapshot) {
          userTiles.add(UserTile.fromDocument(documentSnapshot));
        });
        return ListView(
          children: userTiles,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0.0,
        automaticallyImplyLeading: false,
        title: Text(
          widget.isFollow ? 'Followers' : 'Followings',
          style: TextStyle(
            color: kPrimaryColor,
            fontFamily: 'mont',
            fontSize: 22.0,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: buildFollowers(),
    );
  }
}

class UserTile extends StatelessWidget {
  final String displayName;
  final String username;
  final String photoUrl;
  final String id;

  UserTile({
    this.displayName,
    this.photoUrl,
    this.username,
    this.id,
  });

  factory UserTile.fromDocument(DocumentSnapshot doc) {
    return UserTile(
      id: doc['id'],
      username: doc['username'],
      photoUrl: doc['photoUrl'],
      displayName: doc['displayName'],
    );
  }
  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        GestureDetector(
          onTap: () {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => Profile(profileId: id)));
          },
          child: ListTile(
            title: Container(
              padding: EdgeInsets.only(left: 10.0),
              child: Text(
                displayName,
                style: TextStyle(fontFamily: 'mont'),
              ),
            ),
            leading: CircleAvatar(
              backgroundImage: CachedNetworkImageProvider(photoUrl),
            ),
            subtitle: Container(
              padding: EdgeInsets.only(left: 10.0),
              child: Text(
                username,
                style: TextStyle(fontFamily: 'mont'),
              ),
            ),
          ),
        ),
        Divider(
          height: 1.0,
        ),
      ],
    );
  }
}
