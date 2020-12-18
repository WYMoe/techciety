import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import 'package:google_sign_in/google_sign_in.dart';

final googleSignIn = GoogleSignIn();
final userRef = Firestore.instance.collection('user');
final StorageReference storageRef = FirebaseStorage.instance.ref();
final postsRef = Firestore.instance.collection('posts');
final GoogleSignInAccount user = googleSignIn.currentUser;
final commentsRef = Firestore.instance.collection('comments');
final feedsRef = Firestore.instance.collection('feeds');
final followingRef = Firestore.instance.collection('followings');
final followerRef = Firestore.instance.collection('followers');
