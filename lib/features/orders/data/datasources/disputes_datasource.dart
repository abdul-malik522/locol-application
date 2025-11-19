import 'package:localtrade/features/orders/data/models/dispute_model.dart';
import 'package:uuid/uuid.dart';

class DisputesDataSource {
  DisputesDataSource._();
  static final DisputesDataSource instance = DisputesDataSource._();
  final _uuid = const Uuid();

  final List<DisputeModel> _disputes = [];

  Future<List<DisputeModel>> getDisputes(String userId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _disputes
        .where((d) => d.filedBy == userId || d.opposingParty == userId)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Future<DisputeModel?> getDisputeById(String disputeId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    try {
      return _disputes.firstWhere((d) => d.id == disputeId);
    } catch (_) {
      return null;
    }
  }

  Future<DisputeModel?> getDisputeByOrderId(String orderId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    try {
      return _disputes.firstWhere((d) => d.orderId == orderId);
    } catch (_) {
      return null;
    }
  }

  Future<DisputeModel> fileDispute(DisputeModel dispute) async {
    await Future.delayed(const Duration(milliseconds: 500));
    _disputes.insert(0, dispute);
    return dispute;
  }

  Future<DisputeModel> updateDisputeStatus(
    String disputeId,
    DisputeStatus newStatus, {
    String? adminResponse,
    String? resolution,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final index = _disputes.indexWhere((d) => d.id == disputeId);
    if (index == -1) throw Exception('Dispute not found');

    final dispute = _disputes[index];
    final updated = dispute.copyWith(
      status: newStatus,
      adminResponse: adminResponse ?? dispute.adminResponse,
      resolution: resolution ?? dispute.resolution,
      resolvedAt: (newStatus == DisputeStatus.resolved ||
              newStatus == DisputeStatus.closed ||
              newStatus == DisputeStatus.rejected)
          ? DateTime.now()
          : dispute.resolvedAt,
    );

    _disputes[index] = updated;
    return updated;
  }

  Future<List<DisputeModel>> getAllDisputes() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return List.from(_disputes)..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }
}

