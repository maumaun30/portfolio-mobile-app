import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../api/upload_api.dart';
import '../theme/tokens.dart';
import 'section_label.dart';

enum _Phase { picker, uploading, done, error }

/// Bottom-sheet image picker → upload → return URL.
///
/// Used by anything that stores a Vercel Blob URL in a row (project cover,
/// post cover, future media fields). Returns the uploaded URL via
/// `Navigator.pop(context, url)` so callers can `await showModalBottomSheet`.
class ImageUploadSheet extends ConsumerStatefulWidget {
  const ImageUploadSheet({super.key, this.folder = 'uploads'});

  final String folder;

  /// Convenience launcher. Returns the uploaded URL, or null if the user
  /// cancels.
  static Future<String?> show(
    BuildContext context, {
    String folder = 'uploads',
  }) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      barrierColor: const Color.fromRGBO(10, 9, 7, 0.7),
      builder: (_) => ImageUploadSheet(folder: folder),
    );
  }

  @override
  ConsumerState<ImageUploadSheet> createState() => _ImageUploadSheetState();
}

class _ImageUploadSheetState extends ConsumerState<ImageUploadSheet> {
  final _picker = ImagePicker();
  _Phase _phase = _Phase.picker;
  File? _file;
  int _sent = 0;
  int _total = 0;
  String? _resultUrl;
  String? _error;
  CancelToken? _cancel;
  DateTime? _startedAt;
  Duration? _elapsed;

  Future<void> _pickFrom(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        maxWidth: 2400,
        imageQuality: 90,
      );
      if (picked == null) return;
      setState(() {
        _file = File(picked.path);
        _phase = _Phase.uploading;
        _sent = 0;
        _total = 0;
        _error = null;
        _startedAt = DateTime.now();
      });
      await _upload();
    } catch (e) {
      setState(() {
        _phase = _Phase.error;
        _error = e.toString();
      });
    }
  }

  Future<void> _upload() async {
    final file = _file;
    if (file == null) return;
    _cancel = CancelToken();
    try {
      final res = await ref.read(uploadApiProvider).uploadFile(
            file: file,
            folder: widget.folder,
            onProgress: (sent, total) {
              if (!mounted) return;
              setState(() {
                _sent = sent;
                _total = total > 0 ? total : sent;
              });
            },
            cancelToken: _cancel,
          );
      if (!mounted) return;
      setState(() {
        _phase = _Phase.done;
        _resultUrl = res.url;
        _elapsed = _startedAt != null
            ? DateTime.now().difference(_startedAt!)
            : null;
      });
    } on DioException catch (e) {
      if (CancelToken.isCancel(e)) {
        if (!mounted) return;
        setState(() => _phase = _Phase.picker);
        return;
      }
      if (!mounted) return;
      setState(() {
        _phase = _Phase.error;
        _error = e.response?.data is Map
            ? (e.response!.data['error']?.toString() ?? e.message ?? 'Upload failed')
            : (e.message ?? 'Upload failed');
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _phase = _Phase.error;
        _error = e.toString();
      });
    }
  }

  @override
  void dispose() {
    _cancel?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: mq.viewInsets.bottom),
      child: Container(
        padding: EdgeInsets.fromLTRB(20, 12, 20, 22 + mq.padding.bottom * 0.5),
        decoration: BoxDecoration(
          color: AppTokens.surface,
          border: Border(top: BorderSide(color: AppTokens.lineStrong)),
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(22)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 4, bottom: 18),
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTokens.lineStrong,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            _Header(phase: _phase),
            const SizedBox(height: 18),
            switch (_phase) {
              _Phase.picker => _PickerBody(
                  onCamera: () => _pickFrom(ImageSource.camera),
                  onGallery: () => _pickFrom(ImageSource.gallery),
                  onCancel: () => Navigator.of(context).pop(),
                ),
              _Phase.uploading => _UploadingBody(
                  file: _file!,
                  sent: _sent,
                  total: _total,
                  onCancel: () => _cancel?.cancel(),
                ),
              _Phase.done => _DoneBody(
                  file: _file!,
                  url: _resultUrl!,
                  elapsed: _elapsed,
                  onUseAnother: () {
                    setState(() {
                      _phase = _Phase.picker;
                      _file = null;
                      _resultUrl = null;
                      _elapsed = null;
                    });
                  },
                  onUse: () => Navigator.of(context).pop(_resultUrl),
                ),
              _Phase.error => _ErrorBody(
                  message: _error ?? 'Upload failed',
                  onRetry: _file == null
                      ? null
                      : () {
                          setState(() {
                            _phase = _Phase.uploading;
                            _sent = 0;
                            _error = null;
                            _startedAt = DateTime.now();
                          });
                          _upload();
                        },
                  onPickAnother: () => setState(() {
                    _phase = _Phase.picker;
                    _file = null;
                    _error = null;
                  }),
                ),
            },
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────── header

class _Header extends StatelessWidget {
  const _Header({required this.phase});
  final _Phase phase;

  @override
  Widget build(BuildContext context) {
    final title = switch (phase) {
      _Phase.picker => 'Upload image',
      _Phase.uploading => 'Uploading…',
      _Phase.done => 'Image uploaded',
      _Phase.error => 'Upload failed',
    };
    final subtitle = switch (phase) {
      _Phase.done => '— VERCEL BLOB · COMMITTED',
      _ => '— VERCEL BLOB · PUBLIC',
    };
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: AppTokens.ink,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 10.5,
                  letterSpacing: 0.06 * 10.5,
                  color: AppTokens.inkMuted,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(LucideIcons.x, size: 20, color: AppTokens.inkDim),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }
}

// ──────────────────────────────────────────────── picker

class _PickerBody extends StatelessWidget {
  const _PickerBody({
    required this.onCamera,
    required this.onGallery,
    required this.onCancel,
  });
  final VoidCallback onCamera;
  final VoidCallback onGallery;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InkWell(
          onTap: onGallery,
          borderRadius: BorderRadius.circular(AppTokens.cardRadius),
          child: Container(
            height: 160,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppTokens.cardRadius),
              border:
                  Border.all(color: AppTokens.lineStrong, width: 1.5),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(LucideIcons.upload,
                    size: 26, color: AppTokens.inkDim),
                const SizedBox(height: 10),
                const Text(
                  'Tap to pick a file',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppTokens.ink,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'PNG, JPG, WebP · up to 8 MB',
                  style:
                      TextStyle(fontSize: 12, color: AppTokens.inkMuted),
                ),
                Text(
                  'auto-resized to 2400 px wide',
                  style:
                      TextStyle(fontSize: 12, color: AppTokens.inkMuted),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),
        const SectionLabel('Or pick from'),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTokens.cardRadius),
            border: Border.all(color: AppTokens.line),
          ),
          child: Column(
            children: [
              _SourceRow(
                icon: LucideIcons.image,
                label: 'Photo library',
                onTap: onGallery,
              ),
              Divider(color: AppTokens.line, height: 1),
              _SourceRow(
                icon: LucideIcons.camera,
                label: 'Camera',
                onTap: onCamera,
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        OutlinedButton(
          onPressed: onCancel,
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}

class _SourceRow extends StatelessWidget {
  const _SourceRow({
    required this.icon,
    required this.label,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 18, color: AppTokens.inkDim),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppTokens.ink,
                ),
              ),
            ),
            const Icon(LucideIcons.chevronRight,
                size: 15, color: AppTokens.inkMuted),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────── uploading

class _UploadingBody extends StatelessWidget {
  const _UploadingBody({
    required this.file,
    required this.sent,
    required this.total,
    required this.onCancel,
  });
  final File file;
  final int sent;
  final int total;
  final VoidCallback onCancel;

  String get _name => file.path.split(RegExp(r'[\\/]')).last;
  double get _progress => total <= 0 ? 0 : (sent / total).clamp(0, 1).toDouble();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _FileTile(
          file: file,
          trailing: const SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppTokens.ink,
            ),
          ),
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w500,
                  color: AppTokens.ink,
                  letterSpacing: -0.05,
                ),
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: LinearProgressIndicator(
                  value: _progress > 0 ? _progress : null,
                  minHeight: 4,
                  backgroundColor: AppTokens.surfaceHi,
                  valueColor: const AlwaysStoppedAnimation(AppTokens.accent),
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Text(
                    'UPLOADING · ${(_progress * 100).round()}%',
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 10.5,
                      letterSpacing: 0.04 * 10.5,
                      color: AppTokens.inkMuted,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${_formatBytes(sent)} / ${_formatBytes(total)}',
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 10.5,
                      letterSpacing: 0.04 * 10.5,
                      color: AppTokens.inkMuted,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: onCancel,
                child: const Text('Cancel'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FilledButton(
                onPressed: null,
                style: FilledButton.styleFrom(
                  disabledBackgroundColor: AppTokens.surfaceHi,
                  disabledForegroundColor: AppTokens.inkMuted,
                ),
                child: const Text('Uploading…'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ──────────────────────────────────────────────── done

class _DoneBody extends StatelessWidget {
  const _DoneBody({
    required this.file,
    required this.url,
    required this.elapsed,
    required this.onUseAnother,
    required this.onUse,
  });
  final File file;
  final String url;
  final Duration? elapsed;
  final VoidCallback onUseAnother;
  final VoidCallback onUse;

  String get _name => file.path.split(RegExp(r'[\\/]')).last;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _FileTile(
          file: file,
          trailing: Container(
            width: 22,
            height: 22,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppTokens.accent,
            ),
            child: const Icon(LucideIcons.check,
                size: 14, color: AppTokens.onAccent),
          ),
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w500,
                  color: AppTokens.ink,
                  letterSpacing: -0.05,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(LucideIcons.checkCircle2,
                      size: 11, color: AppTokens.accent),
                  const SizedBox(width: 6),
                  Text(
                    'UPLOADED${elapsed != null ? ' · ${(elapsed!.inMilliseconds / 1000).toStringAsFixed(1)} s' : ''}',
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 10.5,
                      letterSpacing: 0.04 * 10.5,
                      color: AppTokens.accent,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'BLOB URL',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppTokens.inkDim,
            letterSpacing: 0.04 * 12,
          ),
        ),
        const SizedBox(height: 7),
        Container(
          padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
          decoration: BoxDecoration(
            color: AppTokens.bg,
            borderRadius: BorderRadius.circular(AppTokens.inputRadius),
            border: Border.all(color: AppTokens.line),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  url,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 12,
                    color: AppTokens.ink,
                    letterSpacing: -0.01 * 12,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: () async {
                  await Clipboard.setData(ClipboardData(text: url));
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        backgroundColor: AppTokens.surface,
                        duration: Duration(seconds: 1),
                        content: Text(
                          'Copied URL',
                          style: TextStyle(color: AppTokens.ink),
                        ),
                      ),
                    );
                  }
                },
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: AppTokens.surfaceHi,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(LucideIcons.copy,
                      size: 13, color: AppTokens.ink),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: onUseAnother,
                child: const Text('Upload another'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FilledButton(
                onPressed: onUse,
                child: const Text('Use this image'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ──────────────────────────────────────────────── error

class _ErrorBody extends StatelessWidget {
  const _ErrorBody({
    required this.message,
    required this.onRetry,
    required this.onPickAnother,
  });
  final String message;
  final VoidCallback? onRetry;
  final VoidCallback onPickAnother;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: AppTokens.danger10,
            borderRadius: BorderRadius.circular(AppTokens.inputRadius),
            border: Border.all(color: AppTokens.danger.withOpacity(0.3)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(LucideIcons.alertTriangle,
                  size: 16, color: AppTokens.danger),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: AppTokens.danger,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: onPickAnother,
                child: const Text('Pick another'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FilledButton(
                onPressed: onRetry,
                child: const Text('Retry'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ──────────────────────────────────────────────── file tile (shared)

class _FileTile extends StatelessWidget {
  const _FileTile({
    required this.file,
    required this.body,
    required this.trailing,
  });
  final File file;
  final Widget body;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTokens.bg,
        borderRadius: BorderRadius.circular(AppTokens.cardRadius),
        border: Border.all(color: AppTokens.line),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Stack(
              alignment: Alignment.bottomRight,
              children: [
                SizedBox(
                  width: 80,
                  height: 80,
                  child: Image.file(file, fit: BoxFit.cover),
                ),
                Padding(
                  padding: const EdgeInsets.all(6),
                  child: trailing,
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(child: body),
        ],
      ),
    );
  }
}

String _formatBytes(int bytes) {
  if (bytes <= 0) return '0 KB';
  const k = 1024;
  if (bytes < k * k) return '${(bytes / k).toStringAsFixed(0)} KB';
  return '${(bytes / (k * k)).toStringAsFixed(1)} MB';
}
