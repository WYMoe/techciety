import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fluttershare/models/user.dart';
import 'package:fluttershare/pages/activity_feed.dart';
import 'package:fluttershare/pages/create_account.dart';
import 'package:fluttershare/pages/profile.dart';
import 'package:fluttershare/pages/search.dart';
import 'package:fluttershare/pages/timeline.dart';

import 'package:fluttershare/pages/upload.dart';
import 'package:fluttershare/services.dart' as services;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_icons/flutter_icons.dart';
import 'package:fluttershare/widgets/circular_background_painter.dart';

final DateTime timestamp = DateTime.now();
User currentUser;

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  bool isAuth = false;
  PageController pageController;

  int pageIndex = 0;
  int tabIndex = 0;
  DocumentSnapshot doc;
  @override
  void initState() {
    pageController = PageController();
    super.initState();
    //services.googleSignIn.signIn();
    services.googleSignIn.onCurrentUserChanged.listen((account) {
      handleSignIn(account);
    }, onError: (err) => print('Error:$err'));

  //  services.googleSignIn.signInSilently(suppressErrors: false).then((account) => handleSignIn(account)).catchError((err)=>print('Error:$err'));
  }

  @override
  void dispose() {
    super.dispose();
    pageController.dispose();
  }

  //methods....................

  handleSignIn(GoogleSignInAccount account) async {
    if (account != null) {
      await createUserInFirestore();
      setState(() {
        isAuth = true;
      });
    } else {
      print('acc null');
      setState(() {
        isAuth = false;
      });
    }
  }

  createUserInFirestore() async {
    final GoogleSignInAccount user = services.googleSignIn.currentUser;
    doc = await services.userRef.document(user.id).get();
    if (!doc.exists) {
      final username = await Navigator.push(
          context, MaterialPageRoute(builder: (context) => CreateAccount()));
      print(username);

      services.userRef.document(user.id).setData({
        "id": user.id,
        "username": username,
        "photoUrl": user.photoUrl,
        "email": user.email,
        "displayName": user.displayName,
        "bio": "",
        "timestamp": timestamp,
      });

      doc = await services.userRef.document(user.id).get();
    } else {
      print('acc already exist');
    }

    currentUser = User.fromDocument(doc);
    print(currentUser.username);
  }

  login() {
    services.googleSignIn.signIn();
  }

  logout() {
    services.googleSignIn.signOut();
  }

  //Screens ..............
  Scaffold buildAuthScreen() {
    return Scaffold(
      body: PageView(
        children: <Widget>[
          Timeline(
            currentUserId: services.googleSignIn.currentUser.id,
          ),
          // RaisedButton(
          //     child: Text('logout'),
          //     onPressed: () {
          //       logout();
          //     }),
          ActivityFeed(),
          Upload(currentUser),
          Search(),
          Profile(
            profileID: currentUser?.id,
          )
        ],
        controller: pageController,
        onPageChanged: (pageIndex) {
          setState(() {
            this.pageIndex = pageIndex;
          });
        },
        physics: NeverScrollableScrollPhysics(),
      ),
      bottomNavigationBar: CupertinoTabBar(
        items: [
          BottomNavigationBarItem(icon: Icon(Feather.grid)),
          BottomNavigationBarItem(icon: Icon(Feather.bell)),
          BottomNavigationBarItem(
              icon: Icon(
            Feather.camera,
            size: 35.0,
          )),
          BottomNavigationBarItem(icon: Icon(Feather.search)),
          BottomNavigationBarItem(icon: Icon(Feather.user)),
        ],
        activeColor: Theme.of(context).primaryColor,
        currentIndex: pageIndex,
        onTap: (tabIndex) {
          pageController.jumpToPage(tabIndex);
        },
      ),
    );
  }

  Scaffold buildUnauthScreen() {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            height: double.infinity,
            width: double.infinity,
            // decoration: BoxDecoration(
            //     gradient: LinearGradient(
            //         colors: [Colors.purple, Colors.purple[200], Colors.purple],
            //         begin: Alignment.topCenter,
            //         end: Alignment.bottomCenter)),

            child: CustomPaint(
              painter: new CircularBackgroundPainter(),
            ),
          ),
          Container(
            alignment: Alignment.topCenter,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                SizedBox(
                  height: 50.0,
                ),
                Text(
                  'Techciety',
                  style: TextStyle(
                      fontFamily: 'BalooTamma2-Regular',
                      fontSize: MediaQuery.of(context).size.width * 0.2,
                      color: Colors.deepPurple),
                  textAlign: TextAlign.center,
                ),
                GestureDetector(
                  onTap: () {
                    login();
                  },
                  child: Container(
                    width: 260.0,
                    height: 60.0,
                    decoration: BoxDecoration(
                        image: DecorationImage(
                            image: AssetImage(
                                'assets/images/google_signin_button.png'),
                            fit: BoxFit.cover)),
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return isAuth ? buildAuthScreen() : buildUnauthScreen();
  }
}
