import 'dart:io';

import 'package:boorusphere/constant/feature-flags.dart';
import 'package:boorusphere/pigeon/storage_util.pi.dart';
import 'package:media_scanner/media_scanner.dart';
import 'package:path/path.dart' as p;
import 'package:permission_handler/permission_handler.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'shared_storage_handle.g.dart';

@Riverpod(keepAlive: true)
SharedStorageHandle sharedStorageHandle(SharedStorageHandleRef ref) {
  throw UnimplementedError();
}

Future<SharedStorageHandle> provideSharedStorageHandle() async {
  if (!FeatureFlags.enableDownload) {
    return StubSharedStorageHandle();
  }
  final downloadPath = await StorageUtil().getDownloadPath();
  return SharedStorageHandle(downloadPath: downloadPath);
}

class SharedStorageHandle {
  SharedStorageHandle({required this.downloadPath});

  final String downloadPath;

  String get path {
    return p.join(downloadPath, 'Boorusphere');
  }

  File get _nomedia {
    return File(p.join(path, '.nomedia'));
  }

  bool get isHidden {
    return _nomedia.existsSync();
  }

  Future<void> init() async {
    await Permission.storage.request();
    final dir = Directory(path);
    if (!dir.existsSync()) {
      try {
        Directory(path).createSync();
        // ignore: empty_catches
      } catch (e) {}
    }
  }

  Directory createSubDir(String directory) {
    final dir = Directory(p.join(path, directory));
    try {
      dir.createSync();
      // ignore: empty_catches
    } catch (e) {}
    return dir;
  }

  bool fileExists(String relativePath) {
    final file = File(p.join(path, Uri.decodeFull(relativePath)));
    try {
      return file.existsSync();
      // ignore: empty_catches
    } catch (e) {}
    return false;
  }

  Future<void> rescan() async {
    await MediaScanner.loadMedia(path: path);
  }

  Future<void> hide(bool hide) async {
    await init();
    final isExists = _nomedia.existsSync();
    try {
      if (hide && !isExists) {
        await _nomedia.create();
      } else if (!hide && isExists) {
        await _nomedia.delete();
      }
      // ignore: empty_catches
    } catch (e) {}
    await rescan();
  }

  Future<void> open(String dest, {String? on}) async {
    try {
      final filePath = p.join(on ?? path, Uri.decodeFull(dest));
      await StorageUtil().open(filePath);
      // ignore: empty_catches
    } catch (e) {}
  }
}

class StubSharedStorageHandle extends SharedStorageHandle {
  StubSharedStorageHandle() : super(downloadPath: '');

  @override
  Future<void> init() async {}

  @override
  Directory createSubDir(String directory) {
    return Directory('');
  }

  @override
  bool fileExists(String relativePath) {
    return false;
  }

  @override
  Future<void> rescan() async {}

  @override
  Future<void> hide(bool hide) async {}

  @override
  Future<void> open(String dest, {String? on}) async {}
}
