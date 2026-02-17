import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';

/// Captures Flutter widgets as images for social sharing.
class ImageExporter {
  ImageExporter._();

  static final _screenshotController = ScreenshotController();

  /// Capture the widget associated with [key] as a PNG image.
  ///
  /// Returns `null` if the render boundary cannot be found.
  static Future<Uint8List?> captureWidget(GlobalKey key) async {
    final boundary = key.currentContext?.findRenderObject();
    if (boundary == null) return null;

    return _screenshotController.captureFromWidget(
      Builder(builder: (_) {
        // The widget tree under the key is already built; we re-render via
        // the screenshot controller which paints the boundary off-screen.
        final widget = key.currentContext?.widget;
        return widget ?? const SizedBox.shrink();
      }),
      pixelRatio: 3.0,
    );
  }

  /// Capture an arbitrary [widget] to a PNG image without requiring it to be
  /// part of the current widget tree.
  static Future<Uint8List> captureFromWidget(
    Widget widget, {
    double pixelRatio = 3.0,
    Size targetSize = Size.zero,
  }) {
    return _screenshotController.captureFromWidget(
      widget,
      pixelRatio: pixelRatio,
      targetSize: targetSize == Size.zero ? null : targetSize,
    );
  }

  /// Save [imageBytes] to a temp file and share it via the platform share
  /// sheet.
  static Future<void> shareImage(
    Uint8List imageBytes,
    String title,
  ) async {
    final dir = await getTemporaryDirectory();
    final file = File(
      '${dir.path}/${title.replaceAll(RegExp(r'[^\w\-.]'), '_')}.png',
    );
    await file.writeAsBytes(imageBytes);
    await Share.shareXFiles([XFile(file.path)], text: title);
  }
}
