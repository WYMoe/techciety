import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fluttershare/pages/post_screen.dart';
import 'package:fluttershare/widgets/header.dart';
import 'package:fluttershare/services.dart' as services;
import 'package:fluttershare/widgets/progress.dart';
import 'home.dart' as home;

class ActivityFeed extends StatefulWidget {
  @override
  _ActivityFeedState createState() => _ActivityFeedState();
}

class _ActivityFeedState extends State<ActivityFeed> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: header(context, isAppTitleEnabled: true, text: 'Activity Feed'),
        body: StreamBuilder<QuerySnapshot>(
          stream: services.feedsRef
              .document(home.currentUser.id)
              .collection('feedItems')
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return circularProgress();
            }

            List<ActivityFeedItem> activityFeedItems =
                snapshot.data.documents.map((doc) {
              return ActivityFeedItem.fromDocument(doc);
            }).toList();

            if (activityFeedItems.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      'assets/images/disable-alarm.png',
                      width: 200.0,
                    ),
                    SizedBox(
                      height: 20.0,
                    ),
                    Text('No Activity')
                  ],
                ),
              );
            }

            return ListView(
              children: activityFeedItems,
            );
          },
        ));
  }
}

class ActivityFeedItem extends StatelessWidget {
  final String username;
  final String userId;
  final String type; // 'like', 'follow', 'comment'
  final String mediaUrl;
  final String postId;
  final String userProfileImg;
  final String commentData;
  final Timestamp timestamp;

  ActivityFeedItem({
    this.username,
    this.userId,
    this.type,
    this.mediaUrl,
    this.postId,
    this.userProfileImg,
    this.commentData,
    this.timestamp,
  });

  factory ActivityFeedItem.fromDocument(DocumentSnapshot doc) {
    return ActivityFeedItem(
      username: doc['username'],
      userId: doc['userId'],
      type: doc['type'],
      postId: doc['postId'],
      userProfileImg: doc['userProfileImg'],
      commentData: doc['commentData'],
      timestamp: doc['timestamp'],
      mediaUrl: doc['mediaUrl'],
    );
  }
  @override
  Widget build(BuildContext context) {
    String activityItemText = '';
    Widget mediaPreview;
    if (type == 'like') {
      activityItemText = " liked your post";
    } else if (type == 'follow') {
      activityItemText = " is following you";
    } else if (type == 'comment') {
      activityItemText = ' replied: $commentData';
    } else {
      activityItemText = "Error: Unknown type '$type'";
    }

    if (type == 'like' || type == 'comment') {
      mediaPreview = GestureDetector(
        child: Container(
          height: 50.0,
          width: 50.0,
          child: AspectRatio(
              aspectRatio: 16 / 9,
              child: Image(
                image: CachedNetworkImageProvider(mediaUrl),
                fit: BoxFit.cover,
              )),
        ),
        onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) {
            return PostScreen(
              userId: home.currentUser.id,
              postId: postId,
            );
          }));
        },
      );
    }

    return Container(
      color: Theme.of(context).primaryColor.withOpacity(0.2),
      child: Padding(
        padding: const EdgeInsets.all(5.0),
        child: ListTile(
          leading: CircleAvatar(
            backgroundImage: CachedNetworkImageProvider(userProfileImg),
          ),
          title: GestureDetector(
            onTap: () {
              if (type == 'follow') {
              } else {
                Navigator.push(context, MaterialPageRoute(builder: (context) {
                  return PostScreen(
                    userId: home.currentUser.id,
                    postId: postId,
                  );
                }));
              }
            },
            child: RichText(
              text: TextSpan(
                  style: TextStyle(color: Colors.black, fontSize: 14.0),
                  children: [
                    TextSpan(
                      text: username,
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    TextSpan(text: activityItemText)
                  ]),
            ),
          ),
          trailing: mediaPreview,
        ),
      ),
    );
  }
}
