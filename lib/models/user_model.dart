class UserModel {
  final String uid;
  final String fullName;
  final String email;
  final String phone;
  final String address;
  final String profilePictureUrl;
  final ProgressModel progress;
  final bool certificateIssued;
  final bool isAdmin;

  UserModel({
    required this.uid,
    required this.fullName,
    required this.email,
    required this.phone,
    this.address = '',
    this.profilePictureUrl = '',
    required this.progress,
    this.certificateIssued = false,
    this.isAdmin = false,
  });

  factory UserModel.fromMap(Map<String, dynamic> map, String uid) {
    return UserModel(
      uid: uid,
      fullName: map['fullName'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      address: map['address'] ?? '',
      profilePictureUrl: map['profilePictureUrl'] ?? '',
      progress: ProgressModel.fromMap(map['progress'] ?? {}),
      certificateIssued: map['certificateIssued'] ?? false,
      isAdmin: map['isAdmin'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'fullName': fullName,
      'email': email,
      'phone': phone,
      'address': address,
      'profilePictureUrl': profilePictureUrl,
      'progress': progress.toMap(),
      'certificateIssued': certificateIssued,
      'isAdmin': isAdmin,
    };
  }

  UserModel copyWith({
    String? fullName,
    String? email,
    String? phone,
    String? address,
    String? profilePictureUrl,
    ProgressModel? progress,
    bool? certificateIssued,
    bool? isAdmin,
  }) {
    return UserModel(
      uid: uid,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      profilePictureUrl: profilePictureUrl ?? this.profilePictureUrl,
      progress: progress ?? this.progress,
      certificateIssued: certificateIssued ?? this.certificateIssued,
      isAdmin: isAdmin ?? this.isAdmin,
    );
  }
}

class ProgressModel {
  final int attempted;
  final int correct;
  final int wrong;
  final double completionPercentage;

  ProgressModel({
    this.attempted = 0,
    this.correct = 0,
    this.wrong = 0,
    this.completionPercentage = 0.0,
  });

  factory ProgressModel.fromMap(Map<String, dynamic> map) {
    return ProgressModel(
      attempted: map['attempted'] ?? 0,
      correct: map['correct'] ?? 0,
      wrong: map['wrong'] ?? 0,
      completionPercentage: (map['completionPercentage'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'attempted': attempted,
      'correct': correct,
      'wrong': wrong,
      'completionPercentage': completionPercentage,
    };
  }

  ProgressModel copyWith({
    int? attempted,
    int? correct,
    int? wrong,
    double? completionPercentage,
  }) {
    return ProgressModel(
      attempted: attempted ?? this.attempted,
      correct: correct ?? this.correct,
      wrong: wrong ?? this.wrong,
      completionPercentage: completionPercentage ?? this.completionPercentage,
    );
  }
}

