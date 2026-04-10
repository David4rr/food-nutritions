import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';

class DashboardIdleCatOverlay extends StatelessWidget {
  const DashboardIdleCatOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: SafeArea(
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: const SizedBox(
              width: 210,
              height: 210,
              child: _DotLottieAsset(
                assetPath: 'assets/Le Petit Chat _Cat_ Noir.lottie',
                fallbackIcon: Icons.pets_rounded,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DotLottieAsset extends StatefulWidget {
  const _DotLottieAsset({required this.assetPath, required this.fallbackIcon});

  final String assetPath;
  final IconData fallbackIcon;

  @override
  State<_DotLottieAsset> createState() => _DotLottieAssetState();
}

class _DotLottieAssetState extends State<_DotLottieAsset> {
  late final Future<Uint8List?> _animationBytesFuture;

  @override
  void initState() {
    super.initState();
    _animationBytesFuture = _extractDotLottieJson(widget.assetPath);
  }

  Future<Uint8List?> _extractDotLottieJson(String assetPath) async {
    final data = await rootBundle.load(assetPath);
    final zipBytes = data.buffer.asUint8List();
    final archive = ZipDecoder().decodeBytes(zipBytes, verify: true);

    ArchiveFile? animationFile;
    for (final file in archive.files) {
      if (!file.isFile) continue;
      final name = file.name.toLowerCase();
      final isAnimationJson =
          name.startsWith('animations/') && name.endsWith('.json');
      if (isAnimationJson) {
        animationFile = file;
        break;
      }
    }
    if (animationFile == null) return null;

    final content = animationFile.content;
    if (content is List<int>) {
      return _stabilizeIdleCatMotion(Uint8List.fromList(content));
    }
    if (content is Uint8List) {
      return _stabilizeIdleCatMotion(content);
    }
    return null;
  }

  Uint8List _stabilizeIdleCatMotion(Uint8List bytes) {
    try {
      final data = jsonDecode(utf8.decode(bytes));
      if (data is! Map<String, dynamic>) return bytes;

      final layers = data['layers'];
      if (layers is! List) return bytes;

      for (final layer in layers) {
        if (layer is! Map<String, dynamic>) continue;
        if (layer['nm'] != 'Nul 1') continue;

        final ks = layer['ks'];
        if (ks is! Map<String, dynamic>) continue;

        final position = ks['p'];
        if (position is! Map<String, dynamic>) continue;

        final keyframes = position['k'];
        if (keyframes is! List || keyframes.isEmpty) continue;

        final firstKeyframe = keyframes.first;
        if (firstKeyframe is! Map<String, dynamic>) continue;

        final end = firstKeyframe['e'];
        if (end is! List || end.length < 3) continue;

        position['a'] = 0;
        position['k'] = [end[0], end[1], end[2]];
        break;
      }

      return Uint8List.fromList(utf8.encode(jsonEncode(data)));
    } catch (_) {
      return bytes;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List?>(
      future: _animationBytesFuture,
      builder: (context, snapshot) {
        final bytes = snapshot.data;
        if (bytes == null) {
          return _FallbackIdleIcon(icon: widget.fallbackIcon);
        }
        return Lottie.memory(
          bytes,
          fit: BoxFit.contain,
          repeat: true,
          errorBuilder: (context, error, stackTrace) {
            return _FallbackIdleIcon(icon: widget.fallbackIcon);
          },
        );
      },
    );
  }
}

class _FallbackIdleIcon extends StatelessWidget {
  const _FallbackIdleIcon({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Center(child: Icon(icon, size: 52, color: Colors.teal.shade300));
  }
}
