import 'package:cloud_firestore/cloud_firestore.dart';

enum Role { member, staff, manager, admin, membershipCard, trainer }

enum Gender { male, female, other }

class UserAccount {
  final String id; // uid từ Firebase Auth
  final String fullName;
  final String? avatarUrl;
  final String? phone;
  final String email;
  final DateTime? dob;
  final String? address;
  final Gender? gender;
  final Role role;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserAccount({
    required this.id,
    required this.fullName,
    this.avatarUrl,
    this.phone,
    required this.email,
    this.dob,
    this.address,
    this.gender,
    this.role = Role.member,
    required this.createdAt,
    required this.updatedAt,
  }) {
    // Validate data in constructor
    try {
      if (id.isEmpty) throw ArgumentError('ID cannot be empty');
      if (fullName.isEmpty) throw ArgumentError('Full name cannot be empty');
      if (email.isEmpty) throw ArgumentError('Email cannot be empty');
      // Additional validation for dates
      if (dob != null) {
        final now = DateTime.now();
        if (dob!.isAfter(now) || dob!.year < 1900) {
          print('Invalid birth date: $dob');
        }
      }
    } catch (e) {
      print('UserAccount validation warning: $e');
    }
  }

  factory UserAccount.fromMap(Map<String, dynamic> map) {
    try {
      return UserAccount(
        id: map['id'] ?? '',
        fullName: map['fullName'] ?? '',
        avatarUrl: map['avatarUrl'],
        phone: map['phone'],
        email: map['email'] ?? '',
        dob: _parseDateTime(map['dob']),
        address: map['address'],
        gender: genderFromString(map['gender']),
        role: roleFromString(map['role'] ?? 'member'),
        createdAt: _parseDateTime(map['createdAt']) ?? DateTime.now(),
        updatedAt: _parseDateTime(map['updatedAt']) ?? DateTime.now(),
      );
    } catch (e) {
      print('Error parsing UserAccount from map: $e');
      print('Map data: $map');
      rethrow;
    }
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    try {
      if (value is int) {
        // Check if timestamp is reasonable (after 1970 and before 2100)
        if (value < 0 || value > 4102444800000) {
          print('Invalid timestamp: $value');
          return null;
        }
        return DateTime.fromMillisecondsSinceEpoch(value);
      } else if (value is Timestamp) {
        return value.toDate();
      } else if (value is String) {
        // Try to parse as timestamp string
        final intValue = int.tryParse(value);
        if (intValue != null) {
          return _parseDateTime(intValue);
        }
      }
      return null;
    } catch (e) {
      print('Error parsing DateTime from value: $value, error: $e');
      return null;
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'fullName': fullName,
      'avatarUrl': avatarUrl,
      'phone': phone,
      'email': email,
      'dob': dob?.millisecondsSinceEpoch,
      'address': address,
      'gender': genderToString(gender),
      'role': roleToString(role),
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
    };
  }

  factory UserAccount.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;
    if (data == null) {
      throw Exception('Document data is null');
    }

    return UserAccount.fromMap({...data, 'id': doc.id});
  }

  UserAccount copyWith({
    String? id,
    String? fullName,
    String? avatarUrl,
    String? phone,
    String? email,
    DateTime? dob,
    String? address,
    Gender? gender,
    Role? role,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserAccount(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      dob: dob ?? this.dob,
      address: address ?? this.address,
      gender: gender ?? this.gender,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Helper methods
  static Role roleFromString(String value) {
    switch (value.toLowerCase()) {
      case 'member':
        return Role.member;
      case 'staff':
        return Role.staff;
      case 'manager':
        return Role.manager;
      case 'admin':
        return Role.admin;
      case 'membershipcard':
        return Role.membershipCard;
      case 'trainer':
        return Role.trainer;
      default:
        return Role.member;
    }
  }

  static String roleToString(Role role) {
    switch (role) {
      case Role.member:
        return 'member';
      case Role.staff:
        return 'staff';
      case Role.manager:
        return 'manager';
      case Role.admin:
        return 'admin';
      case Role.membershipCard:
        return 'membershipCard';
      case Role.trainer:
        return 'trainer';
    }
  }

  // Gender helper methods
  static Gender? genderFromString(String? value) {
    if (value == null) return null;
    switch (value.toLowerCase()) {
      case 'male':
        return Gender.male;
      case 'female':
        return Gender.female;
      case 'other':
        return Gender.other;
      default:
        return null;
    }
  }

  static String? genderToString(Gender? gender) {
    if (gender == null) return null;
    switch (gender) {
      case Gender.male:
        return 'male';
      case Gender.female:
        return 'female';
      case Gender.other:
        return 'other';
    }
  }

  // Convenience getters
  String get roleDisplayName {
    switch (role) {
      case Role.member:
        return 'Member';
      case Role.staff:
        return 'Staff';
      case Role.manager:
        return 'Manager';
      case Role.admin:
        return 'Admin';
      case Role.membershipCard:
        return 'Membership Card';
      case Role.trainer:
        return 'Personal Trainer';
    }
  }

  bool get isAdmin => role == Role.admin;
  bool get isManager => role == Role.manager || isAdmin;
  bool get isStaff => role == Role.staff || isManager;
  bool get isMember => role == Role.member;
  bool get isTrainer => role == Role.trainer;

  @override
  String toString() {
    return 'UserAccount{id: $id, fullName: $fullName, email: $email, role: ${roleToString(role)}}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is UserAccount &&
        other.id == id &&
        other.fullName == fullName &&
        other.avatarUrl == avatarUrl &&
        other.phone == phone &&
        other.email == email &&
        other.dob == dob &&
        other.address == address &&
        other.gender == gender &&
        other.role == role &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        fullName.hashCode ^
        avatarUrl.hashCode ^
        phone.hashCode ^
        email.hashCode ^
        dob.hashCode ^
        address.hashCode ^
        gender.hashCode ^
        role.hashCode ^
        createdAt.hashCode ^
        updatedAt.hashCode;
  }
}
