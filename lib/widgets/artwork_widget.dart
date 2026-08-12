import 'dart:typed_data';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';

final Map<String, Uint8List?> artworkByteStore = {};

class ArtworkWidget extends StatefulWidget {
  final String? songId;
  final String? artworkUrl;
  final double size;
  final double borderRadius;
  final ArtworkType artworkType;

  const ArtworkWidget({
    super.key,
    this.songId,
    this.artworkUrl,
    this.size = 50,
    this.borderRadius = 8,
    this.artworkType = ArtworkType.AUDIO,
  });

  @override
  State<ArtworkWidget> createState() => _ArtworkWidgetState();
}

class _ArtworkWidgetState extends State<ArtworkWidget> {
  final OnAudioQuery _audioQuery = OnAudioQuery();
  Uint8List? _bytes;
  String? _activeKey;

  @override
  void initState() {
    super.initState();
    final key = widget.songId ?? widget.artworkUrl ?? '';
    if (key.isNotEmpty && artworkByteStore.containsKey(key)) {
      _bytes = artworkByteStore[key];
    }
    _resolveArtwork();
  }

  @override
  void didUpdateWidget(covariant ArtworkWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.songId != widget.songId || oldWidget.artworkUrl != widget.artworkUrl) {
      final key = widget.songId ?? widget.artworkUrl ?? '';
      if (key.isNotEmpty && artworkByteStore.containsKey(key)) {
        _bytes = artworkByteStore[key];
      } else {
        _bytes = null;
      }
      _resolveArtwork();
    }
  }

  void _resolveArtwork() async {
    final key = widget.songId ?? widget.artworkUrl ?? '';
    _activeKey = key;

    if (key.isEmpty) {
      if (mounted) setState(() => _bytes = null);
      return;
    }

    if (artworkByteStore.containsKey(key)) {
      if (mounted) {
        setState(() {
          _bytes = artworkByteStore[key];
        });
      }
      return;
    }

    final parsedId = int.tryParse(widget.songId ?? widget.artworkUrl ?? '');
    if (parsedId != null && parsedId > 0) {
      try {
        final b = await _audioQuery.queryArtwork(
          parsedId,
          widget.artworkType,
          format: ArtworkFormat.JPEG,
          size: 800,
          quality: 100,
        );
        artworkByteStore[key] = b;
        if (mounted && _activeKey == key) {
          setState(() {
            _bytes = b;
          });
        }
      } catch (e) {
        artworkByteStore[key] = null;
        if (mounted && _activeKey == key) {
          setState(() {
            _bytes = null;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fallbackColor = isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE5E5EA);

    Widget imageChild;

    if (widget.artworkUrl != null &&
        (widget.artworkUrl!.startsWith('http://') || widget.artworkUrl!.startsWith('https://'))) {
      imageChild = Image.network(
        widget.artworkUrl!,
        key: ValueKey(widget.artworkUrl!),
        fit: BoxFit.cover,
        gaplessPlayback: true,
        cacheWidth: (widget.size * 2).toInt(),
        cacheHeight: (widget.size * 2).toInt(),
        errorBuilder: (_, __, ___) => _buildPlaceholder(fallbackColor, isDark),
      );
    } else if (_bytes != null) {
      imageChild = Image.memory(
        _bytes!,
        key: ValueKey(_activeKey!),
        fit: BoxFit.cover,
        gaplessPlayback: true,
        errorBuilder: (_, __, ___) => _buildPlaceholder(fallbackColor, isDark),
      );
    } else if (widget.songId != null && int.tryParse(widget.songId!) != null) {
      imageChild = QueryArtworkWidget(
        key: ValueKey('query_${widget.songId}'),
        id: int.parse(widget.songId!),
        type: widget.artworkType,
        artworkFit: BoxFit.cover,
        artworkBorder: BorderRadius.circular(widget.borderRadius),
        artworkQuality: FilterQuality.high,
        size: 800,
        keepOldArtwork: false,
        nullArtworkWidget: _buildPlaceholder(fallbackColor, isDark),
      );
    } else {
      imageChild = _buildPlaceholder(fallbackColor, isDark);
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(widget.borderRadius),
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: imageChild,
      ),
    );
  }

  Widget _buildPlaceholder(Color color, bool isDark) {
    return Container(
      key: const ValueKey('placeholder'),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(widget.borderRadius),
      ),
      child: Center(
        child: Icon(
          widget.artworkType == ArtworkType.ARTIST
              ? CupertinoIcons.person_crop_circle_fill
              : CupertinoIcons.music_note,
          color: isDark ? Colors.white38 : Colors.black38,
          size: widget.size * 0.45,
        ),
      ),
    );
  }
}
