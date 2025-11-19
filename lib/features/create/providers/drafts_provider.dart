import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:localtrade/features/create/data/datasources/drafts_datasource.dart';
import 'package:localtrade/features/create/data/models/draft_post_model.dart';

final draftsDataSourceProvider = Provider<DraftsDataSource>((ref) {
  return DraftsDataSource.instance;
});

class DraftsNotifier extends StateNotifier<List<DraftPostModel>> {
  DraftsNotifier(this._dataSource, this._userId) : super([]) {
    loadDrafts();
  }

  final DraftsDataSource _dataSource;
  final String _userId;

  Future<void> loadDrafts() async {
    final drafts = await _dataSource.getDrafts(_userId);
    state = drafts;
  }

  Future<void> saveDraft(DraftPostModel draft) async {
    await _dataSource.saveDraft(draft);
    await loadDrafts();
  }

  Future<void> deleteDraft(String draftId) async {
    await _dataSource.deleteDraft(draftId);
    await loadDrafts();
  }

  Future<DraftPostModel?> getDraft(String draftId) async {
    return await _dataSource.getDraft(draftId);
  }

  Future<DraftPostModel?> getCurrentDraft() async {
    return await _dataSource.getCurrentDraft(_userId);
  }

  Future<void> saveCurrentDraft(DraftPostModel draft) async {
    await _dataSource.saveCurrentDraft(draft);
  }

  Future<void> clearCurrentDraft() async {
    await _dataSource.clearCurrentDraft();
  }
}

final draftsProvider = StateNotifierProvider.family<DraftsNotifier, List<DraftPostModel>, String>(
  (ref, userId) {
    final dataSource = ref.watch(draftsDataSourceProvider);
    return DraftsNotifier(dataSource, userId);
  },
);

