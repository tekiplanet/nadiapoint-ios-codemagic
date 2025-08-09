import 'package:NadiaPoint/models/kyc_level.dart';
import 'package:NadiaPoint/models/user_details.dart';

class KYCDetails {
  final int currentLevel;
  final KYCLevel levelDetails;
  final UserDetails userDetails;
  final Map<String, dynamic>? kycData;
  final VerificationStatus? verificationStatus;

  KYCDetails({
    required this.currentLevel,
    required this.levelDetails,
    required this.userDetails,
    this.kycData,
    this.verificationStatus,
  });

  factory KYCDetails.fromJson(Map<String, dynamic> json) {
    return KYCDetails(
      currentLevel: json['currentLevel'] ?? 0,
      levelDetails: KYCLevel.fromJson(json['levelDetails'] ?? {}),
      userDetails: UserDetails.fromJson(json['userDetails'] ?? {}),
      kycData: json['kycData'],
      verificationStatus: json['kycData']?['verificationStatus'] != null
          ? VerificationStatus.fromJson(json['kycData']['verificationStatus'])
          : null,
    );
  }
}

class UserDetails {
  final String fullName;
  final String email;
  final bool emailVerified;
  final bool phoneVerified;

  UserDetails({
    required this.fullName,
    required this.email,
    required this.emailVerified,
    required this.phoneVerified,
  });

  factory UserDetails.fromJson(Map<String, dynamic> json) {
    return UserDetails(
      fullName: json['fullName'] ?? '',
      email: json['email'] ?? '',
      emailVerified: json['emailVerified'] ?? false,
      phoneVerified: json['phoneVerified'] ?? false,
    );
  }
}

class VerificationStatus {
  final IdentityVerification? identity;
  final AddressVerification? address;
  final AdvancedVerification? advanced;

  VerificationStatus({
    this.identity,
    this.address,
    this.advanced,
  });

  factory VerificationStatus.fromJson(Map<String, dynamic> json) {
    return VerificationStatus(
      identity: json['identity'] != null
          ? IdentityVerification.fromJson(json['identity'])
          : null,
      address: json['address'] != null
          ? AddressVerification.fromJson(json['address'])
          : null,
      advanced: json['advanced'] != null
          ? AdvancedVerification.fromJson(json['advanced'])
          : null,
    );
  }
}

class IdentityVerification {
  final String status;
  final String? documentType;
  final DateTime? lastAttempt;
  final String? failureReason;
  final String? reviewAnswer;
  final String? reviewRejectType;
  final String? reviewRejectDetails;
  final String? clientComment;

  IdentityVerification({
    required this.status,
    this.documentType,
    this.lastAttempt,
    this.failureReason,
    this.reviewAnswer,
    this.reviewRejectType,
    this.reviewRejectDetails,
    this.clientComment,
  });

  factory IdentityVerification.fromJson(Map<String, dynamic> json) {
    return IdentityVerification(
      status: json['status'],
      documentType: json['documentType'],
      lastAttempt: json['lastAttempt'] != null
          ? DateTime.parse(json['lastAttempt'])
          : null,
      failureReason: json['failureReason'],
      reviewAnswer: json['reviewAnswer'],
      reviewRejectType: json['reviewRejectType'],
      reviewRejectDetails: json['reviewRejectDetails'],
      clientComment: json['clientComment'],
    );
  }
}

class AddressVerification {
  final String status;
  final String? documentType;
  final DateTime? lastAttempt;
  final String? failureReason;

  AddressVerification({
    required this.status,
    this.documentType,
    this.lastAttempt,
    this.failureReason,
  });

  factory AddressVerification.fromJson(Map<String, dynamic> json) {
    return AddressVerification(
      status: json['status'],
      documentType: json['documentType'],
      lastAttempt: json['lastAttempt'] != null
          ? DateTime.parse(json['lastAttempt'])
          : null,
      failureReason: json['failureReason'],
    );
  }
}

class AdvancedVerification {
  final String status;
  final DateTime? lastAttempt;
  final String? reviewAnswer;
  final String? reviewRejectType;
  final String? reviewRejectDetails;
  final String? moderationComment;
  final String? clientComment;

  AdvancedVerification({
    required this.status,
    this.lastAttempt,
    this.reviewAnswer,
    this.reviewRejectType,
    this.reviewRejectDetails,
    this.moderationComment,
    this.clientComment,
  });

  factory AdvancedVerification.fromJson(Map<String, dynamic> json) {
    return AdvancedVerification(
      status: json['status'],
      lastAttempt: json['lastAttempt'] != null
          ? DateTime.parse(json['lastAttempt'])
          : null,
      reviewAnswer: json['reviewAnswer'],
      reviewRejectType: json['reviewRejectType'],
      reviewRejectDetails: json['reviewRejectDetails'],
      moderationComment: json['moderationComment'],
      clientComment: json['clientComment'],
    );
  }
}