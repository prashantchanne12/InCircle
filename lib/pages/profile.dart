import 'package:flutter/material.dart';
import 'package:in_circle/constants.dart';
import 'package:in_circle/model/user.dart';
import 'package:in_circle/pages/home.dart';
import 'package:in_circle/widgets/progress.dart';

class Profile extends StatefulWidget {
  final String profileId;

  Profile({@required this.profileId});

  @override
  _ProfileState createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  bool isFollowing = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: <Widget>[
          buildProfileHeader(),
        ],
      ),
    );
  }

  buildProfileHeader() {
    return StreamBuilder(
      stream: userRef.document(widget.profileId).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return circularProgress();
        } else {
          User user = User.fromDocument(snapshot.data);

          return Padding(
            padding: const EdgeInsets.only(top: 60.0, left: 20.0),
            child: Row(
              children: <Widget>[
                Container(
                  child: CircleAvatar(
                    radius: 50.0,
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
                            fontSize: 25.0,
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
                            fontSize: 20.0,
                            color: Colors.grey,
                            fontWeight: FontWeight.w900),
                      ),
                    ),
                    buildProfileButton(),
                  ],
                ),
              ],
            ),
          );
        }
      },
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
          width: 160.0,
          height: 40.0,
          child: Text(
            text,
            style: TextStyle(
              color: isFollowing ? Colors.black : Colors.white,
              fontFamily: 'mont',
              fontSize: 17.0,
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

  handleUnFollowUsers() {}

  handleFollowUsers() {}

  handleEditProfile() {}
}
