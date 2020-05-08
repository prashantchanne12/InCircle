import 'dart:async';

import 'package:animator/animator.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:in_circle/model/user.dart';
import 'package:in_circle/pages/comments.dart';
import 'package:in_circle/pages/home.dart';

import 'custom_image.dart';
import 'progress.dart';

class PostProfile extends StatefulWidget {
  final String postId;
  final String ownerId; // owner of the post
  final String username;
  final String location;
  final String desc;
  final String mediaUrl;
  final dynamic likes;

  PostProfile({
    this.postId,
    this.ownerId,
    this.username,
    this.location,
    this.desc,
    this.mediaUrl,
    this.likes,
  });

  factory PostProfile.fromDocument(DocumentSnapshot documentSnapshot) {
    return PostProfile(
      postId: documentSnapshot['postId'],
      ownerId: documentSnapshot['ownerId'],
      username: documentSnapshot['username'],
      location: documentSnapshot['location'],
      desc: documentSnapshot['desc'],
      mediaUrl: documentSnapshot['mediaUrl'],
      likes: documentSnapshot['likes'],
    );
  }

  int getLikeCount(likes) {
//    If there are no likes we will return 0
    if (likes == null) {
      return 0;
    } else {
      int count = 0;
      likes.values.forEach((val) {
        if (val == true) {
          count = count + 1;
        }
      });
      return count;
    }
  }

  @override
  _PostProfileState createState() => _PostProfileState(
      postId: this.postId,
      ownerId: this.ownerId,
      username: this.username,
      location: this.location,
      desc: this.desc,
      mediaUrl: this.mediaUrl,
      likes: this.likes,
      likeCount: this.getLikeCount(this.likes));
}

class _PostProfileState extends State<PostProfile> {
  final String currentUserId = currentUser?.id;
  final String postId;
  final String ownerId;
  final String username;
  final String location;
  final String desc;
  final String mediaUrl;
  bool showHeart = false;
  int likeCount;
  Map likes;
  bool isLiked;

  _PostProfileState(
      {this.postId,
      this.ownerId,
      this.username,
      this.location,
      this.desc,
      this.mediaUrl,
      this.likes,
      this.likeCount});

  @override
  Widget build(BuildContext context) {
    isLiked = (likes[currentUserId] == true);

    return Container(
      child: buildPostImage(),
    );
  }

  buildPostHeader() {
    return FutureBuilder(
      future: userRef.document(ownerId).get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return circularProgress();
        } else {
          User user = User.fromDocument(snapshot.data);
          bool isPostOwner = currentUserId == ownerId;
          return ListTile(
            leading: CircleAvatar(
              backgroundImage: CachedNetworkImageProvider(user.photoUrl),
              backgroundColor: Colors.grey,
            ),
            title: GestureDetector(
              onTap: () => print(
                  'Show Profile'), //showProfile(context, profileId: user.id)
              child: Text(
                user.username,
                style: TextStyle(
                  fontFamily: 'mont',
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            subtitle: Text(
              location,
              style: TextStyle(fontFamily: 'mont'),
            ),
            trailing: isPostOwner
                ? IconButton(
                    onPressed: () => handleDeletePost(context),
                    icon: Icon(
                      Icons.more_vert,
                      color: Colors.black,
                    ),
                  )
                : Text(""),
          );
        }
      },
    );
  }

  handleDeletePost(BuildContext parentContext) {
    return showDialog(
        context: parentContext,
        builder: (context) {
          return SimpleDialog(
            title: Text('Remove this post?'),
            children: <Widget>[
              SimpleDialogOption(
                onPressed: () {
                  Navigator.pop(context);
                  deletePost();
                },
                child: Text(
                  'Delete',
                  style: TextStyle(
                    fontFamily: 'mont',
                    color: Colors.red,
                  ),
                ),
              ),
              SimpleDialogOption(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Cancel',
                  style: TextStyle(
                    fontFamily: 'mont',
                  ),
                ),
              ),
            ],
          );
        });
  }

  deletePost() async {
    // 1) delete the post
    postRef
        .document(ownerId)
        .collection('userPosts')
        .document(postId)
        .get()
        .then((doc) {
      if (doc.exists) {
        doc.reference.delete();
      }
    });

    // 2) delete the post from storage
    storageRef.child('posts').child('post_$postId.jpg').delete();

    // 3) delete all activity feed notification
    QuerySnapshot activityFeedSnapshot = await activityFeedRef
        .document(ownerId)
        .collection('feedItems')
        .where('postId', isEqualTo: postId)
        .getDocuments();

    activityFeedSnapshot.documents.forEach((doc) {
      if (doc.exists) {
        doc.reference.delete();
      }
    });

    // 4) delete all comments
    QuerySnapshot commentsSnapshot = await commentsRef
        .document(postId)
        .collection('comments')
        .getDocuments();

    commentsSnapshot.documents.forEach((doc) {
      if (doc.exists) {
        doc.reference.delete();
      }
    });
  }

  buildPostImage() {
    return GestureDetector(
      onDoubleTap: () => handleLikePost(),
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          ClipRRect(
              borderRadius: BorderRadius.circular(10.0),
              child: cachedNetworkImage(mediaUrl)),
          showHeart
              ? Animator(
                  duration: Duration(milliseconds: 300),
                  tween: Tween(begin: 0.8, end: 1.4),
                  curve: Curves.elasticOut,
                  cycles: 0,
                  builder: (anim) => Transform.scale(
                    scale: anim.value,
                    child: Icon(
                      Icons.favorite,
                      size: 80.0,
                      color: Colors.red,
                    ),
                  ),
                )
              : Text(''),
        ],
      ),
    );
  }

  handleLikePost() {
    bool _isLiked = likes[currentUserId] == true;

    if (_isLiked) {
      postRef
          .document(ownerId)
          .collection('userPosts')
          .document(postId)
          .updateData({'likes.$currentUserId': false});

      removeLikeFromActivityFeed();

      setState(() {
        isLiked = false;
        likeCount -= 1;
        likes[currentUserId] = false;
      });
    } else if (!_isLiked) {
      postRef
          .document(ownerId)
          .collection('userPosts')
          .document(postId)
          .updateData({'likes.$currentUserId': true});

      addLikeToActivityFeed();

      setState(() {
        isLiked = true;
        likeCount += 1;
        likes[currentUserId] = true;
        showHeart = true;
      });
      Timer(Duration(milliseconds: 500), () {
        setState(() {
          showHeart = false;
        });
      });
    }
  }

  removeLikeFromActivityFeed() {
    bool isNotPostOwner = currentUserId != ownerId;

    if (isNotPostOwner) {
      activityFeedRef
          .document(ownerId)
          .collection('feedItems')
          .document(postId)
          .get()
          .then((doc) {
        if (doc.exists) {
          doc.reference.delete();
        }
      });
    }
  }

  addLikeToActivityFeed() {
    // add a notification to the post owner feed only if the comment made by other
    // other user avoid getting notification for our own like
    bool isNotPostOwner = currentUserId != ownerId;

    if (isNotPostOwner) {
      activityFeedRef
          .document(ownerId)
          .collection('feedItems')
          .document(postId)
          .setData({
        'type': 'like',
        'username': currentUser.username,
        'userId': currentUserId,
        'userProfileImage': currentUser.photoUrl,
        'postId': postId,
        'mediaUrl': mediaUrl,
        'timestamp': timestamp
      });
    }
  }

  buildPostFooter() {
    return Column(
      children: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            Padding(
              padding: EdgeInsets.only(top: 30, left: 20.0),
            ),
            GestureDetector(
              child: Icon(
                isLiked ? Icons.favorite : Icons.favorite_border,
                size: 28.0,
                color: Colors.pink,
              ),
              onTap: () => handleLikePost(),
            ),
            Padding(
              padding: EdgeInsets.only(top: 30, right: 20.0),
            ),
            GestureDetector(
              child: Icon(
                Icons.chat_bubble_outline,
                size: 28.0,
                color: Colors.deepPurple,
              ),
              onTap: () => showComments(
                context,
                postId: postId,
                ownerId: ownerId,
                mediaUrl: mediaUrl,
              ),
            ),
          ],
        ),
        Row(
          children: <Widget>[
            Container(
              margin: EdgeInsets.only(left: 20.0),
              child: Text(
                '$likeCount likes',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'mont',
                ),
              ),
            ),
          ],
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              margin: EdgeInsets.only(left: 20.0),
              child: Text(
                '$username',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'mont',
                ),
              ),
            ),
            Expanded(
              child: Text(
                desc,
                style: TextStyle(
                  fontFamily: 'mont',
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  showComments(BuildContext context,
      {String postId, String ownerId, String mediaUrl}) {
    Navigator.push(context, MaterialPageRoute(builder: (context) {
      return Comments(
        postId: postId,
        postOwnerId: ownerId,
        postMediaUrl: mediaUrl,
      );
    }));
  }
}
