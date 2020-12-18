import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fluttershare/models/user.dart';
import 'package:fluttershare/pages/home.dart';
import 'package:fluttershare/pages/profile.dart';
import 'package:fluttershare/pages/search.dart';
import 'package:fluttershare/widgets/header.dart';
import 'package:fluttershare/widgets/post.dart';
import 'package:fluttershare/widgets/progress.dart';
import 'package:fluttershare/services.dart' as services;
import 'package:flutter_icons/flutter_icons.dart';
import 'package:cached_network_image/cached_network_image.dart';

final usersRef = Firestore.instance.collection('user');

class Timeline extends StatefulWidget {
  final String currentUserId;

  Timeline({this.currentUserId});

  @override
  _TimelineState createState() => _TimelineState();
}

class _TimelineState extends State<Timeline> {
  List<Post> posts;
  List<String> followingList = [];

  @override
  void initState() {
    super.initState();
    //getTimeline();
    getFollowing();
  }

  getTimeline() async {
    QuerySnapshot snapshot = await Firestore.instance
        .collection('timeline')
        .document(widget.currentUserId)
        .collection('timelinePost')
        .orderBy('timestamp', descending: true)
        .getDocuments();
    List<Post> posts =
        snapshot.documents.map((e) => Post.fromDocument(e)).toList();

    setState(() {
      this.posts = posts;
    });
    print(posts);
  }

  getFollowing() async {
    QuerySnapshot snapshot = await services.followingRef
        .document(widget.currentUserId)
        .collection('userFollowings')
        .getDocuments();
    setState(() {
      followingList = snapshot.documents.map((doc) => doc.documentID).toList();
    });
  }

  buildTimeline() {
    return StreamBuilder<QuerySnapshot>(
        stream: Firestore.instance
            .collection('timeline')
            .document(widget.currentUserId)
            .collection('timelinePost')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return CircularProgressIndicator();
          }
          posts =
              snapshot.data.documents.map((e) => Post.fromDocument(e)).toList();

          if (posts == null) {
            return circularProgress();
          } else if (posts.isEmpty) {
            return buildUsersToFollow();
          }
          return ListView(
            children: posts,
          );
        });
//    return ListView(
//      children: posts,
//    );
  }

  buildUsersToFollow() {
    return StreamBuilder(
      stream:
          usersRef.orderBy('timestamp', descending: true).limit(30).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return circularProgress();
        }
        List<UserToFollow> userResults = [];
        snapshot.data.documents.forEach((doc) {
          User user = User.fromDocument(doc);
          final bool isAuthUser = currentUser.id == user.id;
          final bool isFollowingUser = followingList.contains(user.id);
          // remove auth user from recommended list
          if (isAuthUser) {
            return;
          } else if (isFollowingUser) {
            return;
          } else {
            UserToFollow userResult = UserToFollow(
              user: user,
            );
            userResults.add(userResult);
          }
        });
        return Container(
          // color: Theme.of(context).accentColor.withOpacity(0.2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                margin: EdgeInsets.all(15.0),
                padding: EdgeInsets.all(20.0),
                decoration: BoxDecoration(
                    border: Border.all(color: Colors.deepPurple),
                    borderRadius: BorderRadius.circular(15.0)),
                child: Text(
                  'Follow Your Friends To See Their Timeline',
                  style: TextStyle(
                    color: Theme.of(context).primaryColor,
                    fontSize: 20.0,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              GridView.count(
                crossAxisCount: 2,
                childAspectRatio: 1,
                crossAxisSpacing: 1.5,
                mainAxisSpacing: 1.5,
                shrinkWrap: true,
                children: userResults,
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(context) {
    return Scaffold(
        appBar: header(context,
            isAppTitleEnabled: true, backButtonRemove: true, text: 'Timeline'),
        body: RefreshIndicator(
            onRefresh: () => getTimeline(), child: buildTimeline()));
  }
}

class UserToFollow extends StatelessWidget {
  final User user;
  UserToFollow({this.user});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) {
          return Profile(
            profileID: user.id,
          );
        }));
      },
      child: Card(
        margin: EdgeInsets.all(15.0),
        color: Colors.deepPurple,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
        elevation: 5.0,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: <Widget>[
            CircleAvatar(
              backgroundImage: CachedNetworkImageProvider(user.photoUrl),
              radius: 30.0,
            ),
            Text(
              user.username,
              style: TextStyle(color: Colors.white, fontSize: 20.0),
            )
          ],
        ),
      ),
    );
  }
}
