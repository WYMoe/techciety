import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:flutter/material.dart';
import 'package:fluttershare/models/user.dart';
import 'package:fluttershare/pages/edit_profile.dart';

import 'package:fluttershare/widgets/header.dart';
import 'package:fluttershare/widgets/post.dart';
import 'package:fluttershare/widgets/progress.dart';

import 'package:fluttershare/pages/home.dart' as home;
import 'package:fluttershare/services.dart' as services;
import 'post_screen.dart';
import 'package:fluttershare/widgets/custom_image.dart';

class Profile extends StatefulWidget {
  final String profileID;
  Profile({this.profileID});
  @override
  _ProfileState createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  Future<DocumentSnapshot> currentProfile;
  final String currentUserID =
      home.currentUser?.id; // get currentUser from Firestore through home class
  //final String currentUserID = services.googleSignIn.currentUser?.id; //get currentUser from googleSignIn account through services class
  List<Post> posts = [];
  bool isLoading = false;
  String postOrientation = 'default';
  bool isFollowing = false;
  int postCount = 0;
  int followingCount = 0;
  int followerCount = 0;
  @override
  void initState() {
    super.initState();

    getUserProfile();
    checkFollowing();
    getFollowerCount();
    getFollowingCount();
  }

  getUserProfile() async {
    setState(() {
      isLoading = true;
    });
    QuerySnapshot querySnapshot = await services.postsRef
        .document(widget.profileID)
        .collection('userPosts')
        .orderBy('timestamp', descending: true)
        .getDocuments();

    setState(() {
      querySnapshot.documents.forEach((doc) {
        posts.add(Post.fromDocument(doc));
      });
// posts = querySnapshot.documents.map((doc) {
//         return Post.fromDocument(doc);
//       }).toList();

      postCount = posts.length;
      isLoading = false;
    });
  }

  checkFollowing() async {
    DocumentSnapshot following = await services.followingRef
        .document(currentUserID)
        .collection('userFollowings')
        .document(widget.profileID)
        .get();

    setState(() {
      isFollowing = following.exists;
    });

    // check whether current user follows this profile
  }

  getFollowerCount() async {
    QuerySnapshot follower = await services.followerRef
        .document(widget.profileID)
        .collection('userFollowers')
        .getDocuments();
    setState(() {
      followerCount = follower.documents.length;
    });
  }

  getFollowingCount() async {
    QuerySnapshot following = await services.followingRef
        .document(widget.profileID)
        .collection('userFollowings')
        .getDocuments();
    setState(() {
      followingCount = following.documents.length;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: header(context, isAppTitleEnabled: true, text: 'Profile'),
        body: StreamBuilder<DocumentSnapshot>(
            stream: services.userRef.document(widget.profileID).snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return circularProgress();
              }

              User profile = User.fromDocument(snapshot.data);
              return ListView(
                children: <Widget>[
                  buildProfileHeader(profile),
                  buildTogglePost(),
                  buildProfilePost(),
                ],
              );
            }));
  }

  Widget buildProfileHeader(User profile) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            backgroundImage: NetworkImage(profile.photoUrl),
            radius: 38.00,
          ),
          SizedBox(
            height: 15.0,
          ),
          Column(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                profile.username,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 25.0),
              ),
              Text(
                profile.bio,
                style: TextStyle(
                  fontSize: 15.0,
                ),
                textAlign: TextAlign.center,
              )
            ],
          ),
          SizedBox(
            height: 20.0,
          ),
          Row(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Expanded(child: buildCountColumn('Follower', followerCount)),
              Expanded(child: buildCountColumn('Post', postCount)),
              Expanded(child: buildCountColumn('Following', followingCount))
            ],
          ),
          SizedBox(
            height: 20.0,
          ),
          Row(
            children: [Expanded(child: buildProfileButton())],
          )
        ],
      ),
    );
  }

  buildTogglePost() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: <Widget>[
        IconButton(
          icon: Icon(Icons.grid_on),
          onPressed: () {
            setState(() {
              postOrientation = 'default';
              buildProfilePost();
            });
          },
          color: postOrientation == 'default'
              ? Theme.of(context).primaryColor
              : Colors.grey,
        ),
        IconButton(
          icon: Icon(Icons.list),
          onPressed: () {
            setState(() {
              postOrientation = 'list';
              buildProfilePost();
            });
          },
          color: postOrientation == 'list'
              ? Theme.of(context).primaryColor
              : Colors.grey,
        )
      ],
    );
  }

  Widget buildProfilePost() {
    if (isLoading) {
      return circularProgress();
    } else if (posts.isEmpty) {
      return Column(
        children: [
          SizedBox(
            height: 5.0,
          ),
          Image.asset(
            'assets/images/no-photos.png',
            width: 50.0,
          ),
          Text('No posts')
        ],
      );
    }

    List<GridTile> gridTile = [];
    posts.forEach((post) {
      gridTile.add(GridTile(
        child: GestureDetector(
          onTap: () {
            //Navigator.pop(context);
            Navigator.push(context, MaterialPageRoute(builder: (context) {
              return PostScreen(
                userId: post.ownerId,
                postId: post.postId,

              );
            }));
          },
          child: cachedNetworkImage(post.mediaUrl),
        ),
      ));
    });

    return postOrientation == 'default'
        ? GridView.count(
            physics: NeverScrollableScrollPhysics(),
            crossAxisCount: 3,
            childAspectRatio: 1,
            crossAxisSpacing: 1.5,
            mainAxisSpacing: 1.5,
            shrinkWrap: true,
            children: gridTile,
          )
        : Column(
            children: posts,
          );
  }

  Column buildCountColumn(String label, int count) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Text(
          count.toString(),
          style: TextStyle(fontSize: 22.0, fontWeight: FontWeight.bold),
        ),
        Container(
          margin: EdgeInsets.only(top: 4.0),
          child: Text(
            label,
            style: TextStyle(
              color: Colors.grey,
              fontSize: 15.0,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      ],
    );
  }

  buildProfileButton() {
    if (widget.profileID == currentUserID) {
      return profileButton('Edit Profile', () {
        Navigator.push(context, MaterialPageRoute(builder: (context) {
          return EditProfile(
            currentUserID: currentUserID,
          );
        }));
      });
    } else if (isFollowing == false) {
      return profileButton('Follow', () {
        handleFollow();
      });
    } else if (isFollowing == true) {
      return profileButton('Unfollow', () {
        handleUnfollow();
      });
    }
  }

  profileButton(String label, Function function) {
    return Container(
      height: 40.0,
      margin: EdgeInsets.only(top: 10.0, left: 25.0, right: 25.0),
      child: FlatButton(
        onPressed: function,
        child: Text(
          label,
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(7.0),
          color: isFollowing ? Colors.grey : Colors.deepPurple),
    );
  }

  handleFollow() {
    setState(() {
      isFollowing = true;
    });

    // add to current user's following list
    services.followingRef
        .document(home.currentUser.id)
        .collection('userFollowings')
        .document(widget.profileID)
        .setData({});

    // add to OP's follower list
    services.followerRef
        .document(widget.profileID)
        .collection('userFollowers')
        .document(home.currentUser.id)
        .setData({});

    //add to OP's activity feed

    services.feedsRef
        .document(widget.profileID)
        .collection('feedItems')
        .document(home.currentUser.id)
        .setData({
      "type": "follow",
      "ownerId": widget.profileID,
      'username': home.currentUser.username,
      'userId': home.currentUser.id,
      'userProfileImg': home.currentUser.photoUrl,
      'timestamp': home.timestamp
    });
    followBackend();
    getFollowerCount();
    getFollowingCount();
  }

  followBackend() async {
    var postRef = Firestore.instance
        .collection('posts')
        .document(widget.profileID)
        .collection('userPosts');

    var timelineRef = Firestore.instance
        .collection('timeline')
        .document(home.currentUser.id)
        .collection('timelinePost');

    QuerySnapshot querySnapshot = await postRef.getDocuments();

    querySnapshot.documents.forEach((doc) {
      if (doc.exists) {
        var postId = doc.documentID;
        var postData = doc.data;

        timelineRef.document(postId).setData(postData);
      }
    });
  }

  unfollowBackend() async {
    var timelineRef = Firestore.instance
        .collection('timeline')
        .document(home.currentUser.id)
        .collection('timelinePost');

    QuerySnapshot querySnapshot = await Firestore.instance
        .collection('posts')
        .document(widget.profileID)
        .collection('userPosts')
        .getDocuments();

    querySnapshot.documents.forEach((doc) {
      if (doc.exists) {
        var postId = doc.documentID;

        timelineRef.document(postId).delete();
      }
    });
  }

  handleUnfollow() {
    setState(() {
      isFollowing = false;
    });

    // remove from current user's following list
    services.followingRef
        .document(home.currentUser.id)
        .collection('userFollowings')
        .document(widget.profileID)
        .delete();

    // remove from OP's follower list
    services.followerRef
        .document(widget.profileID)
        .collection('userFollowers')
        .document(home.currentUser.id)
        .delete();

    //remove from OP's activity feed

    services.feedsRef
        .document(widget.profileID)
        .collection('feedItems')
        .document(home.currentUser.id)
        .delete();
    unfollowBackend();
    getFollowerCount();
    getFollowingCount();
  }
}
