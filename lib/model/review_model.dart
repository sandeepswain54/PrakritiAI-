import 'package:service_app/model/contact_model.dart';
import 'package:service_app/model/posting_model.dart';

class ReviewModel {
  ContactModel? contact;
  String? text;
  double? rating;
  DateTime? dateTime;

  ReviewModel({
    this.contact,
    this.text,
    this.rating,
    this.dateTime,
  });

  factory ReviewModel.fromMap(Map<String, dynamic> map) {
    return ReviewModel(
      contact: map['contact'] != null ? ContactModel.fromMap(map['contact']) : null,
      text: map['text'],
      rating: map['rating']?.toDouble(),
      dateTime: map['dateTime'] != null ? DateTime.parse(map['dateTime']) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'contact': contact?.toMap(),
      'text': text,
      'rating': rating,
      'dateTime': dateTime?.toIso8601String(),
    };
  }
}