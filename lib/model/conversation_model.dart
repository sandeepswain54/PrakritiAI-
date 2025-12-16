import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:service_app/model/app_constant.dart';
import 'package:service_app/model/contact_model.dart';
import 'package:service_app/model/message_model.dart';

class ConversationModel {
  String? id;
  ContactModel? otherContact;
  List<MessageModel>? messages;
  MessageModel? lastMessage;

  ConversationModel() {
    messages = [];
    otherContact = ContactModel();
  }

  Future<void> addConversationToFirestore(ContactModel otherContact) async {
    try {
      List<String> userNames = [
        AppConstants.currentUser.getFullNameofUser(),
        otherContact.getFullNameofUser(),
      ];

      List<String> userIDs = [
        AppConstants.currentUser.id!,
        otherContact.id!,
      ];

      Map<String, dynamic> conversationDataMap = {
        "lastMessageDateTime": Timestamp.now(),
        "lastMessageText": "",
        "userNames": userNames,
        "userIDs": userIDs,
        "participants": FieldValue.arrayUnion(userIDs),
      };

      DocumentReference reference = await FirebaseFirestore.instance
          .collection("conversations")
          .add(conversationDataMap);

      id = reference.id;
      await otherContact.getContactInfoFromFirestore();
      await otherContact.getImageFromStorage();
    } catch (e) {
      debugPrint("Error creating conversation: $e");
      rethrow;
    }
  }

  Future<void> addMessageToFirestore(String messageText) async {
    try {
      Map<String, dynamic> messageData = {
        "dateTime": Timestamp.now(),
        "senderID": AppConstants.currentUser.id,
        "text": messageText
      };

      await FirebaseFirestore.instance
          .collection("conversations/$id/messages")
          .add(messageData);

      Map<String, dynamic> conversationData = {
        "lastMessageDateTime": Timestamp.now(),
        "lastMessageText": messageText,
      };

      await FirebaseFirestore.instance
          .doc("conversations/$id")
          .update(conversationData);
    } catch (e) {
      debugPrint("Error sending message: $e");
      rethrow;
    }
  }

  Future<void> getConversationInfoFromFirestore(DocumentSnapshot snapshot) async {
    try {
      id = snapshot.id;
      final data = snapshot.data() as Map<String, dynamic>;

      String lastMessageText = data["lastMessageText"] ?? "";
      Timestamp lastMessageDateTimestamp = data["lastMessageDateTime"] ?? Timestamp.now();
      
      lastMessage = MessageModel(dateTime: lastMessageDateTimestamp.toDate());
      lastMessage!.text = lastMessageText;

      List<String> userIDs = List<String>.from(data["userIDs"] ?? []);
      List<String> userNames = List<String>.from(data["userNames"] ?? []);

      // Find and load other contact info
      for (int i = 0; i < userIDs.length; i++) {
        if (userIDs[i] != AppConstants.currentUser.id) {
          otherContact = ContactModel(
            id: userIDs[i],
            firstname: userNames[i].split(" ")[0],
            lastname: userNames[i].split(" ").length > 1 ? userNames[i].split(" ")[1] : "",
          );
          await otherContact?.getContactInfoFromFirestore();
          await otherContact?.getImageFromStorage();
          break;
        }
      }
    } catch (e) {
      debugPrint("Error loading conversation: $e");
      rethrow;
    }
  }

  Stream<QuerySnapshot> getMessagesStream() {
    return FirebaseFirestore.instance
        .collection("conversations/$id/messages")
        .orderBy("dateTime", descending: false)
        .snapshots();
  }
}