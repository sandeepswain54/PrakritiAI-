import 'dart:io';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:service_app/model/user_model.dart';

class ContactModel {
  String? id;
  String? firstname;
  String? lastname;
  String? fullname;
  MemoryImage? displayImage;

  ContactModel({
    this.id = '',
    this.firstname = '',
    this.lastname = '',
    this.fullname = '',
    this.displayImage,
  });

  String getFullNameofUser() => fullname = '${firstname ?? ''} ${lastname ?? ''}'.trim();

  UserModel createUserFromContact() => UserModel(
    id: id ?? '',
    firstname: firstname ?? '',
    lastname: lastname ?? '',
    displayImage: displayImage,
  );

  void clearImageCache() {
    displayImage = null;
    if (id != null) {
      final imageCache = PaintingBinding.instance.imageCache;
      imageCache?.clear();
      imageCache?.clearLiveImages();
    }
  }

  Future<MemoryImage?> getImageFromStorage() async {
    try {
      if (id == null || id!.isEmpty) return null;

      // Clear previous image reference
      displayImage = null;

      final ref = FirebaseStorage.instance
          .ref()
          .child("userImages")
          .child(id!)
          .child("$id.png");

      final url = await ref.getDownloadURL();
      final response = await http.get(Uri.parse('$url?t=${DateTime.now().millisecondsSinceEpoch}'));

      if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
        displayImage = MemoryImage(response.bodyBytes);
        return displayImage;
      }
      return null;
    } catch (e) {
      debugPrint("Error loading profile image: $e");
      return null;
    }
  }

  static ContactModel fromMap(Map<String, dynamic> map) => ContactModel(
    id: map['id'],
    firstname: map['firstName'],
    lastname: map['lastName'],
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'firstName': firstname,
    'lastName': lastname,
  };

  Future<void> getContactInfoFromFirestore() async {
    try {
      if (id == null || id!.isEmpty) return;
      
      final snapshot = await FirebaseFirestore.instance
          .collection("users")
          .doc(id)
          .get();

      if (snapshot.exists) {
        firstname = snapshot.get("firstName") ?? "";
        lastname = snapshot.get("lastName") ?? "";
      }
    } catch (e) {
      debugPrint("Error fetching contact info: $e");
    }
  }
}