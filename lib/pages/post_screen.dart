import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fluttershare/services.dart' as services;
import 'package:flutter/material.dart';
import 'package:fluttershare/widgets/header.dart';
import 'package:fluttershare/widgets/progress.dart';
import 'package:fluttershare/widgets/post.dart';
import 'package:flutter_icons/flutter_icons.dart';

class PostScreen extends StatefulWidget {
  final String userId;
  final String postId;


  PostScreen({this.userId, this.postId});

  @override
  _PostScreenState createState() => _PostScreenState();
}

class _PostScreenState extends State<PostScreen> {

  refresh()async{
    setState(() {
      print('refresh');

    });
  }
  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: services.postsRef
          .document(widget.userId)
          .collection('userPosts')
          .document(widget.postId)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return circularProgress();
        }
        Post post = Post(
          postId: snapshot.data["postId"],
          ownerId: snapshot.data['ownerId'],
          username: snapshot.data['username'],
          location: snapshot.data['location'],
          description: snapshot.data['description'],
          mediaUrl: snapshot.data['mediaUrl'],
          likes: snapshot.data['likes'],
          timestamp: snapshot.data['timestamp'],
          notifyParent:  refresh,

        );
        return Center(
          child: Scaffold(
            appBar: AppBar(
              title: Text(post.description),
              centerTitle: true,
              leading: IconButton(
                  icon: Icon(Feather.arrow_left),
                  onPressed: () {
                    Navigator.pop(context);
                  }),
            ),
            body: ListView(
              children: <Widget>[
                Container(
                  child: post,
                )
              ],
            ),
          ),
        );
      },
    );
  }
}
