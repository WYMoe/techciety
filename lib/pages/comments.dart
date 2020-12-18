import 'package:cached_network_image/cached_network_image.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fluttershare/services.dart' as services;
import 'package:flutter/material.dart';

import 'package:fluttershare/widgets/header.dart';
import 'package:fluttershare/widgets/progress.dart';
import 'home.dart' as home;

class Comments extends StatefulWidget {
  final String postId;
  final String ownerId;
  final String mediaUrl;
  Comments({this.postId, this.ownerId, this.mediaUrl});

  @override
  CommentsState createState() => CommentsState();
}

class CommentsState extends State<Comments> {
  TextEditingController commentController = TextEditingController();
  String cmt;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: header(context,
            text: 'Comments', backButtonRemove: false, isAppTitleEnabled: true),
        body: Column(
          children: <Widget>[
            Expanded(child: buildComments()),
            buildCommentBox(context),
            SizedBox(
              height: 10.0,
            )
          ],
        ));
  }

  StreamBuilder<QuerySnapshot> buildComments() {
    return StreamBuilder(
      stream: services.commentsRef
          .document(widget.postId)
          .collection('comments')
          .orderBy("timestamp", descending: false)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return circularProgress();
        }

        List<Comment> comments = [];

        comments = snapshot.data.documents.map((doc) {
          return Comment.fromDocument(doc);
        }).toList();

        return ListView(
          children: comments,
        );
      },
    );
  }

  ListTile buildCommentBox(BuildContext context) {
    return ListTile(
      title: TextField(
        controller: commentController,
        decoration: InputDecoration(
            labelText: "Write a comment...",
            border:
                OutlineInputBorder(borderRadius: BorderRadius.circular(15.0))),
        onChanged: (val) {
          cmt = val;
        },
      ),
      trailing: OutlineButton(
        onPressed: () {
          addComment();
          commentController.clear();
        },
        child: Text('Post'),
        borderSide: BorderSide(color: Theme.of(context).primaryColor),
      ),
    );
  }

  addComment() {
    services.commentsRef.document(widget.postId).collection('comments').add({
      "username": home.currentUser.username,
      "comment": cmt,
      "timestamp": home.timestamp,
      "avatarUrl": home.currentUser.photoUrl,
      "userId": home.currentUser.id,
    });
    {
      services.feedsRef
          .document(widget.ownerId)
          .collection('feedItems')
          .document(widget.postId)
          .setData({
        "type": "comment",
        "commentData": cmt,
        'username': home.currentUser.username,
        'userId': home.currentUser.id,
        'userProfileImg': home.currentUser.photoUrl,
        'postId': widget.postId,
        'mediaUrl': widget.mediaUrl,
        'timestamp': home.timestamp
      }); //add noti
    }
  }
}

class Comment extends StatelessWidget {
  final String username;
  final String comment;
  final Timestamp timestamp;
  final String avatarUrl;
  final String userId;
  Comment(
      {this.username,
      this.comment,
      this.timestamp,
      this.avatarUrl,
      this.userId});

  factory Comment.fromDocument(doc) {
    return Comment(
      username: doc['username'],
      comment: doc['comment'],
      timestamp: doc['timestamp'],
      avatarUrl: doc['avatarUrl'],
      userId: doc['userId'],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        ListTile(
          leading: CircleAvatar(
            backgroundImage: CachedNetworkImageProvider(avatarUrl),
          ),
          title: Text(comment),
          subtitle: Text(timeago.format(timestamp.toDate())),
        ),
        Divider(),
      ],
    );
  }
}
