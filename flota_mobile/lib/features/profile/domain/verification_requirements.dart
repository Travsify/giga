import 'package:flutter/material.dart';

/// Document verification status types
enum DocStatus { required, optional, choiceGroup }

/// Represents a verification document requirement
class VerificationDoc {
  final String id;
  final String label;
  final String description;
  final IconData icon;
  final DocStatus status;
  final String? choiceGroupId;

  const VerificationDoc({
    required this.id,
    required this.label,
    required this.description,
    required this.icon,
    this.status = DocStatus.required,
    this.choiceGroupId,
  });
}

/// Country-specific verification requirements
class VerificationRequirements {
  static const Map<String, List<VerificationDoc>> requirements = {
    'NG': [
      VerificationDoc(
        id: 'nin',
        label: 'NIN (National ID)',
        description: 'National Identification Number slip or card',
        icon: Icons.badge_outlined,
        status: DocStatus.choiceGroup,
        choiceGroupId: 'identity',
      ),
      VerificationDoc(
        id: 'intl_passport',
        label: 'International Passport',
        description: 'Valid Nigerian international passport',
        icon: Icons.public,
        status: DocStatus.choiceGroup,
        choiceGroupId: 'identity',
      ),
      VerificationDoc(
        id: 'driver_license',
        label: 'Driver License',
        description: 'Valid Nigerian driving permit',
        icon: Icons.drive_eta_outlined,
        status: DocStatus.required,
      ),
      VerificationDoc(
        id: 'passport_photo',
        label: 'Passport Photo',
        description: 'Clear headshot photo for your profile',
        icon: Icons.photo_camera_outlined,
        status: DocStatus.required,
      ),
    ],
    'UK': [
      VerificationDoc(
        id: 'dvla_license',
        label: 'Driving Licence',
        description: 'Valid UK DVLA driving licence',
        icon: Icons.drive_eta_outlined,
        status: DocStatus.required,
      ),
      VerificationDoc(
        id: 'passport',
        label: 'Passport',
        description: 'Valid UK or foreign passport',
        icon: Icons.public,
        status: DocStatus.required,
      ),
      VerificationDoc(
        id: 'passport_photo',
        label: 'Passport Photo',
        description: 'Clear headshot photo for your profile',
        icon: Icons.photo_camera_outlined,
        status: DocStatus.required,
      ),
      VerificationDoc(
        id: 'brp',
        label: 'BRP (Residence Permit)',
        description: 'Biometric Residence Permit for non-UK nationals',
        icon: Icons.fingerprint,
        status: DocStatus.optional,
      ),
    ],
  };

  /// Get requirements for a specific country
  static List<VerificationDoc> getForCountry(String countryCode) {
    return requirements[countryCode.toUpperCase()] ?? [];
  }

  /// Get choice group documents
  static List<VerificationDoc> getChoiceGroup(String countryCode, String groupId) {
    return getForCountry(countryCode)
        .where((doc) => doc.choiceGroupId == groupId)
        .toList();
  }

  /// Check if a document is part of a choice group
  static bool isInChoiceGroup(VerificationDoc doc) {
    return doc.status == DocStatus.choiceGroup && doc.choiceGroupId != null;
  }

  /// Supported countries
  static const List<Map<String, String>> supportedCountries = [
    {'code': 'NG', 'name': 'Nigeria', 'flag': '🇳🇬'},
    {'code': 'UK', 'name': 'United Kingdom', 'flag': '🇬🇧'},
  ];
}
