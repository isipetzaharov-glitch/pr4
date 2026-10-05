// lib/models/client.dart
import 'service_card.dart';

class Client {
  final int id;
  final String lastName;
  final String firstName;
  final String email;
  final String phone;
  final String country;
  final ServiceCard? card; // связь 1-к-1
  final DateTime? deletedAt;

  const Client({
    required this.id,
    required this.lastName,
    required this.firstName,
    required this.email,
    required this.phone,
    required this.country,
    this.card,
    this.deletedAt,
  });

  bool get isDeleted => deletedAt != null;
  String get fullName => '$lastName $firstName';

  Client copyWith({
    String? lastName,
    String? firstName,
    String? email,
    String? phone,
    String? country,
    ServiceCard? card,
    bool clearCard = false,
    DateTime? deletedAt,
    bool clearDeletedAt = false,
  }) {
    return Client(
      id: id,
      lastName: lastName ?? this.lastName,
      firstName: firstName ?? this.firstName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      country: country ?? this.country,
      card: clearCard ? null : (card ?? this.card),
      deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'lastName': lastName,
    'firstName': firstName,
    'email': email,
    'phone': phone,
    'country': country,
    'card': card?.toJson(),
    'deletedAt': deletedAt?.toIso8601String(),
  };

  factory Client.fromJson(Map<String, dynamic> json) {
    // card может прийти как вложенный объект, как null,
    // или отсутствовать в ответе вовсе.
    final rawCard = json['card'];

    return Client(
      id: (json['id'] as num?)?.toInt() ?? 0,
      lastName: json['lastName'] as String? ?? '',
      firstName: json['firstName'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      country: json['country'] as String? ?? '',
      card: rawCard is Map<String, dynamic>
          ? ServiceCard.fromJson(rawCard)
          : (rawCard is Map
                ? ServiceCard.fromJson(Map<String, dynamic>.from(rawCard))
                : null),
      deletedAt: json['deletedAt'] == null
          ? null
          : DateTime.tryParse(json['deletedAt'] as String),
    );
  }
}
