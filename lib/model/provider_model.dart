// models/provider_model.dart
class ProviderModel {
  final String firstName;
  final String lastName;
  final String email;
  final String phone;
  final String city;
  final String country;
  final String serviceType;
  final String serviceDescription;
  final String profileImageUrl;
  final String govIdImageUrl;

  ProviderModel({
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
    required this.city,
    required this.country,
    required this.serviceType,
    required this.serviceDescription,
    required this.profileImageUrl,
    required this.govIdImageUrl,
  });

  Map<String, dynamic> toJson() {
    return {
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'phone': phone,
      'city': city,
      'country': country,
      'serviceType': serviceType,
      'serviceDescription': serviceDescription,
      'profileImageUrl': profileImageUrl,
      'govIdImageUrl': govIdImageUrl,
    };
  }
}
