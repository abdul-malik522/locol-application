class TwoFactorAuthModel {
  const TwoFactorAuthModel({
    required this.isEnabled,
    this.secretKey,
    this.backupCodes,
    this.setupDate,
  });

  final bool isEnabled;
  final String? secretKey; // TOTP secret key
  final List<String>? backupCodes; // Backup codes for recovery
  final DateTime? setupDate;

  TwoFactorAuthModel copyWith({
    bool? isEnabled,
    String? secretKey,
    List<String>? backupCodes,
    DateTime? setupDate,
  }) {
    return TwoFactorAuthModel(
      isEnabled: isEnabled ?? this.isEnabled,
      secretKey: secretKey ?? this.secretKey,
      backupCodes: backupCodes ?? this.backupCodes,
      setupDate: setupDate ?? this.setupDate,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'isEnabled': isEnabled,
      'secretKey': secretKey,
      'backupCodes': backupCodes,
      'setupDate': setupDate?.toIso8601String(),
    };
  }

  factory TwoFactorAuthModel.fromJson(Map<String, dynamic> json) {
    return TwoFactorAuthModel(
      isEnabled: json['isEnabled'] ?? false,
      secretKey: json['secretKey'],
      backupCodes: json['backupCodes'] != null
          ? List<String>.from(json['backupCodes'])
          : null,
      setupDate: json['setupDate'] != null
          ? DateTime.parse(json['setupDate'])
          : null,
    );
  }
}

