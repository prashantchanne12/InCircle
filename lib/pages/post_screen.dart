import 'package:flutter/material.dart';
import 'package:in_circle/constants.dart';
import 'package:in_circle/pages/home.dart';
import 'package:in_circle/widgets/progress.dart';
import 'package:in_circle/widgets/post.dart';

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
//        print('In post screen $postId anf $post');
        return Center(
          child: Scaffold(
            appBar: AppBar(
              elevation: 0.0,
              automaticallyImplyLeading: false,
              title: Text(
                userId == currentUser.id ? 'You Posted' : 'InCircle',
                style: TextStyle(
                  color: kPrimaryColor,
                  fontWeight: FontWeight.w900,
                  fontSize: 22.0,
                  fontFamily: 'mont',
                ),
              ),
              leading: (IconButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                icon: Icon(
                  Icons.arrow_back,
                  color: kPrimaryColor,
                ),
              )),
            ),
            body: ListView(
              children: <Widget>[
                Container(
                  child: post,
                ),
                SizedBox(
                  height: 10.0,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
