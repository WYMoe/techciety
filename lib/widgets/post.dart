import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fluttershare/models/user.dart';
import 'package:fluttershare/pages/comments.dart';
import 'package:fluttershare/pages/post_screen.dart';
import 'package:fluttershare/pages/profile.dart';
import 'package:fluttershare/services.dart' as services;
import 'package:fluttershare/widgets/custom_image.dart';
import 'package:fluttershare/widgets/progress.dart';
import 'package:fluttershare/pages/home.dart' as home;
import 'package:flutter_icons/flutter_icons.dart';

class Post extends StatefulWidget {
  final String postId;
  final String ownerId;
  final String username;
  final String location;
  final String description;
  final String mediaUrl;
  final Timestamp timestamp;
  final Map likes;
  final Function notifyParent;

  Post(
      {this.postId,
      this.ownerId,
      this.username,
      this.location,
      this.description,
      this.mediaUrl,
      this.likes,
      this.timestamp,this.notifyParent});

  factory Post.fromDocument(DocumentSnapshot doc) {
    return Post(
      postId: doc["postId"],
      ownerId: doc['ownerId'],
      username: doc['username'],
      location: doc['location'],
      description: doc['description'],
      mediaUrl: doc['mediaUrl'],
      likes: doc['likes'],
      timestamp: doc['timestamp'],
    );
  }

  int getLikeCount(likes) {
    if (likes == null) {
      return 0;
    }
    int count = 0;

    likes.values.forEach((val) {
      if (val == true) {
        count += 1;
      }
    });
    return count;
  }

  @override
  _PostState createState() => _PostState(
        postId: this.postId,
        ownerId: this.ownerId,
        username: this.username,
        location: this.location,
        description: this.description,
        mediaUrl: this.mediaUrl,
        likes: likes,
        timestamp: this.timestamp,
        likeCount: getLikeCount(this.likes),
      );
}

class _PostState extends State<Post> {
  final String currentUserId = home.currentUser?.id;
  final String postId;
  final String ownerId;
  final String username;
  final String location;
  final String description;
  final String mediaUrl;
  final Timestamp timestamp;
  bool isLiked;
  int likeCount;
  Map likes;

  _PostState({
    this.postId,
    this.ownerId,
    this.username,
    this.location,
    this.description,
    this.mediaUrl,
    this.likes,
    this.timestamp,
    this.likeCount,
  });

  buildPostHeader() {
    return FutureBuilder(
      future: services.userRef.document(ownerId).get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return circularProgress();
        }
        User user = User.fromDocument(snapshot.data);
        return Column(
          children: [
            ListTile(
              leading: CircleAvatar(
                backgroundImage: CachedNetworkImageProvider(user.photoUrl),
                backgroundColor: Colors.grey,
              ),
              title: GestureDetector(
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) {
                    return Profile(
                      profileID: ownerId,
                    );
                  }));
                },
                child: Text(
                  user.username,
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              subtitle: Text(location),
              trailing: IconButton(
                onPressed: () => deletePostDialog(context),
                icon: Icon(Icons.more_vert),
              ),
            ),
          ],
        );
      },
    );
  }

  deletePostDialog(parentContext)  {
    return showDialog(
      context: parentContext,
      builder: (context) {
        return SimpleDialog(
          title: Text('Delete Post'),
          children: <Widget>[
            SimpleDialogOption(
              child: Text('Delete'),
              onPressed: ()async {
                Navigator.pop(context);

                await handleDelete();
                widget.notifyParent();

              },
            ),
            SimpleDialogOption(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }

  handleDelete() async {
    if (ownerId == currentUserId) {
      print(ownerId);
      print(currentUserId);

      ///delete posts
      services.postsRef
          .document(ownerId)
          .collection('userPosts')
          .document(postId)
          .delete();

      ///delete feeds
      QuerySnapshot feeds = await services.feedsRef
          .document(ownerId)
          .collection('feedItems')
          .where('postId', isEqualTo: postId)
          .getDocuments();

      feeds.documents.forEach((doc) {
        if (doc.exists) {
          doc.reference.delete();
        }
      });

      ///delete picture
      services.storageRef.child('post_$postId.jpg').delete();
    }

    QuerySnapshot followers = await services.followerRef
        .document(ownerId)
        .collection('userFollowers')
        .getDocuments();

    followers.documents.forEach((doc) {
      if (doc.exists) {
        Firestore.instance
            .collection('timeline')
            .document(doc.documentID)
            .collection('timelinePost')
            .document(postId)
            .delete();
      }
    });
  }

  handleLike() async {
    bool _isLiked = likes['likes.$currentUserId'] ==
        true; //check whether currentUser likes the post

    if (_isLiked) {
      services.postsRef
          .document(ownerId)
          .collection('userPosts')
          .document(postId)
          .updateData({'likes.$currentUserId': false});
      //update follower timeline data
      QuerySnapshot followers = await Firestore.instance
          .collection('followers')
          .document(ownerId)
          .collection('userFollowers')
          .getDocuments();

      followers.documents.forEach((doc) {
        if (doc.exists) {
          Firestore.instance
              .collection('timeline')
              .document(doc.documentID)
              .collection('timelinePost')
              .document(postId)
              .updateData({
            "likes": {'likes.$currentUserId': false},
          });
        }
      });
      //remove like noti from owner's activity feed
      if (currentUserId != ownerId) {
        services.feedsRef
            .document(ownerId)
            .collection('feedItems')
            .document(postId)
            .get()
            .then((doc) {
          doc.reference.delete();
        });
      }

      setState(() {
        likeCount -= 1;
        isLiked = false;
        likes['likes.$currentUserId'] = false;
      });
    } else if (_isLiked == false) {
      services.postsRef
          .document(ownerId)
          .collection('userPosts')
          .document(postId)
          .updateData({'likes.$currentUserId': true});

      QuerySnapshot followers = await Firestore.instance
          .collection('followers')
          .document(ownerId)
          .collection('userFollowers')
          .getDocuments();

      followers.documents.forEach((doc) {
        if (doc.exists) {
          Firestore.instance
              .collection('timeline')
              .document(doc.documentID)
              .collection('timelinePost')
              .document(postId)
              .updateData({
            "likes": {'likes.$currentUserId': true},
          });
        }
      });

      //add like noti to owner's activity feed
      if (currentUserId != ownerId) {
        services.feedsRef
            .document(ownerId)
            .collection('feedItems')
            .document(postId)
            .setData({
          'type': 'like',
          'username': home.currentUser.username,
          'userId': currentUserId,
          'userProfileImg': home.currentUser.photoUrl,
          'postId': postId,
          'mediaUrl': mediaUrl,
          'timestamp': home.timestamp
        });
      }
      setState(() {
        likeCount += 1;
        isLiked = true;
        likes['likes.$currentUserId'] = true;
      });
    }
  }

  buildPostImage() {
    return GestureDetector(
      onDoubleTap: () async {
        handleLike();
      },
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[cachedNetworkImage(mediaUrl)],
      ),
    );
  }

  buildPostFooter() {
    return Column(
      children: <Widget>[
        Row(
          children: <Widget>[
            SizedBox(height: 50.0),
            Expanded(
              child: GestureDetector(
                onTap: () {
                  handleLike();
                },
                child: Icon(
                  isLiked ? Icons.favorite : Feather.heart,
                  size: 28.0,
                  color: Colors.pink,
                ),
              ),
            ),
            Expanded(
              child: GestureDetector(
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) {
                    return Comments(
                      postId: postId,
                      ownerId: ownerId,
                      mediaUrl: mediaUrl,
                    );
                  }));
                },
                child: Icon(
                  Feather.message_circle,
                  size: 28.0,
                  color: Colors.blue[900],
                ),
              ),
            ),
          ],
        ),
        Row(
          children: <Widget>[
            Container(
              margin: EdgeInsets.only(left: 20.0),
              child: Text(
                "$likeCount likes",
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              margin: EdgeInsets.only(left: 20.0),
              child: Text(
                "$username ",
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Expanded(child: Text(description))
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    isLiked = (likes['likes.$currentUserId'] == true);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        buildPostHeader(),
        buildPostImage(),
        buildPostFooter(),
        Divider(
          height: 20.0,
        )
      ],
    );
  }
}
