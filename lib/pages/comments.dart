import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:in_circle/constants.dart';
import 'package:in_circle/pages/home.dart';
import 'package:in_circle/widgets/progress.dart';
import 'package:timeago/timeago.dart' as timeago;

class Comments extends StatefulWidget {
  final String postId;
  final String postOwnerId;
  final String postMediaUrl;

  Comments({
    this.postId,
    this.postOwnerId,
    this.postMediaUrl,
  });

  @override
  _CommentsState createState() => _CommentsState(
        postId: this.postId,
        postOwnerId: this.postOwnerId,
        postMediaUrl: this.postMediaUrl,
      );
}

class _CommentsState extends State<Comments> {
  TextEditingController commentController = TextEditingController();
  final String postId;
  final String postOwnerId;
  final String postMediaUrl;

  _CommentsState({
    this.postId,
    this.postOwnerId,
    this.postMediaUrl,
  });

  buildComments() {
    return StreamBuilder(
      stream: commentsRef
          .document(postId)
          .collection('comments')
          .orderBy('timestamp', descending: false)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return circularProgress();
        }
        List<Comment> comments = [];
        snapshot.data.documents.forEach((doc) {
          comments.add(Comment.fromDocument(doc));
        });
        return ListView(
          children: comments,
        );
      },
    );
  }

  addComment() {
    commentsRef.document(postId).collection('comments').add({
      'username': currentUser.username,
      'comment': commentController.text,
      'timestamp': timestamp,
      'avatarUrl': currentUser.photoUrl,
      'userId': currentUser.id,
    });

    if (postOwnerId != currentUser.id) {
      activityFeedRef.document(postOwnerId).collection('feedItems').add({
        'type': 'comment',
        'commentData': commentController.text,
        'username': currentUser.username,
        'userId': currentUser.id,
        'userProfileImage': currentUser.photoUrl,
        'postId': postId,
        'mediaUrl': postMediaUrl,
        'timestamp': timestamp,
        'isSeen': false,
      });
    }

    commentController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        elevation: 0.0,
        title: Text(
          'Comments',
          style: TextStyle(
            color: kPrimaryColor,
            fontSize: 22.0,
            fontFamily: 'mont',
            fontWeight: FontWeight.w900,
          ),
        ),
        backgroundColor: Colors.white,
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: buildComments(),
          ),
          Divider(),
          ListTile(
            title: TextFormField(
              controller: commentController,
              decoration: InputDecoration(
                labelText: 'Write a comment...',
              ),
            ),
            trailing: OutlineButton(
              onPressed: () => addComment(),
              borderSide: BorderSide.none,
              child: Text(
                'Post',
                style: TextStyle(
                  fontFamily: 'mont',
                  fontSize: 18.0,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class Comment extends StatelessWidget {
  final String username;
  final String userId;
  final String avatarUrl;
  final String comment;
  final Timestamp timestamp;

  Comment({
    this.username,
    this.userId,
    this.timestamp,
    this.comment,
    this.avatarUrl,
  });

  factory Comment.fromDocument(DocumentSnapshot doc) {
    return Comment(
      username: doc['username'],
      userId: doc['userId'],
      avatarUrl: doc['avatarUrl'],
      comment: doc['comment'],
      timestamp: doc['timestamp'],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        ListTile(
          title: Text(comment),
          leading: CircleAvatar(
            backgroundImage: CachedNetworkImageProvider(avatarUrl),
          ),
          subtitle: Text(timeago.format(timestamp.toDate())),
        ),
        Divider(
          height: 1.0,
        )
      ],
    );
  }
}
