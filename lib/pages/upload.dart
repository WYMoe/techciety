import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:fluttershare/models/user.dart';
import 'package:fluttershare/widgets/progress.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as im;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:fluttershare/services.dart';

class Upload extends StatefulWidget {
  final User user;
  Upload(this.user);
  @override
  _UploadState createState() => _UploadState();
}

class _UploadState extends State<Upload>
  with AutomaticKeepAliveClientMixin<Upload> {
  File file;
  bool isUploading = false;
  String postID = Uuid().v4();
  DateTime timestamp = DateTime.now();

  TextEditingController locationController = TextEditingController();
  TextEditingController captionController = TextEditingController();
  selectImage(parentContext) {
    return showDialog(
      context: parentContext,
      builder: (context) {
        return SimpleDialog(
          title: Text('Create Post'),
          children: <Widget>[
            SimpleDialogOption(
              child: Text('Photo with camera'),
              onPressed: () => handleImageFromCamera(),
            ),
            SimpleDialogOption(
              child: Text('Image from gallery'),
              onPressed: () => handleImageFromGallery(),
            ),
            SimpleDialogOption(
              child: Text('Cancel'),
              onPressed: () => Navigator.pop(context),
            )
          ],
        );
      },
    );
  }

  handleImageFromCamera() async {
    Navigator.pop(context);
    final pickedFile = await ImagePicker().getImage(
      source: ImageSource.camera,
      maxHeight: 675,
      maxWidth: 960,
    );

    setState(() {
      file = File(pickedFile.path);
    });
  }

  handleImageFromGallery() async {
    Navigator.pop(context);
    final pickedFile = await ImagePicker().getImage(
      source: ImageSource.gallery,
      maxHeight: 675,
      maxWidth: 960,
    );

    setState(() {
      if (pickedFile != null) {
        file = File(pickedFile.path);
      }
    });
  }

  handleSubmit() async {
    setState(() {
      isUploading = true;
    });
    await compressImage();
    String imageUrl = await uploadImage(file);
    createPostInFirestore(
        imageUrl, locationController.text, captionController.text);

    // updateFollowerTimeline(
    //    imageUrl, locationController.text, captionController.text);
    locationController.clear();
    captionController.clear();
    setState(() {
      file = null;
      isUploading = false;
      postID = Uuid().v4();
    });
  }

  compressImage() async {
    Directory tempDir = await getTemporaryDirectory();
    String tempPath = tempDir.path;
    im.Image image = im.decodeImage(file.readAsBytesSync());
    final compressedImage = File('$tempPath/post_$postID.jpg')
      ..writeAsBytesSync(im.encodeJpg(image, quality: 85));
    setState(() {
      file = compressedImage;
    });
  }

  Future<String> uploadImage(imageFile) async {
    StorageUploadTask uploadTask =
        storageRef.child('post_$postID.jpg').putFile(imageFile);
    StorageTaskSnapshot taskSnapshot = await uploadTask.onComplete;

    String url = await taskSnapshot.ref.getDownloadURL();
    return url;
  }

  createPostInFirestore(String imageUrl, String location, String caption) {
    postsRef
        .document(widget.user.id)
        .collection('userPosts')
        .document(postID)
        .setData({
      "postId": postID,
      "ownerId": widget.user.id,
      "username": widget.user.username,
      "mediaUrl": imageUrl,
      "description": caption,
      "location": location,
      "timestamp": timestamp,
      "likes": {},
    }).whenComplete(() {
      updateFollowerTimeline();
      final snackBar = SnackBar(content: Text('Upload success!'));

      Scaffold.of(context).showSnackBar(snackBar);
    });
    print('postIdUserPost $postID');
  }

  updateFollowerTimeline() async {
    QuerySnapshot followers = await Firestore.instance
        .collection('followers')
        .document(widget.user.id)
        .collection('userFollowers')
        .getDocuments();

    QuerySnapshot posts = await postsRef
        .document(widget.user.id)
        .collection('userPosts')
        .getDocuments();

    followers.documents.forEach((doc) {
      if (doc.exists) {
        var userId = doc.documentID;
        posts.documents.forEach((doc) {
          if (doc.exists) {
            var postId = doc.documentID;
            var postData = doc.data;

            Firestore.instance
                .collection('timeline')
                .document(userId)
                .collection('timelinePost')
                .document(postId)
                .setData(postData);

            print('postIdTimeline $postId');
          }
        });
      }
    });
  }

  getCurrentLocation() async {
    Position position = await Geolocator()
        .getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    List<Placemark> placemarks = await Geolocator().placemarkFromCoordinates(
        position.latitude, position.longitude,
        localeIdentifier: 'en');
    Placemark placemark = placemarks[0];
    print('${placemark.country},${placemark.locality}');
    locationController.text =
        '${placemark.country},${placemark.locality},${placemark.subLocality}';
  }

  Scaffold buildUploadForm(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
            icon: Icon(
              Icons.arrow_back_ios,
              color: Colors.black,
            ),
            onPressed: () {
              setState(() {
                file = null;
              });
            }),
        title: Text(
          'Caption Post',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
        ),
        actions: <Widget>[
          FlatButton(
              onPressed: isUploading ? null : () => handleSubmit(),
              child: Text(
                'Post',
                style: TextStyle(
                    color: isUploading ? Colors.grey : Colors.blueAccent,
                    fontSize: 20.0),
              ))
        ],
        backgroundColor: Colors.white70,
        centerTitle: true,
      ),
      body: Container(
        padding: EdgeInsets.all(10.0),
        child: ListView(
          children: <Widget>[
            isUploading ? linearProgress() : Text(''),
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Container(
                height: 220.0,
                width: MediaQuery.of(context).size.width * 0.8,
                decoration: BoxDecoration(
                    image: DecorationImage(
                        image: FileImage(file), fit: BoxFit.cover)),
              ),
            ),
            SizedBox(
              height: 10.0,
            ),
            ListTile(
              leading: CircleAvatar(
                backgroundImage:
                    CachedNetworkImageProvider(widget.user.photoUrl),
              ),
              title: Container(
                color: Colors.white70,
                child: TextField(
                  controller: captionController,
                  decoration: InputDecoration(
                      border: UnderlineInputBorder(borderSide: BorderSide.none),
                      hintText: 'Write some caption.....'),
                ),
              ),
            ),
            SizedBox(
              height: 10.0,
            ),
            ListTile(
              leading: Icon(
                Icons.pin_drop,
                size: 35.0,
                color: Colors.orangeAccent,
              ),
              title: Container(
                child: TextField(
                  controller: locationController,
                  decoration: InputDecoration(
                      border: UnderlineInputBorder(borderSide: BorderSide.none),
                      hintText: 'Where was this photo taken'),
                ),
              ),
            ),
            SizedBox(
              height: 20.0,
            ),
            Container(
              width: 100.0,
              alignment: Alignment.center,
              child: RaisedButton.icon(
                onPressed: () {
                  getCurrentLocation();
                },
                icon: Icon(
                  Icons.my_location,
                  color: Colors.white,
                ),
                label: Text(
                  'Use current location',
                  style: TextStyle(color: Colors.white),
                ),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30.0)),
                color: Colors.blueAccent,
              ),
            )
          ],
        ),
      ),
    );
  }

  Container buildSplashScreen(BuildContext context) {
    return Container(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Image.asset(
            'assets/images/2.png',
            height: 260.0,
          ),
          SizedBox(
            height: 20.0,
          ),
          RaisedButton(
            color: Theme.of(context).primaryColor,
            onPressed: () {
              selectImage(context);
            },
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.0)),
            child: Padding(
              padding: const EdgeInsets.all(13.0),
              child: Text('Upload Image',
                  style: TextStyle(color: Colors.white, fontSize: 22.0)),
            ),
          )
        ],
      ),
    );
  }

  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return file == null ? buildSplashScreen(context) : buildUploadForm(context);
  }
}
