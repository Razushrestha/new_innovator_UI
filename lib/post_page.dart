import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:ui';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'theme/brand_colors.dart';
import 'package:flutter/services.dart';

import 'widgets/liquid_button.dart';
import 'widgets/liquid_pressable.dart';
import 'widgets/wave_fill_painter.dart';

const _ink = BrandColors.ink;
const _muted = BrandColors.muted;
const _maxChars = 280;

enum AttachmentKind { image, video, pdf, file }

class PostAttachment {
  const PostAttachment({
    required this.kind,
    required this.name,
    required this.size,
    this.path,
  });

  final AttachmentKind kind;
  final String name;
  final int size;
  final String? path;
}

/// Compose section rendered inside the dashboard shell, so the dockable
/// liquid nav bar stays present while writing.
///
/// Liquid everywhere: the Post button fills with ink waves the moment the
/// post is ready, a droplet meter fills as you type, a sheen drifts across
/// the glass, and posting submerges the section under a liquid wave.
class PostSection extends StatefulWidget {
  const PostSection({
    super.key,
    required this.authorName,
    required this.onPosted,
    this.contentPadding = EdgeInsets.zero,
  });

  final String authorName;

  /// Called once the liquid wave has swallowed the screen; the shell
  /// switches back to the feed.
  final VoidCallback onPosted;

  /// Vertical clearances from the shell (kept clear of the docked bar).
  final EdgeInsets contentPadding;

  @override
  State<PostSection> createState() => _PostSectionState();
}

class _PostSectionState extends State<PostSection>
    with TickerProviderStateMixin {
  final _text = TextEditingController();
  final _focus = FocusNode();
  final _attachments = <PostAttachment>[];
  bool _picking = false;
  bool _posting = false;

  static const _hints = [
    'Share something inspiring…',
    'What did you build today?',
    'Drop your latest idea…',
    'Tell the community a story…',
  ];
  int _hintIndex = 0;
  Timer? _hintTimer;

  static const _audiences = [
    (Icons.public_rounded, 'Public'),
    (Icons.group_rounded, 'Followers'),
    (Icons.lock_rounded, 'Only me'),
  ];
  int _audience = 0;

  late final AnimationController _entrance = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  )..forward();

  /// Continuous phase driving every wave surface on the page.
  late final AnimationController _wave = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  )..repeat();

  /// Light band drifting across the composer glass.
  late final AnimationController _sheen = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 7),
  )..repeat();

  /// Liquid level inside the Post button: rests as a droplet at the
  /// bottom, rises and fills the button when the post becomes ready.
  late final AnimationController _fill = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
    value: .12,
  );

  bool get _canPost => _text.text.trim().isNotEmpty || _attachments.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _focus.addListener(() => setState(() {}));
    _hintTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (_text.text.isEmpty && mounted) {
        setState(() => _hintIndex = (_hintIndex + 1) % _hints.length);
      }
    });
  }

  @override
  void dispose() {
    _hintTimer?.cancel();
    _entrance.dispose();
    _wave.dispose();
    _sheen.dispose();
    _fill.dispose();
    _focus.dispose();
    _text.dispose();
    super.dispose();
  }

  void _syncFill() {
    final target = _canPost ? 1.0 : .12;
    if ((_fill.value - target).abs() > .001) {
      _fill.animateTo(target, curve: Curves.easeInOutCubic);
    }
  }

  Widget _stagger({required int index, required Widget child}) {
    final start = (index * .15).clamp(0.0, .6);
    final animation = CurvedAnimation(
      parent: _entrance,
      curve: Interval(
        start,
        (start + .45).clamp(0.0, 1.0),
        curve: Curves.easeOutCubic,
      ),
    );
    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, .06),
          end: Offset.zero,
        ).animate(animation),
        child: child,
      ),
    );
  }

  // ---------------------------------------------------------- attachments

  Future<void> _openAttachmentSheet() async {
    HapticFeedback.selectionClick();
    final kind = await showModalBottomSheet<AttachmentKind>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: _ink.withValues(alpha: .25),
      isScrollControlled: true,
      builder: (context) => const _AttachmentSheet(),
    );
    if (kind != null) await _pick(kind);
  }

  Future<void> _pick(AttachmentKind kind) async {
    if (_picking) return;
    _picking = true;
    try {
      final result = await FilePicker.pickFiles(
        allowMultiple: true,
        type: switch (kind) {
          AttachmentKind.image => FileType.image,
          AttachmentKind.video => FileType.video,
          AttachmentKind.pdf => FileType.custom,
          AttachmentKind.file => FileType.any,
        },
        allowedExtensions: kind == AttachmentKind.pdf ? const ['pdf'] : null,
      );
      if (result == null || !mounted) return;
      setState(() {
        for (final file in result.files) {
          _attachments.add(
            PostAttachment(
              kind: _kindOf(file, kind),
              name: file.name,
              size: file.size,
              path: file.path,
            ),
          );
        }
      });
      _syncFill();
      HapticFeedback.lightImpact();
    } on PlatformException {
      // Picker unavailable (e.g. permission denied) — nothing to add.
    } finally {
      _picking = false;
    }
  }

  /// "Any file" picks still get the right icon/preview based on extension.
  AttachmentKind _kindOf(PlatformFile file, AttachmentKind pickedAs) {
    final ext = (file.extension ?? '').toLowerCase();
    if (const {
      'jpg',
      'jpeg',
      'png',
      'gif',
      'webp',
      'bmp',
      'heic',
    }.contains(ext)) {
      return AttachmentKind.image;
    }
    if (const {'mp4', 'mov', 'mkv', 'avi', 'webm'}.contains(ext)) {
      return AttachmentKind.video;
    }
    if (ext == 'pdf') return AttachmentKind.pdf;
    return pickedAs == AttachmentKind.file ? AttachmentKind.file : pickedAs;
  }

  void _removeAttachment(PostAttachment attachment) {
    HapticFeedback.selectionClick();
    setState(() => _attachments.remove(attachment));
    _syncFill();
  }

  // ----------------------------------------------------------------- post

  void _submit() {
    if (!_canPost || _posting) return;
    HapticFeedback.mediumImpact();
    _focus.unfocus();
    setState(() => _posting = true);
    // Let the liquid wave swallow the screen, then melt back to the feed.
    Future.delayed(const Duration(milliseconds: 950), () {
      if (!mounted) return;
      HapticFeedback.lightImpact();
      ScaffoldMessenger.of(context).showSnackBar(_liveSnackBar());
      widget.onPosted();
    });
  }

  SnackBar _liveSnackBar() {
    return SnackBar(
      behavior: SnackBarBehavior.floating,
      backgroundColor: Colors.transparent,
      elevation: 0,
      duration: const Duration(seconds: 2),
      content: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 13),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            gradient: LinearGradient(
              colors: [
                BrandColors.secondarySurface.withValues(alpha: .95),
                BrandColors.secondarySurface.withValues(alpha: .92),
              ],
            ),
            border: Border.all(color: Colors.white.withValues(alpha: .25)),
            boxShadow: [
              BoxShadow(
                color: _ink.withValues(alpha: .25),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.check_circle_rounded,
                color: Color(0xFF6EE7B7),
                size: 20,
              ),
              SizedBox(width: 10),
              Text(
                'Your post is live',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------- build

  @override
  Widget build(BuildContext context) {
    final padding = widget.contentPadding;
    return Stack(
      fit: StackFit.expand,
      children: [
        Column(
          children: [
            Expanded(
              child: ListView(
                padding: EdgeInsets.fromLTRB(20, padding.top + 6, 20, 12),
                children: [_stagger(index: 0, child: _buildComposer())],
              ),
            ),
            _stagger(index: 1, child: _buildActions()),
          ],
        ),
        if (_posting) _PostingWave(wave: _wave),
      ],
    );
  }

  // ------------------------------------------------------------- composer

  Widget _buildComposer() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withValues(alpha: _focus.hasFocus ? .70 : .62),
                Colors.white.withValues(alpha: _focus.hasFocus ? .40 : .32),
              ],
            ),
            border: Border.all(
              color: Colors.white.withValues(alpha: _focus.hasFocus ? 1 : .75),
              width: _focus.hasFocus ? 1.4 : 1,
            ),
            boxShadow: _focus.hasFocus
                ? [
                    BoxShadow(
                      color: _ink.withValues(alpha: .12),
                      blurRadius: 34,
                      offset: const Offset(0, 16),
                    ),
                  ]
                : const [],
          ),
          child: Stack(
            children: [
              // Light band drifting slowly across the glass.
              Positioned.fill(
                child: IgnorePointer(
                  child: AnimatedBuilder(
                    animation: _sheen,
                    builder: (context, _) => Align(
                      alignment: Alignment(-1.8 + 3.6 * _sheen.value, 0),
                      child: Transform.rotate(
                        angle: -.55,
                        child: Container(
                          width: 80,
                          height: 500,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.white.withValues(alpha: 0),
                                Colors.white.withValues(alpha: .30),
                                Colors.white.withValues(alpha: 0),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _AuthorRow(
                      name: widget.authorName,
                      audienceIcon: _audiences[_audience].$1,
                      audienceLabel: _audiences[_audience].$2,
                      onAudienceTap: () {
                        HapticFeedback.selectionClick();
                        setState(
                          () => _audience = (_audience + 1) % _audiences.length,
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildTextArea(),
                    if (_attachments.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      _AttachmentPreview(
                        attachments: _attachments,
                        onRemove: _removeAttachment,
                      ),
                    ],
                    const SizedBox(height: 12),
                    Container(height: 1, color: _ink.withValues(alpha: .07)),
                    const SizedBox(height: 10),
                    _buildQuickRow(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextArea() {
    const hintStyle = TextStyle(color: _muted, fontSize: 16, height: 1.5);
    return Stack(
      children: [
        // Rotating prompt: swaps every few seconds while the field is
        // empty, sliding up like liquid finding a new level.
        if (_text.text.isEmpty)
          IgnorePointer(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 450),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              transitionBuilder: (child, animation) => FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, .5),
                    end: Offset.zero,
                  ).animate(animation),
                  child: child,
                ),
              ),
              child: Text(
                _hints[_hintIndex],
                key: ValueKey(_hintIndex),
                style: hintStyle,
              ),
            ),
          ),
        TextField(
          controller: _text,
          focusNode: _focus,
          onChanged: (_) {
            setState(() {});
            _syncFill();
          },
          maxLines: null,
          minLines: 5,
          maxLength: _maxChars,
          textCapitalization: TextCapitalization.sentences,
          style: const TextStyle(fontSize: 16, height: 1.5, color: _ink),
          cursorColor: _ink,
          decoration: const InputDecoration(
            isCollapsed: true,
            border: InputBorder.none,
            counterText: '',
          ),
        ),
      ],
    );
  }

  /// Quick-attach shortcuts plus the ink-drop character meter.
  Widget _buildQuickRow() {
    return Row(
      children: [
        _QuickAttach(
          icon: Icons.image_rounded,
          tint: const Color(0xFF2563EB),
          tooltip: 'Photo',
          onTap: () => _pick(AttachmentKind.image),
        ),
        _QuickAttach(
          icon: Icons.videocam_rounded,
          tint: const Color(0xFF7C3AED),
          tooltip: 'Video',
          onTap: () => _pick(AttachmentKind.video),
        ),
        _QuickAttach(
          icon: Icons.picture_as_pdf_rounded,
          tint: const Color(0xFFDC2626),
          tooltip: 'PDF',
          onTap: () => _pick(AttachmentKind.pdf),
        ),
        _QuickAttach(
          icon: Icons.folder_rounded,
          tint: const Color(0xFFB45309),
          tooltip: 'Any file',
          onTap: () => _pick(AttachmentKind.file),
        ),
        const Spacer(),
        if (_text.text.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Text(
              '${_maxChars - _text.text.length}',
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: _text.text.length > _maxChars - 30
                    ? const Color(0xFFE0245E)
                    : _muted,
              ),
            ),
          ),
        // Droplet that fills with ink as the post grows.
        AnimatedBuilder(
          animation: _wave,
          builder: (context, _) => Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: .55),
              border: Border.all(color: Colors.white.withValues(alpha: .95)),
            ),
            child: ClipOval(
              child: CustomPaint(
                painter: WaveFillPainter(
                  phase: _wave.value * 2 * pi,
                  fill: (_text.text.length / _maxChars).clamp(0.0, 1.0),
                  color: _text.text.length > _maxChars - 30
                      ? const Color(0xFFE0245E).withValues(alpha: .85)
                      : _ink.withValues(alpha: .8),
                  amplitude: 2,
                  frequency: 1.6,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // -------------------------------------------------------------- actions

  Widget _buildActions() {
    // Clear the docked nav when the keyboard is closed; when typing, the
    // nav stays under the keyboard so only a light inset is needed.
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;
    final bottom = keyboard > 0
        ? 12.0
        : max(18.0, widget.contentPadding.bottom - 24);
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 4, 20, bottom),
      child: Row(
        children: [
          Expanded(
            child: LiquidButton(
              label: 'Attachment',
              dark: false,
              leading: const Icon(
                Icons.attach_file_rounded,
                size: 19,
                color: _ink,
              ),
              onTap: _openAttachmentSheet,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _LiquidPostButton(wave: _wave, fill: _fill, onTap: _submit),
          ),
        ],
      ),
    );
  }
}

// ------------------------------------------------------------ post button

/// The Post button as a vessel of liquid ink: a droplet rests at the
/// bottom while the post is empty, and the moment there is something to
/// share the ink rises in animated waves and floods the whole button.
class _LiquidPostButton extends StatelessWidget {
  const _LiquidPostButton({
    required this.wave,
    required this.fill,
    required this.onTap,
  });

  final AnimationController wave;
  final AnimationController fill;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return LiquidPressable(
      onTap: onTap,
      borderRadius: BorderRadius.circular(23),
      rippleColor: Colors.white,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: AnimatedBuilder(
          animation: Listenable.merge([wave, fill]),
          builder: (context, _) {
            final level = fill.value;
            final phase = wave.value * 2 * pi;
            final labelColor = Color.lerp(
              _ink,
              Colors.white,
              ((level - .35) / .45).clamp(0, 1),
            )!;
            return Container(
              height: 57,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(23),
                color: Colors.white.withValues(alpha: .40),
                border: Border.all(
                  color: Colors.white.withValues(alpha: .9),
                  width: 1.2,
                ),
                boxShadow: level > .9
                    ? [
                        BoxShadow(
                          color: _ink.withValues(alpha: .28),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ]
                    : const [],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Trailing lighter wave, slightly ahead of the main one.
                    CustomPaint(
                      painter: WaveFillPainter(
                        phase: phase + 2.1,
                        fill: level * 1.02 + .02,
                        color: _ink.withValues(alpha: .30),
                        amplitude: 5,
                        frequency: 1.3,
                      ),
                    ),
                    CustomPaint(
                      painter: WaveFillPainter(
                        phase: phase,
                        fill: level,
                        color: BrandColors.secondarySurface.withValues(
                          alpha: .92,
                        ),
                        amplitude: 4,
                        frequency: 1.5,
                      ),
                    ),
                    Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.send_rounded, size: 17, color: labelColor),
                          const SizedBox(width: 10),
                          Text(
                            'Post',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              letterSpacing: .4,
                              color: labelColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Full-screen liquid wave that rises and swallows the page on submit,
/// surfacing a check mark once the screen is submerged.
class _PostingWave extends StatelessWidget {
  const _PostingWave({required this.wave});

  final AnimationController wave;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1.06),
        duration: const Duration(milliseconds: 750),
        curve: Curves.easeInOutCubic,
        builder: (context, t, _) => AnimatedBuilder(
          animation: wave,
          builder: (context, _) {
            final phase = wave.value * 2 * pi;
            final reveal = Curves.elasticOut.transform(
              ((t - .62) / .44).clamp(0, 1),
            );
            return Stack(
              fit: StackFit.expand,
              children: [
                CustomPaint(
                  painter: WaveFillPainter(
                    phase: phase + 1.8,
                    fill: t * 1.04,
                    color: _ink.withValues(alpha: .30),
                    amplitude: 26,
                    frequency: 1.15,
                  ),
                ),
                CustomPaint(
                  painter: WaveFillPainter(
                    phase: phase,
                    fill: t,
                    color: BrandColors.secondarySurface.withValues(alpha: .97),
                    amplitude: 20,
                    frequency: 1.35,
                  ),
                ),
                if (reveal > 0)
                  Center(
                    child: Opacity(
                      opacity: ((t - .62) / .3).clamp(0, 1),
                      child: Transform.scale(
                        scale: reveal,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 76,
                              height: 76,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withValues(alpha: .12),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: .55),
                                  width: 1.5,
                                ),
                              ),
                              child: const Icon(
                                Icons.check_rounded,
                                size: 40,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 14),
                            const Text(
                              'Posting…',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                letterSpacing: .3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------- widgets

class _QuickAttach extends StatelessWidget {
  const _QuickAttach({
    required this.icon,
    required this.tint,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final Color tint;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Tooltip(
        message: tooltip,
        child: LiquidPressable(
          onTap: onTap,
          borderRadius: BorderRadius.circular(19),
          rippleColor: tint,
          intensity: .6,
          child: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  tint.withValues(alpha: .16),
                  tint.withValues(alpha: .06),
                ],
              ),
              border: Border.all(color: tint.withValues(alpha: .22)),
            ),
            child: Icon(icon, size: 18, color: tint),
          ),
        ),
      ),
    );
  }
}

class _AuthorRow extends StatelessWidget {
  const _AuthorRow({
    required this.name,
    required this.audienceIcon,
    required this.audienceLabel,
    required this.onAudienceTap,
  });

  final String name;
  final IconData audienceIcon;
  final String audienceLabel;
  final VoidCallback onAudienceTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF3A4154), BrandColors.secondarySurface],
            ),
            border: Border.all(color: Colors.white.withValues(alpha: .9)),
            boxShadow: [
              BoxShadow(
                color: _ink.withValues(alpha: .22),
                blurRadius: 12,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Text(
            name.isEmpty ? 'I' : name[0].toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 15.5,
                  fontWeight: FontWeight.w700,
                  color: _ink,
                ),
              ),
              const SizedBox(height: 5),
              // Tap to cycle who can see the post.
              LiquidPressable(
                onTap: onAudienceTap,
                borderRadius: BorderRadius.circular(20),
                rippleColor: _ink,
                intensity: .5,
                child: AnimatedSize(
                  duration: const Duration(milliseconds: 280),
                  curve: Curves.easeOutCubic,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 3.5,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: Colors.white.withValues(alpha: .55),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: .9),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 260),
                          transitionBuilder: (child, animation) =>
                              ScaleTransition(scale: animation, child: child),
                          child: Icon(
                            audienceIcon,
                            key: ValueKey(audienceIcon),
                            size: 12.5,
                            color: _muted,
                          ),
                        ),
                        const SizedBox(width: 5),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 260),
                          transitionBuilder: (child, animation) =>
                              FadeTransition(opacity: animation, child: child),
                          child: Text(
                            audienceLabel,
                            key: ValueKey(audienceLabel),
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: _muted,
                            ),
                          ),
                        ),
                        const SizedBox(width: 3),
                        Icon(
                          Icons.keyboard_arrow_down_rounded,
                          size: 13,
                          color: _muted.withValues(alpha: .8),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------- attachment previews

class _AttachmentPreview extends StatelessWidget {
  const _AttachmentPreview({required this.attachments, required this.onRemove});

  final List<PostAttachment> attachments;
  final void Function(PostAttachment) onRemove;

  @override
  Widget build(BuildContext context) {
    final images = attachments
        .where((a) => a.kind == AttachmentKind.image && a.path != null)
        .toList();
    final others = attachments.where((a) => !images.contains(a)).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (images.isNotEmpty)
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final image in images)
                _ImageThumb(attachment: image, onRemove: () => onRemove(image)),
            ],
          ),
        if (images.isNotEmpty && others.isNotEmpty) const SizedBox(height: 10),
        for (final file in others) ...[
          _FileTile(attachment: file, onRemove: () => onRemove(file)),
          if (file != others.last) const SizedBox(height: 8),
        ],
      ],
    );
  }
}

class _ImageThumb extends StatelessWidget {
  const _ImageThumb({required this.attachment, required this.onRemove});

  final PostAttachment attachment;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 96,
          height: 96,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withValues(alpha: .9)),
            boxShadow: [
              BoxShadow(
                color: _ink.withValues(alpha: .16),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(17),
            child: Image.file(
              File(attachment.path!),
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color: Colors.white.withValues(alpha: .5),
                child: const Icon(Icons.image_rounded, color: _muted),
              ),
            ),
          ),
        ),
        Positioned(top: -7, right: -7, child: _RemoveBadge(onTap: onRemove)),
      ],
    );
  }
}

class _FileTile extends StatelessWidget {
  const _FileTile({required this.attachment, required this.onRemove});

  final PostAttachment attachment;
  final VoidCallback onRemove;

  (IconData, Color) get _style => switch (attachment.kind) {
    AttachmentKind.video => (
      Icons.play_circle_fill_rounded,
      const Color(0xFF7C3AED),
    ),
    AttachmentKind.pdf => (
      Icons.picture_as_pdf_rounded,
      const Color(0xFFDC2626),
    ),
    AttachmentKind.image => (Icons.image_rounded, const Color(0xFF2563EB)),
    AttachmentKind.file => (Icons.insert_drive_file_rounded, _ink),
  };

  @override
  Widget build(BuildContext context) {
    final (icon, tint) = _style;
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 10, 8, 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: Colors.white.withValues(alpha: .55),
        border: Border.all(color: Colors.white.withValues(alpha: .9)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(13),
              color: tint.withValues(alpha: .12),
            ),
            child: Icon(icon, size: 22, color: tint),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  attachment.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: _ink,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _formatBytes(attachment.size),
                  style: const TextStyle(fontSize: 11.5, color: _muted),
                ),
              ],
            ),
          ),
          _RemoveBadge(onTap: onRemove),
        ],
      ),
    );
  }
}

class _RemoveBadge extends StatelessWidget {
  const _RemoveBadge({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return LiquidPressable(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      rippleColor: Colors.white,
      intensity: .5,
      child: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _ink.withValues(alpha: .88),
          border: Border.all(color: Colors.white.withValues(alpha: .85)),
        ),
        child: const Icon(Icons.close_rounded, size: 14, color: Colors.white),
      ),
    );
  }
}

// -------------------------------------------------------- attachment sheet

class _AttachmentSheet extends StatelessWidget {
  const _AttachmentSheet();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.white.withValues(alpha: .82),
                Colors.white.withValues(alpha: .58),
              ],
            ),
            border: Border(
              top: BorderSide(color: Colors.white.withValues(alpha: .95)),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 18),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 42,
                      height: 4.5,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        color: _ink.withValues(alpha: .18),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Add attachment',
                    style: TextStyle(
                      fontSize: 16.5,
                      fontWeight: FontWeight.w700,
                      color: _ink,
                      letterSpacing: -.2,
                    ),
                  ),
                  const SizedBox(height: 14),
                  const _SheetOption(
                    kind: AttachmentKind.image,
                    icon: Icons.image_rounded,
                    tint: Color(0xFF2563EB),
                    title: 'Photo',
                    subtitle: 'JPG, PNG, GIF and more',
                  ),
                  const _SheetOption(
                    kind: AttachmentKind.video,
                    icon: Icons.videocam_rounded,
                    tint: Color(0xFF7C3AED),
                    title: 'Video',
                    subtitle: 'MP4, MOV and more',
                  ),
                  const _SheetOption(
                    kind: AttachmentKind.pdf,
                    icon: Icons.picture_as_pdf_rounded,
                    tint: Color(0xFFDC2626),
                    title: 'PDF document',
                    subtitle: 'Share reports and papers',
                  ),
                  const _SheetOption(
                    kind: AttachmentKind.file,
                    icon: Icons.folder_rounded,
                    tint: Color(0xFFB45309),
                    title: 'Browse files',
                    subtitle: 'Any file type is supported',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SheetOption extends StatelessWidget {
  const _SheetOption({
    required this.kind,
    required this.icon,
    required this.tint,
    required this.title,
    required this.subtitle,
  });

  final AttachmentKind kind;
  final IconData icon;
  final Color tint;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: LiquidPressable(
        onTap: () => Navigator.of(context).pop(kind),
        borderRadius: BorderRadius.circular(20),
        rippleColor: tint,
        intensity: .55,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: Colors.white.withValues(alpha: .55),
            border: Border.all(color: Colors.white.withValues(alpha: .95)),
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      tint.withValues(alpha: .18),
                      tint.withValues(alpha: .08),
                    ],
                  ),
                  border: Border.all(color: tint.withValues(alpha: .22)),
                ),
                child: Icon(icon, size: 23, color: tint),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: _ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(fontSize: 12, color: _muted),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: _muted),
            ],
          ),
        ),
      ),
    );
  }
}

String _formatBytes(int bytes) {
  if (bytes <= 0) return '—';
  const units = ['B', 'KB', 'MB', 'GB'];
  var value = bytes.toDouble();
  var unit = 0;
  while (value >= 1024 && unit < units.length - 1) {
    value /= 1024;
    unit++;
  }
  return '${value.toStringAsFixed(value >= 100 || unit == 0 ? 0 : 1)} '
      '${units[unit]}';
}
