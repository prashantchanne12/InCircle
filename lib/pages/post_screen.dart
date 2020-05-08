import 'package:flutter/material.dart';
import 'package:in_circle/pages/home.dart';
import 'package:in_circle/widgets/progress.dart';
import 'package:in_circle/widgets/post.dart';
import 'package:in_circle/widgets/header.dart';

class PostScreen extends StatelessWidget {
  final String userId;
  final String postId;

  PostScreen({this.userId, this.postId});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: postRef
          .document(userId)
          .collection('userPosts')
          .document(postId)
          .get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return circularProgress();
        }
        Post post = Post.fromDocument(snapshot.data);
        print('In post screen $postId anf $post');
        return Center(
          child: Scaffold(
            appBar: header(
              context,
              title: post.desc,
            ),
            body: ListView(
              children: <Widget>[
                Container(
                  child: post,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
