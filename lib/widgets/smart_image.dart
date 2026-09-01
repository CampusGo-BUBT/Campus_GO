import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

/// Renders an image that may be either:
///   * a base64 data URI ("data:image/...;base64,...") -> Image.memory
///   * a normal http(s) URL -> Image.network
///
/// Use this anywhere the backend might return a base64 image string.
class SmartImage extends StatelessWidget {
  final String? src;
  final BoxFit fit;
  final double? width;
  final double? height;

  const SmartImage(this.src,
      {super.key, this.fit = BoxFit.cover, this.width, this.height});

  static bool isDataUri(String? s) => s != null && s.startsWith('data:');

  static Uint8List? decodeDataUri(String s) {
    final idx = s.indexOf(',');
    if (idx == -1) return null;
    try {
      return base64Decode(s.substring(idx + 1));
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = src;
    if (s == null || s.isEmpty) {
      return const SizedBox.shrink();
    }
    if (isDataUri(s)) {
      final bytes = decodeDataUri(s);
      if (bytes != null) {
        return Image.memory(bytes, fit: fit, width: width, height: height,
            gaplessPlayback: true);
      }
      return const SizedBox.shrink();
    }
    return Image.network(s,
        fit: fit,
        width: width,
        height: height,
        errorBuilder: (_, _, _) => const SizedBox.shrink());
  }
}

/// Memory-image equivalent for use inside CircleAvatar / NetworkImage contexts.
/// Convenience: decode a data URI into bytes, or null if not a data URI.
Uint8List? imageBytesFromSrc(String? src) {
  if (src == null || !SmartImage.isDataUri(src)) return null;
  return SmartImage.decodeDataUri(src);
}

/// Returns an [ImageProvider] for a source that may be a base64 data URI or a
/// normal URL. Use inside CircleAvatar(backgroundImage: ...).
ImageProvider? imageProviderFor(String? src) {
  if (src == null || src.isEmpty) return null;
  final bytes = imageBytesFromSrc(src);
  if (bytes != null) return MemoryImage(bytes);
  return NetworkImage(src);
}
