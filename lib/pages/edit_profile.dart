import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:fluttershare/models/user.dart';
import 'package:fluttershare/pages/home.dart';
import 'package:fluttershare/pages/profile.dart';
import 'package:fluttershare/services.dart' as services;

import "package:flutter/material.dart";
import 'package:fluttershare/widgets/progress.dart';

class EditProfile extends StatefulWidget {
  final String currentUserID;
  EditProfile({this.currentUserID});
  @override
  _EditProfileState createState() => _EditProfileState();
}

class _EditProfileState extends State<EditProfile> {
  TextEditingController nameController = TextEditingController();
  TextEditingController bioController = TextEditingController();
  User currentUser;
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  bool isLoading = false;
  bool _isNameValidate = true;
  bool _isBioValidate = true;

  @override
  void initState() {
    super.initState();
    getCurrentUser();
  }

  getCurrentUser() async {
    setState(() {
      isLoading = true;
    });
    DocumentSnapshot doc =
        await services.userRef.document(widget.currentUserID).get();
    currentUser = User.fromDocument(doc);
    nameController.text = currentUser.username;
    bioController.text = currentUser.bio;

    setState(() {
      isLoading = false;
    });
  }

  updateProfileData() {
    if (nameController.text.trim().length < 3 || nameController.text.isEmpty) {
      setState(() {
        _isNameValidate = false;
      });
    } else {
      setState(() {
        _isNameValidate = true;
      });
    }

    if (bioController.text.trim().length > 100) {
      setState(() {
        _isBioValidate = false;
      });
    } else {
      setState(() {
        _isBioValidate = true;
      });
    }

    if (_isNameValidate && _isBioValidate) {
      services.userRef.document(widget.currentUserID).updateData({
        'username': nameController.text.toString(),
        'bio': bioController.text.toString()
      }).whenComplete(() {
        

        _scaffoldKey.currentState
            .showSnackBar(SnackBar(content: Text('Update success!')));
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        leading: IconButton(icon: Icon(Icons.arrow_back_ios), onPressed: () {
          Navigator.pop(context);
        }),
        title: Text('Edit Profile'),
        actions: <Widget>[
          IconButton(
              icon: Icon(Icons.done),
              onPressed: () {
                Navigator.pop(context,);
              })
        ],
        centerTitle: true,
      ),
      body: isLoading
          ? circularProgress()
          : ListView(
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: <Widget>[
                      CircleAvatar(
                        backgroundColor: Colors.grey,
                        backgroundImage:
                            CachedNetworkImageProvider(currentUser.photoUrl),
                        radius: 50.0,
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          SizedBox(
                            height: 30.0,
                          ),
                          buildEditFormColumn(
                              'Display Name', nameController, _isNameValidate),
                          SizedBox(
                            height: 20.0,
                          ),
                          buildEditFormColumn(
                              'Bio', bioController, _isBioValidate)
                        ],
                      ),
                      SizedBox(
                        height: 20.0,
                      ),
                      buildEditProfileButton(
                          context: context,
                          buttonLabel: 'Update Profile',
                          function: () {
                            updateProfileData();
                          }),
                      SizedBox(
                        height: 20.0,
                      ),
                      buildEditProfileButton(
                          context: context,
                          buttonLabel: 'Logout',
                          function: () {

                            services.googleSignIn.signOut();
                            Navigator.push(context, MaterialPageRoute(builder: (context){
                              return Home();
                            }));
                          })
                    ],
                  ),
                )
              ],
            ),
    );
  }

  FlatButton buildEditProfileButton(
      {BuildContext context, String buttonLabel, Function function}) {
    return FlatButton(
        onPressed: () {},
        child: Container(
          height: 50.0,
          width: MediaQuery.of(context).size.width * 0.5,
          margin: EdgeInsets.only(top: 10.0, left: 25.0, right: 25.0),
          child: FlatButton(
            onPressed: function,
            child: Text(
              buttonLabel,
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(7.0),
              color: Theme.of(context).primaryColor),
        ));
  }

  Column buildEditFormColumn(
      String label, TextEditingController controller, bool isValid) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          label,
          style: TextStyle(color: Colors.grey),
        ),
        TextField(
          controller: controller,
          onChanged: (val) {},
          decoration: InputDecoration(errorText: isValid ? null : 'Error'),
        )
      ],
    );
  }
}
