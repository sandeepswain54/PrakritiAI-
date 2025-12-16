import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:service_app/model/app_constant.dart';
import 'package:service_app/model/contact_model.dart';

class MessageModel {
  ContactModel? sender;
  String? text;
  DateTime? dateTime;
  String? id;

  MessageModel({required this.dateTime});

  String getMessageDateTime() {
    return timeago.format(dateTime!);
  }

  Future<void> getMessageInfoFromFirestore(DocumentSnapshot snapshot) async {
    try {
      id = snapshot.id;
      final data = snapshot.data() as Map<String, dynamic>? ?? {};
      
      final timestamp = data["dateTime"] as Timestamp? ?? Timestamp.now();
      dateTime = timestamp.toDate();
      
      final senderID = data["senderID"] as String? ?? "";
      text = data["text"] as String? ?? "";
      
      // Load sender info
      if (senderID == AppConstants.currentUser.id) {
        sender = AppConstants.currentUser.createContactFromUser();
      } else {
        sender = ContactModel(id: senderID);
        await sender?.getContactInfoFromFirestore();
        await sender?.getImageFromStorage();
      }
    } catch (e) {
      debugPrint("Error loading message: $e");
    }
  }
}