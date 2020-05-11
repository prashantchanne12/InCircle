import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:in_circle/main.dart';
import 'package:in_circle/model/user.dart';
import 'package:in_circle/pages/home.dart';
import 'package:in_circle/widgets/post.dart';
import 'package:in_circle/widgets/progress.dart';
import 'package:in_circle/constants.dart';

class Timeline extends StatefulWidget {
  final User user;

  Timeline({@required this.user});

  @override
  _TimelineState createState() => _TimelineState();
}

class _TimelineState extends State<Timeline> {
  List<dynamic> users = [];
  List<Post> posts = [];
  List<String> followingList = [];

  logout() async {
    await googleSignIn.signOut();
  }

  @override
  void initState() {
    super.initState();
    getFollowing();
  }

  getFollowing() async {
    QuerySnapshot querySnapshot = await followingRef
        .document(widget.user.id)
        .collection('userFollowing')
        .getDocuments();

    setState(() {
      followingList =
          querySnapshot.documents.map((doc) => doc.documentID).toList();
    });
  }

  buildTimeline() {
    if (posts == null) {
      return circularProgress();
    } else if (posts.isEmpty) {
      buildNoContent();
    }
    return StreamBuilder(
      stream: timelineRef
          .document(widget.user.id)
          .collection('timelinePosts')
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshots) {
        if (!snapshots.hasData) {
          return circularProgress();
        }
        List<Post> posts = [];
        snapshots.data.documents.forEach((DocumentSnapshot documentSnapshot) {
          posts.add(Post.fromDocument(documentSnapshot));
        });
        return posts.isEmpty
            ? buildNoContent()
            : ListView(
                children: posts,
              );
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
              'assets/images/notPost.svg',
              height: orientation == Orientation.portrait ? 300.0 : 200,
            ),
            Text(
              'Follow Your Friends To See Posts',
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(
          'InCircle',
          style: TextStyle(
            color: kPrimaryColor,
            fontFamily: 'mont',
            fontSize: 22.0,
            fontWeight: FontWeight.w900,
          ),
        ),
        elevation: 0.0,
      ),
      body: posts == null
          ? buildNoContent()
          : RefreshIndicator(
              onRefresh: () => buildTimeline(),
              child: buildTimeline(),
            ),
    );
  }
}
