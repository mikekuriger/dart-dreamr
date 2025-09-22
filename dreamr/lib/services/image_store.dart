// services/image_store.dart
import 'dart:io';
import 'dart:async';
import 'package:dio/dio.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

enum DreamImageKind { file, tile }

class ImageStore {
  static Future<Directory> _imagesDir() async {
    final base = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(base.path, 'images'));
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  static String _extFromUrl(String url) {
    final seg = Uri.parse(url).pathSegments;
    final last = seg.isNotEmpty ? seg.last : '';
    final ext = p.extension(last).toLowerCase();
    if (ext.isEmpty) return '.jpg'; // default
    // guard against query params like .jpg?sig=...
    final qIdx = ext.indexOf('?');
    return qIdx >= 0 ? ext.substring(0, qIdx) : ext;
  }

  static Future<File> fileFor(int dreamId, DreamImageKind kind, String url) async {
    final dir = await _imagesDir();
    final ext = _extFromUrl(url);
    final name = '${dreamId}_${kind.name}$ext';
    return File(p.join(dir.path, name));
  }

  static Future<File?> localIfExists(int dreamId, DreamImageKind kind, String url) async {
    final f = await fileFor(dreamId, kind, url);
    return (await f.exists()) && (await f.length()) > 0 ? f : null;
  }

  static Future<File> download(int dreamId, DreamImageKind kind, String url, {Dio? dio}) async {
    final f = await fileFor(dreamId, kind, url);
    if (await f.exists() && (await f.length()) > 0) return f;
    final tmp = File('${f.path}.part');
    await tmp.parent.create(recursive: true);
    final client = dio ?? Dio();
    final res = await client.get<List<int>>(
      url,
      options: Options(responseType: ResponseType.bytes, followRedirects: true),
    );
    await tmp.writeAsBytes(res.data!);
    await tmp.rename(f.path);
    return f;
  }

  static Future<void> prefetchForDream({
    required int dreamId,
    String? imageFileUrl,
    String? imageTileUrl,
    Dio? dio,
  }) async {
    if (imageFileUrl != null && imageFileUrl.isNotEmpty) {
      // fire and forget
      unawaited(download(dreamId, DreamImageKind.file, imageFileUrl, dio: dio));
    }
    if (imageTileUrl != null && imageTileUrl.isNotEmpty) {
      unawaited(download(dreamId, DreamImageKind.tile, imageTileUrl, dio: dio));
    }
  }
}
