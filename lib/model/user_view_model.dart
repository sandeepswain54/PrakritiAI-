import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:service_app/model/app_constant.dart';
import 'package:service_app/model/user_model.dart';
import 'package:service_app/views/home_screen.dart';

class UserViewModel {
  UserModel userModel = UserModel();

  Signup(email, password, firstName, lastName, bio, city, country, imageFileofUser) async {
    Get.snackbar("Please Wait", "We are creating your account");

    try {
      await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: email,
            password: password,
          )
          .then((result) async {
        String currentUserID = result.user!.uid;

        AppConstants.currentUser.id = currentUserID;
        AppConstants.currentUser.email = email;
        AppConstants.currentUser.firstName = firstName;
        AppConstants.currentUser.lastName = lastName;
        AppConstants.currentUser.bio = bio;
        AppConstants.currentUser.city = city;
        AppConstants.currentUser.country = country;
        AppConstants.currentUser.password = password;

        await saveUserToFirestore(bio, city, country, email, firstName, lastName, currentUserID);

        // Create default posting and add to myPostingIDs
        String postingId = await createInitialPosting(currentUserID);
        await FirebaseFirestore.instance.collection('users').doc(currentUserID).update({
          'myPostingIDs': FieldValue.arrayUnion([postingId])
        });

        // Upload profile image
        await addImageToFirebaseStorage(imageFileofUser, currentUserID);

        Get.to(HomeScreen());
        Get.snackbar("Congratulations", "Your account has been created successfully");
      });
    } catch (e) {
      Get.snackbar("Error", e.toString());
    }
  }

  Future<void> saveUserToFirestore(bio, city, country, email, firstName, lastName, id) async {
    Map<String, dynamic> dataMap = {
      'bio': bio,
      'city': city,
      'country': country,
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'isHost': false,
      'myPostingIDs': [],
      'savedPostinigIDs': [],
      'earning': 0,
    };

    await FirebaseFirestore.instance.collection('users').doc(id).set(dataMap);
  }

  Future<String> createInitialPosting(String userID) async {
    DocumentReference postingRef =
        await FirebaseFirestore.instance.collection("postings").add({
      'userId': userID,
      'title': 'Welcome Posting',
      'description': 'Auto-created on signup',
      'timestamp': FieldValue.serverTimestamp(),
    });

    return postingRef.id;
  }

  Future<void> addImageToFirebaseStorage(File imageFileofUser, String currentUserID) async {
    Reference referenceStorage = FirebaseStorage.instance
        .ref()
        .child('userImages')
        .child(currentUserID)
        .child(currentUserID + '.png');

    await referenceStorage.putFile(imageFileofUser);
    AppConstants.currentUser.displayImage = MemoryImage(imageFileofUser.readAsBytesSync());
  }

  Future<void> getUserInfoFromFirestore(String userID) async {
    DocumentSnapshot snapshot =
        await FirebaseFirestore.instance.collection('users').doc(userID).get();

    AppConstants.currentUser.snapshot = snapshot;
    AppConstants.currentUser.firstName = snapshot['firstName'] ?? '';
    AppConstants.currentUser.bio = snapshot['bio'] ?? '';
    AppConstants.currentUser.lastName = snapshot['lastName'] ?? '';
    AppConstants.currentUser.city = snapshot['city'] ?? '';
    AppConstants.currentUser.country = snapshot['country'] ?? '';
    AppConstants.currentUser.email = snapshot['email'] ?? '';
    AppConstants.currentUser.isHost = snapshot['isHost'] ?? false;
  }

  Future<MemoryImage?> getImageFromStorage(String userID) async {
    if (AppConstants.currentUser.displayImage != null) {
      return AppConstants.currentUser.displayImage;
    }

    final imageDatainBytes = await FirebaseStorage.instance
        .ref()
        .child('userImages')
        .child(userID)
        .child(userID + '.png')
        .getData(1024 * 1024);

    AppConstants.currentUser.displayImage = MemoryImage(imageDatainBytes!);
    return AppConstants.currentUser.displayImage;
  }

  Future<void> login(String email, String password) async {
    try {
      Get.snackbar("Please wait", "Authenticating...");

      // 1. Authenticate with Firebase Auth
      UserCredential userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);

      String userId = userCredential.user!.uid;
      AppConstants.currentUser.id = userId;

      // 2. Get user document from Firestore
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection("users")
          .doc(userId)
          .get();

      if (!userDoc.exists) {
        throw Exception("User document not found");
      }

      // 3. Update basic user info with null checks
      Map<String, dynamic>? userData = userDoc.data() as Map<String, dynamic>?;

      AppConstants.currentUser.email = userData?['email'] ?? '';
      AppConstants.currentUser.firstName = userData?['firstName'] ?? '';
      AppConstants.currentUser.lastName = userData?['lastName'] ?? '';
      AppConstants.currentUser.isHost = userData?['isHost'] ?? false;

      // 4. Only load postings if user is a host (with error handling)
      if (AppConstants.currentUser.isHost == true) {
        try {
          await AppConstants.currentUser.getMyPostingsFromFirestore();
        } catch (e) {
          debugPrint("Error loading postings: $e");
          Get.snackbar("Notice", "Logged in but couldn't load provider data");
        }
      }

      // 5. Navigate to home screen
      Get.offAll(() => HomeScreen());
      Get.snackbar("Success", "Logged in successfully");

    } on FirebaseAuthException catch (e) {
      Get.snackbar("Login Failed", e.message ?? 'Authentication error');
    } catch (e) {
      Get.snackbar("Error", "Login failed: ${e.toString()}");
    }
  }

  becomeHost(String userID, dynamic userModel) async {
    userModel.isHost = true;
    Map<String, dynamic> dataMap = {
      'isHost': true,
    };
    await FirebaseFirestore.instance.collection("users").doc(userID).update(dataMap);
  }

  modifyCurrentlyHosting(bool isHosting, dynamic userModel) {
    userModel.isCurrentlyHosting = isHosting;
  }

  /// ✅ New: Send password reset link to email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      Get.snackbar("Email Sent", "Password reset link sent to $email",
          backgroundColor: Colors.green,
          colorText: Colors.white);
    } on FirebaseAuthException catch (e) {
      Get.snackbar("Reset Failed", e.message ?? "Failed to send reset email",
          backgroundColor: Colors.red,
          colorText: Colors.white);
    } catch (e) {
      Get.snackbar("Error", "Something went wrong: ${e.toString()}",
          backgroundColor: Colors.red,
          colorText: Colors.white);
    }
  }
}
