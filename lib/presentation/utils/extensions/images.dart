import 'dart:async';

import 'package:boorusphere/presentation/utils/entity/pixel_size.dart';
import 'package:extended_image/extended_image.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_avif/flutter_avif.dart';

/// Builds the [ImageProvider] for a content [url], decoding AVIF (which
/// Flutter's built-in codecs can't handle) via flutter_avif. For every other
/// format it mirrors what [ExtendedImage.network] does, so non-AVIF images
/// keep their existing caching and resize behavior.
ImageProvider contentImageProvider(
  String url, {
  Map<String, String>? headers,
  int? cacheWidth,
  int? cacheHeight,
}) {
  if (url.toLowerCase().endsWith('.avif')) {
    // avif bytes can't pass through Flutter's codec/resize pipeline
    return CachedNetworkAvifImageProvider(url, headers: headers);
  }
  return ExtendedResizeImage.resizeIfNeeded(
    provider: ExtendedNetworkImageProvider(url, headers: headers, cache: true),
    cacheWidth: cacheWidth,
    cacheHeight: cacheHeight,
  );
}

extension ImageProviderExt<T> on ImageProvider {
  Future<PixelSize> resolvePixelSize() {
    final completer = Completer<PixelSize>();
    final resolver = resolve(const ImageConfiguration());
    final onComplete = ImageStreamListener((image, synchronousCall) {
      completer.complete(PixelSize(
        width: image.image.width,
        height: image.image.height,
      ));
    });
    resolver.addListener(onComplete);
    completer.future.whenComplete(() => resolver.removeListener(onComplete));
    return completer.future;
  }
}

extension ExtendedImageStateExt on ExtendedImageState {
  bool get isFailed {
    return extendedImageLoadState == LoadState.failed;
  }

  bool get isCompleted {
    return extendedImageLoadState == LoadState.completed;
  }

  Future<void> reload(
    Function() block, {
    Duration until = const Duration(milliseconds: 150),
  }) async {
    Future.delayed(until, (() {
      reLoadImage();
      block.call();
    }));
  }
}
