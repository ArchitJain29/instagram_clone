import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:instagram_clone/models/user.dart' as model;
import 'package:instagram_clone/resources/storage_methods.dart';

class AuthMethods {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  Future<model.User> getUserDetails() async {
    User currentUser = _auth.currentUser!;
    DocumentSnapshot snap =
        await _firestore.collection('users').doc(currentUser.uid).get();

    return model.User.fromSnap(snap);
  }

  Future<String> singUpUser({
    required String email,
    required String password,
    required String username,
    required String bio,
    required Uint8List file,
    required String fcmToken,
  }) async {
    String res = 'An error occurred';
    try {
      if (email.isNotEmpty ||
          password.isNotEmpty ||
          username.isNotEmpty ||
          bio.isNotEmpty) {
        UserCredential cred = await _auth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );

        print(cred.user!.uid);

        String photoUrl = await StorageMethods()
            .uploadImageToStorage('profilePic', file, false);

        String? fcmToken = await _firebaseMessaging.getToken();

        model.User user = model.User(
          email: email,
          bio: bio,
          followers: [],
          following: [],
          photoUrl: photoUrl,
          uid: cred.user!.uid,
          username: username,
          fcmToken: fcmToken ?? '', // Use an empty string if fcmToken is null
        );

        await _firestore
            .collection('users')
            .doc(cred.user!.uid)
            .set(user.toJson());

        res = 'success';
      } else {
        print('hi');
      }
    } catch (err) {
      res = err.toString();
      print(res);
    }
    return res;
  }

  Future<String> loginUser({
    required String email,
    required String password,
  }) async {
    String res = 'Some error occurred';

    try {
      if (email.isNotEmpty || password.isNotEmpty) {
        await _auth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );

        String? fcmToken = await _firebaseMessaging.getToken();
        User currentUser = _auth.currentUser!;
        DocumentSnapshot userSnapshot =
            await _firestore.collection('users').doc(currentUser.uid).get();
        model.User user = model.User.fromSnap(userSnapshot);

        if (user.fcmToken == null || user.fcmToken.isEmpty) {
          await _firestore
              .collection('users')
              .doc(currentUser.uid)
              .update({'fcmToken': fcmToken ?? ''});
        }

        res = 'success';
      } else {
        res = ' Please enter all the fields';
      }
    } catch (err) {
      res = err.toString();
    }

    return res;
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}
