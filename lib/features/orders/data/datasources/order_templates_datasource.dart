import 'dart:convert';

import 'package:localtrade/features/orders/data/models/order_template_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OrderTemplatesDataSource {
  OrderTemplatesDataSource._();
  static final OrderTemplatesDataSource instance = OrderTemplatesDataSource._();

  static const String _templatesKeyPrefix = 'order_templates_';

  String _getTemplatesKey(String userId) => '$_templatesKeyPrefix$userId';

  Future<List<OrderTemplateModel>> getTemplates(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final String? templatesJson = prefs.getString(_getTemplatesKey(userId));
    if (templatesJson == null) {
      return [];
    }
    final List<dynamic> decoded = json.decode(templatesJson);
    return decoded
        .map((e) => OrderTemplateModel.fromJson(e as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  Future<void> saveTemplate(OrderTemplateModel template) async {
    final prefs = await SharedPreferences.getInstance();
    final List<OrderTemplateModel> existingTemplates = await getTemplates(template.userId);

    final int index = existingTemplates.indexWhere((t) => t.id == template.id);
    if (index != -1) {
      existingTemplates[index] = template; // Update existing template
    } else {
      existingTemplates.add(template); // Add new template
    }

    // Sort by most recent first
    existingTemplates.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

    final String encoded =
        json.encode(existingTemplates.map((e) => e.toJson()).toList());
    await prefs.setString(_getTemplatesKey(template.userId), encoded);
  }

  Future<void> deleteTemplate(String templateId, String userId) async {
    final prefs = await SharedPreferences.getInstance();
    List<OrderTemplateModel> existingTemplates = await getTemplates(userId);
    existingTemplates.removeWhere((t) => t.id == templateId);

    final String encoded =
        json.encode(existingTemplates.map((e) => e.toJson()).toList());
    await prefs.setString(_getTemplatesKey(userId), encoded);
  }

  Future<OrderTemplateModel?> getTemplate(String templateId, String userId) async {
    final List<OrderTemplateModel> existingTemplates = await getTemplates(userId);
    try {
      return existingTemplates.firstWhere((t) => t.id == templateId);
    } catch (e) {
      return null;
    }
  }
}

