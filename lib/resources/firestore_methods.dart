import 'dart:math';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:instagram_clone/models/post.dart';
import 'package:instagram_clone/resources/storage_methods.dart';
import 'package:uuid/uuid.dart';

class FirestoreMethods {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Uploads an image to Firebase Storage and creates a corresponding post in Firestore
  Future<String> uploadImage(
    String description,
    String uid,
    Uint8List file,
    String username,
    String profImage,
  ) async {
    try {
      // Upload image to Firebase Storage
      String photoUrl =
          await StorageMethods().uploadImageToStorage('posts', file, true);

      // Generate a unique postId using Uuid
      String postId = Uuid().v1();

      // Create a Post object
      Post post = Post(
        datePublished: DateTime.now(),
        description: description,
        likes: [],
        postId: postId,
        postUrl: photoUrl,
        uid: uid,
        username: username,
        profImage: profImage,
      );

      // Add the post to the 'posts' collection in Firestore
      await _firestore.collection('posts').doc(postId).set(post.toJson());

      // Return success message
      return 'success';
    } catch (err) {
      // Handle errors during the upload process and provide a detailed error message
      return 'Upload failed: ${err.toString()}';
    }
  }

  // Handles liking/unliking a post
  Future<void> likePost(String postId, String uid, List likes) async {
    try {
      // Check if the user has already liked the post
      if (likes.contains(uid)) {
        // Unlike the post if user has already liked it
        await _firestore.collection('posts').doc(postId).update({
          'likes': FieldValue.arrayRemove([uid])
        });
      } else {
        // Like the post if user has not liked it
        await _firestore.collection('posts').doc(postId).update({
          'likes': FieldValue.arrayUnion([uid])
        });
      }
    } catch (e) {
      // Handle errors during the like/unlike process
      print('Error liking post: ${e.toString()}');
    }
  }

  // Posts a comment on a specific post
  Future<void> postComment(String postId, String text, String uid, String name,
      String profilePic) async {
    try {
      // Check if the comment text is not empty
      if (text.isNotEmpty) {
        // Generate a unique commentId using Uuid
        String commentId = const Uuid().v1();

        // Add the comment to the 'comments' subcollection under the specified post
        await _firestore
            .collection('posts')
            .doc(postId)
            .collection('comments')
            .doc(commentId)
            .set({
          'profilePic': profilePic,
          'name': name,
          'uid': uid,
          'text': text,
          'commentId': commentId,
          'datePublished': DateTime.now(),
        });
      } else {
        // Print a message if the comment text is empty
        print('Comment not posted: Text is empty');
      }
    } catch (e) {
      // Handle errors during the comment posting process
      print('Error posting comment: ${e.toString()}');
    }
  }

  // Deletes a post
  Future<void> deletePost(String postId) async {
    try {
      // Delete the specified post from the 'posts' collection
      await _firestore.collection('posts').doc(postId).delete();
    } catch (err) {
      // Handle errors during the post deletion process
      print('Error deleting post: ${err.toString()}');
    }
  }

  // Follows/unfollows a user
  Future<void> followUser(String uid, String followId) async {
    try {
      // Retrieve the user's following list
      DocumentSnapshot snap =
          await _firestore.collection('users').doc(uid).get();
      List following = (snap.data()! as dynamic)['following'];

      // Check if the user is already following the target user
      if (following.contains(followId)) {
        // Unfollow the user if already following
        await _firestore.collection('users').doc(followId).update({
          'followers': FieldValue.arrayRemove([uid]),
        });

        await _firestore.collection('users').doc(uid).update({
          'following': FieldValue.arrayRemove([followId]),
        });
      } else {
        // Follow the user if not already following
        await _firestore.collection('users').doc(followId).update({
          'followers': FieldValue.arrayUnion([uid]),
        });

        await _firestore.collection('users').doc(uid).update({
          'following': FieldValue.arrayUnion([followId]),
        });
      }
    } catch (e) {
      // Handle errors during the follow/unfollow process
      print('Error following/unfollowing user: ${e.toString()}');
    }
  }
}
