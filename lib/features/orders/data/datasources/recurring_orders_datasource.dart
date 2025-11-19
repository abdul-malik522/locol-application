import 'package:localtrade/features/orders/data/models/recurring_order_model.dart';
import 'package:uuid/uuid.dart';

class RecurringOrdersDataSource {
  RecurringOrdersDataSource._();
  static final RecurringOrdersDataSource instance = RecurringOrdersDataSource._();
  final _uuid = const Uuid();

  final List<RecurringOrderModel> _recurringOrders = [];

  Future<List<RecurringOrderModel>> getRecurringOrders(String userId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _recurringOrders
        .where((ro) => ro.buyerId == userId && ro.isActive)
        .toList()
      ..sort((a, b) => a.nextOrderDate.compareTo(b.nextOrderDate));
  }

  Future<RecurringOrderModel?> getRecurringOrderById(String id) async {
    await Future.delayed(const Duration(milliseconds: 200));
    try {
      return _recurringOrders.firstWhere((ro) => ro.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<RecurringOrderModel> createRecurringOrder(RecurringOrderModel recurringOrder) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _recurringOrders.insert(0, recurringOrder);
    return recurringOrder;
  }

  Future<RecurringOrderModel> updateRecurringOrder(RecurringOrderModel updated) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final index = _recurringOrders.indexWhere((ro) => ro.id == updated.id);
    if (index == -1) throw Exception('Recurring order not found');
    _recurringOrders[index] = updated;
    return updated;
  }

  Future<void> pauseRecurringOrder(String id) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final index = _recurringOrders.indexWhere((ro) => ro.id == id);
    if (index == -1) throw Exception('Recurring order not found');
    _recurringOrders[index] = _recurringOrders[index].copyWith(isActive: false);
  }

  Future<void> resumeRecurringOrder(String id) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final index = _recurringOrders.indexWhere((ro) => ro.id == id);
    if (index == -1) throw Exception('Recurring order not found');
    _recurringOrders[index] = _recurringOrders[index].copyWith(isActive: true);
  }

  Future<void> cancelRecurringOrder(String id) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final index = _recurringOrders.indexWhere((ro) => ro.id == id);
    if (index == -1) throw Exception('Recurring order not found');
    _recurringOrders[index] = _recurringOrders[index].copyWith(isActive: false);
  }

  Future<void> incrementOccurrenceCount(String id) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final index = _recurringOrders.indexWhere((ro) => ro.id == id);
    if (index == -1) return;
    final current = _recurringOrders[index];
    final nextDate = current.calculateNextDate(current.nextOrderDate);
    _recurringOrders[index] = current.copyWith(
      occurrenceCount: current.occurrenceCount + 1,
      nextOrderDate: nextDate,
    );
  }
}

