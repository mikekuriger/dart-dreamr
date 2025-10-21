// repository/dream_repository.dart
import 'dart:async';
import 'package:dreamr/models/dream.dart';
import 'package:dreamr/services/api_service.dart';
import 'package:dreamr/services/image_store.dart';
import 'package:dreamr/data/dream_dao.dart';
import 'package:dreamr/services/dio_client.dart';

class DreamRepository {
  final _dao = DreamDao();
  final _controller = StreamController<List<Dream>>.broadcast();
  Stream<List<Dream>> get stream => _controller.stream;

  /// === KEEP EXISTING NAME: used by DreamListModel ===
  Future<List<Dream>> loadLocal({bool includeHidden = false}) async {
    final local = await _dao.getAll(includeHidden: includeHidden);
    _controller.add(local);
    return local;
  }

  /// === KEEP EXISTING NAME: used by DreamListModel ===
  /// Local-first: updates DB from server, then emits new local snapshot.
  Future<void> syncFromServer({
    bool includeHidden = false,
    bool prefetchImages = true,
  }) async {
    // Use existing endpoints only (no updatedSince yet).
    final remote = includeHidden
        ? await ApiService.fetchAllDreams()
        : await ApiService.fetchDreams();

    await _dao.upsertMany(remote);

    if (prefetchImages) {
      for (final d in remote) {
        // These helpers are already defined in your ImageStore
        await ImageStore.prefetchForDream(
          dreamId: d.id,
          imageFileUrl: d.imageFile,
          imageTileUrl: d.imageTile,
          dio: DioClient.dio, // pass shared Dio for auth/cookies
        );
      }
    }

    final updated = await _dao.getAll(includeHidden: includeHidden);
    _controller.add(updated);
  }

  void dispose() => _controller.close();
}
