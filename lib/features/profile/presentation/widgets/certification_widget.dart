import 'package:flutter/material.dart';
import 'package:localtrade/features/profile/data/models/certification_model.dart';

/// Widget to display a single certification
class CertificationWidget extends StatelessWidget {
  const CertificationWidget({
    required this.certification,
    this.showDetails = false,
    super.key,
  });

  final CertificationModel certification;
  final bool showDetails;

  @override
  Widget build(BuildContext context) {
    final isExpired = certification.isExpired;
    final isExpiringSoon = certification.isExpiringSoon;

    return Tooltip(
      message: _buildTooltipMessage(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isExpired
              ? Colors.grey.withOpacity(0.1)
              : certification.type.color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isExpired
                ? Colors.grey
                : isExpiringSoon
                    ? Colors.orange
                    : certification.type.color,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              certification.type.icon,
              size: 18,
              color: isExpired
                  ? Colors.grey
                  : certification.type.color,
            ),
            const SizedBox(width: 6),
            Text(
              certification.type.label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: isExpired
                        ? Colors.grey
                        : certification.type.color,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            if (isExpiringSoon && !isExpired) ...[
              const SizedBox(width: 4),
              Icon(
                Icons.warning_amber_rounded,
                size: 14,
                color: Colors.orange,
              ),
            ],
            if (isExpired) ...[
              const SizedBox(width: 4),
              Icon(
                Icons.cancel_outlined,
                size: 14,
                color: Colors.grey,
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _buildTooltipMessage() {
    final buffer = StringBuffer();
    buffer.writeln(certification.type.description);
    if (certification.certificationNumber != null) {
      buffer.writeln('Cert #: ${certification.certificationNumber}');
    }
    if (certification.issuingOrganization != null) {
      buffer.writeln('Issued by: ${certification.issuingOrganization}');
    }
    if (certification.issuedDate != null) {
      buffer.writeln('Issued: ${_formatDate(certification.issuedDate!)}');
    }
    if (certification.expiryDate != null) {
      if (certification.isExpired) {
        buffer.writeln('Expired: ${_formatDate(certification.expiryDate!)}');
      } else {
        buffer.writeln('Expires: ${_formatDate(certification.expiryDate!)}');
      }
    }
    return buffer.toString();
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

/// Widget to display multiple certifications
class CertificationsWidget extends StatelessWidget {
  const CertificationsWidget({
    required this.certifications,
    this.showDetails = false,
    this.wrap = true,
    super.key,
  });

  final List<CertificationModel> certifications;
  final bool showDetails;
  final bool wrap; // If true, wraps to multiple lines; if false, scrolls horizontally

  @override
  Widget build(BuildContext context) {
    if (certifications.isEmpty) return const SizedBox.shrink();

    if (wrap) {
      return Wrap(
        spacing: 8,
        runSpacing: 8,
        children: certifications
            .map((cert) => CertificationWidget(
                  certification: cert,
                  showDetails: showDetails,
                ))
            .toList(),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: certifications
            .map((cert) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: CertificationWidget(
                    certification: cert,
                    showDetails: showDetails,
                  ),
                ))
            .toList(),
      ),
    );
  }
}

