import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:localtrade/features/create/data/models/draft_post_model.dart';

class DraftsDataSource {
  DraftsDataSource._();
  static final DraftsDataSource instance = DraftsDataSource._();

  static const _draftsKey = 'draft_posts';
  static const _currentDraftKey = 'current_draft';

  /// Save a draft post
  Future<void> saveDraft(DraftPostModel draft) async {
    final prefs = await SharedPreferences.getInstance();
    final draftsJson = prefs.getStringList(_draftsKey) ?? [];
    
    // Remove existing draft with same ID if it exists
    draftsJson.removeWhere((json) {
      final draftMap = jsonDecode(json) as Map<String, dynamic>;
      return draftMap['id'] == draft.id;
    });
    
    // Add updated draft
    draftsJson.add(jsonEncode(draft.toJson()));
    
    await prefs.setStringList(_draftsKey, draftsJson);
  }

  /// Get all drafts for a user
  Future<List<DraftPostModel>> getDrafts(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final draftsJson = prefs.getStringList(_draftsKey) ?? [];
    
    final drafts = draftsJson
        .map((json) => DraftPostModel.fromJson(jsonDecode(json)))
        .where((draft) => draft.userId == userId)
        .toList();
    
    // Sort by updatedAt descending (most recent first)
    drafts.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    
    return drafts;
  }

  /// Get a specific draft by ID
  Future<DraftPostModel?> getDraft(String draftId) async {
    final prefs = await SharedPreferences.getInstance();
    final draftsJson = prefs.getStringList(_draftsKey) ?? [];
    
    for (final json in draftsJson) {
      final draftMap = jsonDecode(json) as Map<String, dynamic>;
      if (draftMap['id'] == draftId) {
        return DraftPostModel.fromJson(draftMap);
      }
    }
    
    return null;
  }

  /// Delete a draft
  Future<void> deleteDraft(String draftId) async {
    final prefs = await SharedPreferences.getInstance();
    final draftsJson = prefs.getStringList(_draftsKey) ?? [];
    
    draftsJson.removeWhere((json) {
      final draftMap = jsonDecode(json) as Map<String, dynamic>;
      return draftMap['id'] == draftId;
    });
    
    await prefs.setStringList(_draftsKey, draftsJson);
  }

  /// Save current draft (for auto-save)
  Future<void> saveCurrentDraft(DraftPostModel draft) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_currentDraftKey, jsonEncode(draft.toJson()));
  }

  /// Get current draft (for auto-save recovery)
  Future<DraftPostModel?> getCurrentDraft(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final draftJson = prefs.getString(_currentDraftKey);
    
    if (draftJson == null) return null;
    
    final draft = DraftPostModel.fromJson(jsonDecode(draftJson));
    
    // Only return if it belongs to the current user
    if (draft.userId != userId) return null;
    
    return draft;
  }

  /// Clear current draft
  Future<void> clearCurrentDraft() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_currentDraftKey);
  }
}

