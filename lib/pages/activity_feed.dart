import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:in_circle/pages/home.dart';
import 'package:in_circle/pages/post_screen.dart';
import 'package:in_circle/pages/profile.dart';
import 'package:in_circle/constants.dart';
import 'package:in_circle/widgets/progress.dart';
import 'package:timeago/timeago.dart' as timeago;

class ActivityFeed extends StatefulWidget {
  @override
  _ActivityFeedState createState() => _ActivityFeedState();
}

class _ActivityFeedState extends State<ActivityFeed> {
  getActivityFeed() async {
    QuerySnapshot querySnapshot = await activityFeedRef
        .document(currentUser.id)
        .collection('feedItems')
        .orderBy('timestamp', descending: true)
        .limit(50)
        .getDocuments();

    querySnapshot.documents.forEach((DocumentSnapshot documentSnapshot) {
      activityFeedRef
          .document(currentUser.id)
          .collection('feedItems')
          .document(documentSnapshot.documentID)
          .updateData({
        'isSeen': true,
      });
    });

    List<ActivityFeedItem> feedItems = [];

    querySnapshot.documents.forEach((doc) {
      feedItems.add(ActivityFeedItem.fromDocument(doc));
    });
    return feedItems;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0.0,
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        title: Text(
          'Activity',
          style: TextStyle(
            color: kPrimaryColor,
            fontFamily: 'mont',
            fontWeight: FontWeight.bold,
            fontSize: 22.0,
          ),
        ),
      ),
      body: Container(
        child: FutureBuilder(
            future: getActivityFeed(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return circularProgress();
              }
              return ListView(
                children: snapshot.data,
              );
            }),
      ),
    );
  }
}

Widget mediaPreview;
String activityItemText;

class ActivityFeedItem extends StatelessWidget {
  final String username;
  final String userId;
  final String type; // like, follow, comment
  final String mediaUrl;
  final String postId;
  final String userProfileImage;
  final String commentData;
  final Timestamp timestamp;
  final bool isSeen;

  ActivityFeedItem({
    this.username,
    this.userId,
    this.type, // like, follow, comment
    this.mediaUrl,
    this.postId,
    this.userProfileImage,
    this.commentData,
    this.timestamp,
    this.isSeen,
  });

  factory ActivityFeedItem.fromDocument(DocumentSnapshot doc) {
    return ActivityFeedItem(
      username: doc['username'],
      userId: doc['userId'],
      type: doc['type'],
      mediaUrl: doc['mediaUrl'],
      postId: doc['postId'],
      userProfileImage: doc['userProfileImage'],
      commentData: doc['commentData'],
      timestamp: doc['timestamp'],
      isSeen: doc['isSeen'],
    );
  }

  configureMediaPreview(context) {
//    print('\n Median Url 2 $mediaUrl');
    if (type == 'like' || type == 'comment') {
      mediaPreview = GestureDetector(
        onTap: () => showPost(context, currentUser.id, postId),
        child: Container(
          height: 50.0,
          width: 50.0,
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: Container(
              decoration: BoxDecoration(
                  image: DecorationImage(
                      fit: BoxFit.cover,
                      image: CachedNetworkImageProvider(mediaUrl))),
            ),
          ),
        ),
      );
    } else {
      mediaPreview = Text('');
    }

    if (type == 'like') {
      activityItemText = 'Liked your Post';
    } else if (type == 'follow') {
      activityItemText = 'Started following you';
    } else if (type == 'comment') {
      activityItemText = 'Replied $commentData';
    } else {
      activityItemText = 'Error : Unknown type $type';
    }
  }

  @override
  Widget build(BuildContext context) {
    configureMediaPreview(context);

    return Padding(
      padding: EdgeInsets.only(bottom: 2.0),
      child: Column(
        children: <Widget>[
          Container(
            color: Colors.white54,
            child: ListTile(
              title: GestureDetector(
                onTap: () => showProfile(context, profileId: userId),
                child: RichText(
                  overflow: TextOverflow.ellipsis,
                  text: TextSpan(
                    style: TextStyle(
                      fontSize: 14.0,
                      color: Colors.black,
                      fontFamily: 'mont',
                    ),
                    children: [
                      TextSpan(
                        text: username,
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      TextSpan(
                        text: ' $activityItemText',
                      ),
                    ],
                  ),
                ),
              ),
              leading: GestureDetector(
                onTap: () => showProfile(context, profileId: userId),
                child: CircleAvatar(
                  backgroundImage: CachedNetworkImageProvider(userProfileImage),
                ),
              ),
              subtitle: Text(
                timeago.format(timestamp.toDate()),
                overflow: TextOverflow.ellipsis,
              ),
              trailing: mediaPreview,
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

  showPost(context, userId, postId) {
//    print('In showPost $postId and userId $userId');
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => PostScreen(
                  postId: postId,
                  userId: userId,
                )));
  }
}

showProfile(BuildContext context, {String profileId}) {
  Navigator.push(
    context,
    MaterialPageRoute(
        builder: (context) => Profile(
              profileId: profileId,
            )),
  );
}
