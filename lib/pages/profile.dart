import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:flutter_svg/svg.dart';
import 'package:in_circle/constants.dart';
import 'package:in_circle/model/user.dart';
import 'package:in_circle/pages/follow_user_lists.dart';
import 'package:in_circle/pages/home.dart';
import 'package:in_circle/pages/post_screen.dart';
import 'package:in_circle/widgets/post.dart';
import 'package:in_circle/widgets/post_tile.dart';
import 'package:in_circle/widgets/progress.dart';
import 'package:in_circle/pages/edit_profile.dart';
import 'package:in_circle/widgets/post_profile.dart';
import 'package:in_circle/pages/chat.dart';

class Profile extends StatefulWidget {
  final String profileId;

  Profile({@required this.profileId});

  @override
  _ProfileState createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  bool isFollowing = false;
  bool isLoading = false;
  String postOrientation = "grid";
  int postCount = 0;
  int followerCount = 0;
  int followingCount = 0;
  List<PostProfile> posts = [];
  List<Post> postGrid = [];
  Firestore _firestore;

  @override
  void initState() {
    super.initState();
    getProfilePosts();
    checkIfFollowing();
    _firestore = Firestore.instance;
  }

  checkIfFollowing() async {
    DocumentSnapshot documentSnapshot = await followersRef
        .document(widget.profileId)
        .collection('userFollowers')
        .document(currentUserId)
        .get();

    setState(() {
      isFollowing = documentSnapshot.exists;
    });
  }

  getProfilePosts() async {
    setState(() {
      isLoading = true;
    });

    QuerySnapshot querySnapshot = await postRef
        .document(widget.profileId)
        .collection('userPosts')
        .orderBy('timestamp', descending: true)
        .getDocuments();

    setState(() {
      isLoading = false;
      postCount = querySnapshot.documents.length;

      // posts - list containing objects of Post class
      posts = querySnapshot.documents
          .map((DocumentSnapshot documentSnapshot) =>
              PostProfile.fromDocument(documentSnapshot))
          .toList();
//      print(posts);

      postGrid = querySnapshot.documents
          .map((DocumentSnapshot documentSnapshot) =>
              Post.fromDocument(documentSnapshot))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
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
      body: Column(
        children: <Widget>[
          Padding(
            padding: EdgeInsets.only(top: 0.0),
            child: buildProfileHeader(),
          ),
          Padding(
            padding: EdgeInsets.only(top: 15.0),
            child: buildCounts(),
          ),
          Padding(
            padding: EdgeInsets.only(top: 10.0, bottom: 0.0),
            child: buildTogglePostOrientation(),
          ),
          Expanded(
            child: buildProfilePosts(),
          )
        ],
      ),
    );
  }

  User user;

//  buildProfilePosts()
  buildProfileHeader() {
    return StreamBuilder(
      stream: userRef.document(widget.profileId).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return circularProgress();
        } else {
          user = User.fromDocument(snapshot.data);

          return Padding(
            padding: const EdgeInsets.only(left: 25.0),
            child: Row(
              children: <Widget>[
                Container(
                  child: CircleAvatar(
                    radius: 45.0,
                    backgroundImage: NetworkImage(user.photoUrl),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Container(
                      padding: EdgeInsets.only(left: 40.0),
                      alignment: Alignment.center,
                      child: Text(
                        user.displayName,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontFamily: 'mont',
                            fontSize: 20.0,
                            color: Colors.black,
                            fontWeight: FontWeight.w900),
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.only(left: 40.0, top: 3.0),
                      alignment: Alignment.center,
                      child: Text(
                        user.username,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontFamily: 'mont',
                            fontSize: 18.0,
                            color: Colors.grey,
                            fontWeight: FontWeight.w900),
                      ),
                    ),
                    Row(
                      children: <Widget>[
                        buildProfileButton(),
                        isFollowing ? buildMessageButton() : Text(''),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          );
        }
      },
    );
  }

  buildMessageButton() {
    return Padding(
      padding: const EdgeInsets.only(top: 10.0),
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChatScreen(
                profileId: widget.profileId,
                username: user.username,
                photoUrl: user.photoUrl,
              ),
            ),
          );
        },
        child: Container(
          width: 45.0,
          height: 45.0,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(50.0),
          ),
          child: Icon(
            Icons.mail,
            size: 20.0,
            color: kPrimaryColor,
          ),
        ),
      ),
    );
  }

  buildProfileButton() {
    bool isProfileOwner = widget.profileId == currentUser.id;
    if (isProfileOwner) {
      return buildButton(text: 'Edit Profile', function: handleEditProfile);
    } else if (isFollowing) {
      return buildButton(text: 'Unfollow', function: handleUnFollowUsers);
    } else if (!isFollowing) {
      return buildButton(text: 'Follow', function: handleFollowUsers);
    }
  }

  Container buildButton({String text, Function function}) {
    return Container(
      padding: EdgeInsets.only(top: 10.0, left: 20.0),
      child: FlatButton(
        onPressed: function,
        child: Container(
          width: 130.0,
          height: 35.0,
          child: Text(
            text,
            style: TextStyle(
              color: isFollowing ? Colors.black : Colors.white,
              fontFamily: 'mont',
              fontSize: 16.0,
              fontWeight: FontWeight.bold,
            ),
          ),
          decoration: BoxDecoration(
            color: isFollowing ? Colors.white : kPrimaryColor,
            border: Border.all(
              color: isFollowing ? Colors.grey : kPrimaryColor,
            ),
            borderRadius: BorderRadius.circular(20.0),
          ),
          alignment: Alignment.center,
        ),
      ),
    );
  }

  buildProfilePosts() {
    if (isLoading) {
      return circularProgress();
    } else if (posts.isEmpty) {
      return ListView(
        children: <Widget>[
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              SvgPicture.asset(
                'assets/images/notPost.svg',
                height: 260.0,
              ),
              Padding(
                padding: EdgeInsets.only(top: 40.0),
                child: Text(
                  'No Post',
                  style: TextStyle(
                      color: kPrimaryColor,
                      fontFamily: 'Mont',
                      fontWeight: FontWeight.bold,
                      fontSize: 30.0),
                ),
              ),
            ],
          ),
        ],
      );
    } else if (postOrientation == 'grid') {
      List<GridTile> gridTiles = [];
      postGrid.forEach((post) {
        gridTiles.add(GridTile(child: PostTile(post)));
      });

      return GridView.count(
        crossAxisCount: 3,
        childAspectRatio: 1.0,
        mainAxisSpacing: 1.5,
        crossAxisSpacing: 1.5,
        shrinkWrap: true,
        physics: NeverScrollableScrollPhysics(),
        children: gridTiles,
      );
    } else {
//      return Column(
//        children: posts,
//        );
      int indexCount = 0;
      print(posts.length);
//      print(posts[1]);
      return StaggeredGridView.countBuilder(
        shrinkWrap: true,
        crossAxisCount: 4,
        padding: EdgeInsets.all(5.0),
//        shrinkWrap: true,
        itemCount: posts.length,
        itemBuilder: (BuildContext context, int index) {
          print(indexCount);
          return GestureDetector(
            onTap: () {
              showPost(context, posts[index].postId, posts[index].ownerId);
            },
            child: Container(
              alignment: Alignment.center,
              padding: EdgeInsets.only(left: 10.0, right: 10.0, top: 10.0),
              child: posts[index],
            ),
          );
        },
        staggeredTileBuilder: (int index) {
          indexCount = index + 1;
//          print(indexCount);
          return indexCount % 3 != 0
              ? StaggeredTile.count(2, 2)
              : StaggeredTile.count(4, 3);
        },
        mainAxisSpacing: 0.0,
        crossAxisSpacing: 0.0,
      );
    }
  }

  String currentUserId = currentUser?.id;

  handleFollowUsers() {
    setState(() {
      isFollowing = true;
    });

    // Add user to that user's follower collection
    followersRef
        .document(widget.profileId)
        .collection('userFollowers')
        .document(currentUserId)
        .setData({
      'id': currentUserId,
      'displayName': currentUser.displayName,
      'photoUrl': currentUser.photoUrl,
      'username': currentUser.username,
    });

    // Update user's following collection
    followingRef
        .document(currentUserId)
        .collection('userFollowing')
        .document(widget.profileId)
        .setData({
      'id': user.id,
      'displayName': user.displayName,
      'photoUrl': user.photoUrl,
      'username': user.username,
    });

    // add activity feed item for that user to notify about new follower
    activityFeedRef
        .document(widget.profileId)
        .collection('feedItems')
        .document(currentUserId)
        .setData({
      'type': 'follow',
      'ownerId': widget.profileId,
      'username': currentUser.username,
      'userId': currentUserId,
      'userProfileImage': currentUser.photoUrl,
      'timestamp': timestamp,
      'isSeen': false,
    });
  }

  handleUnFollowUsers() {
    setState(() {
      isFollowing = false;
    });

    // remove user from that user's follower collection
    followersRef
        .document(widget.profileId)
        .collection('userFollowers')
        .document(currentUserId)
        .get()
        .then((doc) {
      if (doc.exists) {
        doc.reference.delete();
      }
    });

    // remove user from following collection
    followingRef
        .document(currentUserId)
        .collection('userFollowing')
        .document(widget.profileId)
        .get()
        .then((doc) {
      if (doc.exists) {
        doc.reference.delete();
      }
    });

    // delete activity feed item for them
    activityFeedRef
        .document(widget.profileId)
        .collection('feedItems')
        .document(currentUserId)
        .get()
        .then((doc) {
      if (doc.exists) {
        doc.reference.delete();
      }
    });

    // delete user from chat tiles
    _firestore
        .collection('chat_tiles')
        .document(currentUserId)
        .collection('chat_users')
        .document(widget.profileId)
        .get()
        .then((doc) {
      if (doc.exists) {
        doc.reference.delete();
      }
    });
  }

  buildCounts() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: <Widget>[
        buildPostColumns('Posts', postCount),
        InkWell(
          onTap: () {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => FollowList(
                          profileId: widget.profileId,
                          isFollow: true,
                        )));
          },
          child: buildCountColumns('Followers'),
        ),
        InkWell(
          onTap: () {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => FollowList(
                          profileId: widget.profileId,
                          isFollow: false,
                        )));
          },
          child: buildCountColumns('Following'),
        ),
      ],
    );
  }

  buildPostColumns(String label, int count) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Text(
          count.toString(),
          style: TextStyle(
            fontSize: 22.0,
            fontWeight: FontWeight.bold,
            fontFamily: 'mont',
          ),
        ),
        Container(
          child: Text(
            label,
            style: TextStyle(
              color: Colors.black54,
              fontSize: 15.0,
              fontWeight: FontWeight.w400,
              fontFamily: 'mont',
            ),
          ),
        ),
      ],
    );
  }

  buildCountColumns(String label) {
    return StreamBuilder(
      stream: label == 'Followers'
          ? followersRef
              .document(widget.profileId)
              .collection('userFollowers')
              .snapshots()
          : followingRef
              .document(widget.profileId)
              .collection('userFollowing')
              .snapshots(),
      builder: (context, snapshots) {
        if (!snapshots.hasData) {
          return CircularProgressIndicator(
            backgroundColor: kPrimaryColor,
          );
        }
        int count = snapshots.data.documents.length;
        return Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              count.toString(),
              style: TextStyle(
                fontSize: 22.0,
                fontWeight: FontWeight.bold,
                fontFamily: 'mont',
              ),
            ),
            Container(
              child: Text(
                label,
                style: TextStyle(
                  color: Colors.black54,
                  fontSize: 15.0,
                  fontWeight: FontWeight.w400,
                  fontFamily: 'mont',
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  setPostOrientation(String postOrientation) {
    setState(() {
      this.postOrientation = postOrientation;
    });
  }

  buildTogglePostOrientation() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: <Widget>[
        IconButton(
          onPressed: () => setPostOrientation('grid'),
          icon: Icon(
            Icons.grid_on,
            color: postOrientation == 'grid' ? kPrimaryColor : Colors.grey,
          ),
        ),
        IconButton(
          onPressed: () => setPostOrientation('list'),
          icon: Icon(
            Icons.list,
            color: postOrientation == 'list' ? kPrimaryColor : Colors.grey,
          ),
        ),
      ],
    );
  }

  showPost(context, postId, ownerId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PostScreen(
          postId: postId,
          userId: ownerId,
        ),
      ),
    );
  }

  handleEditProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => EditProfile(currentUserId: currentUserId)),
    );
  }
}
