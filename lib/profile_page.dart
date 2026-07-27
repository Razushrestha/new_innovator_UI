import 'dart:math';
import 'dart:ui';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'theme/brand_colors.dart';
import 'widgets/animated_blob_background.dart';
import 'widgets/fast_glass.dart';
import 'widgets/liquid_pressable.dart';
import 'widgets/wave_fill_painter.dart';

const _ink = BrandColors.ink;

const _defaultCover = 'Assets/feed/post_07.jpg';

/// Student / learner profile fields editable from the profile menu.
class _LearnerInfo {
  const _LearnerInfo({
    required this.displayName,
    required this.fullName,
    required this.bio,
    required this.email,
    required this.phone,
    required this.dateOfBirth,
    required this.gender,
    required this.city,
    required this.country,
    required this.permanentAddress,
    required this.temporaryAddress,
    required this.zipCode,
    required this.school,
    required this.faculty,
    required this.educationLevel,
    required this.degree,
    required this.major,
    required this.yearLevel,
    required this.studentId,
    required this.enrollmentYear,
    required this.skills,
    required this.hobby,
    required this.learningGoals,
    required this.language,
    required this.portfolio,
    required this.facebook,
    required this.linkedin,
    required this.instagram,
    required this.github,
  });

  final String displayName;
  final String fullName;
  final String bio;
  final String email;
  final String phone;
  final String dateOfBirth;
  final String gender;
  final String city;
  final String country;
  final String permanentAddress;
  final String temporaryAddress;
  final String zipCode;
  final String school;
  final String faculty;
  final String educationLevel;
  final String degree;
  final String major;
  final String yearLevel;
  final String studentId;
  final String enrollmentYear;
  final String skills;
  final String hobby;
  final String learningGoals;
  final String language;
  final String portfolio;
  final String facebook;
  final String linkedin;
  final String instagram;
  final String github;

  _LearnerInfo copyWith({
    String? displayName,
    String? fullName,
    String? bio,
    String? email,
    String? phone,
    String? dateOfBirth,
    String? gender,
    String? city,
    String? country,
    String? permanentAddress,
    String? temporaryAddress,
    String? zipCode,
    String? school,
    String? faculty,
    String? educationLevel,
    String? degree,
    String? major,
    String? yearLevel,
    String? studentId,
    String? enrollmentYear,
    String? skills,
    String? hobby,
    String? learningGoals,
    String? language,
    String? portfolio,
    String? facebook,
    String? linkedin,
    String? instagram,
    String? github,
  }) {
    return _LearnerInfo(
      displayName: displayName ?? this.displayName,
      fullName: fullName ?? this.fullName,
      bio: bio ?? this.bio,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      gender: gender ?? this.gender,
      city: city ?? this.city,
      country: country ?? this.country,
      permanentAddress: permanentAddress ?? this.permanentAddress,
      temporaryAddress: temporaryAddress ?? this.temporaryAddress,
      zipCode: zipCode ?? this.zipCode,
      school: school ?? this.school,
      faculty: faculty ?? this.faculty,
      educationLevel: educationLevel ?? this.educationLevel,
      degree: degree ?? this.degree,
      major: major ?? this.major,
      yearLevel: yearLevel ?? this.yearLevel,
      studentId: studentId ?? this.studentId,
      enrollmentYear: enrollmentYear ?? this.enrollmentYear,
      skills: skills ?? this.skills,
      hobby: hobby ?? this.hobby,
      learningGoals: learningGoals ?? this.learningGoals,
      language: language ?? this.language,
      portfolio: portfolio ?? this.portfolio,
      facebook: facebook ?? this.facebook,
      linkedin: linkedin ?? this.linkedin,
      instagram: instagram ?? this.instagram,
      github: github ?? this.github,
    );
  }
}

_LearnerInfo _defaultLearnerInfo(String name) => _LearnerInfo(
      displayName: name,
      fullName: name,
      bio:
          'Building liquid products at Innovator. Design systems, Flutter, and '
          'ideas that ship. Always open to collaborate on the next breakthrough.',
      email: '${name.toLowerCase().replaceAll(' ', '.')}@innovator.edu',
      phone: '+977 98X-XXX-XXXX',
      dateOfBirth: '15 Mar 2003',
      gender: 'Prefer not to say',
      city: 'Kathmandu',
      country: 'Nepal',
      permanentAddress: 'Ward 5, Lazimpat, Kathmandu',
      temporaryAddress: 'Baneshwor, Kathmandu',
      zipCode: '44600',
      school: 'Innovator University',
      faculty: 'School of Technology',
      educationLevel: 'Bachelor level',
      degree: 'Bachelor',
      major: 'Computer Science',
      yearLevel: '3rd Year',
      studentId: 'INV-2023-0842',
      enrollmentYear: '2023',
      skills: 'Flutter, UI Design, Product Thinking',
      hobby: 'Photography, hiking, sketching UI ideas',
      learningGoals: 'Ship AI-assisted learning tools',
      language: 'English, Nepali',
      portfolio: 'innovator.app/u/${name.toLowerCase()}',
      facebook: 'https://facebook.com/${name.toLowerCase().replaceAll(' ', '')}',
      linkedin: 'https://linkedin.com/in/${name.toLowerCase().replaceAll(' ', '-')}',
      instagram: 'https://instagram.com/${name.toLowerCase().replaceAll(' ', '')}',
      github: 'https://github.com/${name.toLowerCase().replaceAll(' ', '')}',
    );

class _Person {
  const _Person({
    required this.name,
    required this.title,
    required this.colors,
  });

  final String name;
  final String title;
  final List<Color> colors;
}

/// People following the user (Collaborators).
const _collaboratorsList = [
  _Person(
    name: 'Maya Chen',
    title: 'Product Designer',
    colors: [Color(0xFF4C1D95), Color(0xFF7C3AED)],
  ),
  _Person(
    name: 'Aarav Sharma',
    title: 'Flutter Developer',
    colors: [Color(0xFF1E3A8A), Color(0xFF2563EB)],
  ),
  _Person(
    name: 'Priya Thapa',
    title: 'Brand Strategist',
    colors: [Color(0xFF9F1239), Color(0xFFE11D48)],
  ),
  _Person(
    name: 'Rohan KC',
    title: 'Growth Lead',
    colors: [Color(0xFF0F766E), Color(0xFF14B8A6)],
  ),
  _Person(
    name: 'Sneha Rai',
    title: 'UX Researcher',
    colors: [Color(0xFF9D174D), Color(0xFFDB2777)],
  ),
  _Person(
    name: 'Kabir Joshi',
    title: 'Full-stack Engineer',
    colors: [Color(0xFF3730A3), Color(0xFF4F46E5)],
  ),
  _Person(
    name: 'Anisha Gurung',
    title: 'Motion Designer',
    colors: [Color(0xFF92400E), Color(0xFFB45309)],
  ),
  _Person(
    name: 'Nischal Adhikari',
    title: 'Founder · Atlas',
    colors: [Color(0xFF166534), Color(0xFF16A34A)],
  ),
];

/// People the user is following (Collaborating).
const _collaboratingList = [
  _Person(
    name: 'Elena Voss',
    title: 'Design Systems',
    colors: [Color(0xFF1E3A8A), Color(0xFF2563EB)],
  ),
  _Person(
    name: 'Samir Basnet',
    title: 'AI Engineer',
    colors: [Color(0xFF0F766E), Color(0xFF0D9488)],
  ),
  _Person(
    name: 'Innovator Team',
    title: 'Official',
    colors: [Color(0xFFE0A800), BrandColors.accent],
  ),
  _Person(
    name: 'Lina Ortega',
    title: 'Product Manager',
    colors: [Color(0xFF5C2D91), Color(0xFF7C3AED)],
  ),
  _Person(
    name: 'Tenzin Lama',
    title: 'Illustrator',
    colors: [Color(0xFF9D174D), Color(0xFFDB2777)],
  ),
  _Person(
    name: 'Hana Park',
    title: 'Frontend Lead',
    colors: [Color(0xFF0A1C30), Color(0xFF14304A)],
  ),
];

class _TitleBadge {
  const _TitleBadge({
    required this.label,
    required this.icon,
    required this.colors,
  });

  final String label;
  final IconData icon;
  final List<Color> colors;
}

const _titles = [
  _TitleBadge(
    label: 'Innovator',
    icon: Icons.auto_awesome_rounded,
    colors: [Color(0xFFE0A800), BrandColors.accent],
  ),
  _TitleBadge(
    label: 'Creator',
    icon: Icons.palette_rounded,
    colors: [BrandColors.secondarySurface, Color(0xFF14304A)],
  ),
  _TitleBadge(
    label: 'Developer',
    icon: Icons.code_rounded,
    colors: [BrandColors.secondarySurface, Color(0xFF0F2A44)],
  ),
  _TitleBadge(
    label: 'Programmer',
    icon: Icons.terminal_rounded,
    colors: [Color(0xFF0A1C30), BrandColors.secondarySurface],
  ),
];

class _Innovation {
  const _Innovation({
    required this.title,
    required this.subtitle,
    required this.date,
    required this.coverAsset,
    required this.icon,
    required this.colors,
  });

  final String title;
  final String subtitle;
  final String date;
  final String coverAsset;
  final IconData icon;
  final List<Color> colors;
}

const _innovations = [
  _Innovation(
    title: 'Liquid Glass Nav',
    subtitle: 'Dockable bar with spring physics that feels alive on every tap.',
    date: 'Jul 22, 2026',
    coverAsset: 'Assets/feed/post_01.jpg',
    icon: Icons.water_drop_rounded,
    colors: [Color(0xFF1E3A8A), Color(0xFF2563EB)],
  ),
  _Innovation(
    title: 'Khalti Checkout',
    subtitle: 'Nepal-ready liquid payments with a glass checkout sheet.',
    date: 'Jul 18, 2026',
    coverAsset: 'Assets/feed/post_02.jpg',
    icon: Icons.account_balance_wallet_rounded,
    colors: [Color(0xFF5C2D91), Color(0xFF7C3AED)],
  ),
  _Innovation(
    title: 'Wave Fill System',
    subtitle: 'Shared liquid surfaces that ripple across the whole app.',
    date: 'Jul 12, 2026',
    coverAsset: 'Assets/feed/post_03.jpg',
    icon: Icons.waves_rounded,
    colors: [Color(0xFF0F766E), Color(0xFF14B8A6)],
  ),
  _Innovation(
    title: 'Bouncy Chat Drop',
    subtitle: 'Messages that fly in like water droplets with soft bounce.',
    date: 'Jul 5, 2026',
    coverAsset: 'Assets/feed/post_04.jpg',
    icon: Icons.chat_bubble_rounded,
    colors: [Color(0xFF9D174D), Color(0xFFDB2777)],
  ),
  _Innovation(
    title: 'E-learning Rails',
    subtitle: 'Featured and top-selling courses in smooth horizontal rails.',
    date: 'Jun 28, 2026',
    coverAsset: 'Assets/feed/post_05.jpg',
    icon: Icons.school_rounded,
    colors: [Color(0xFF92400E), Color(0xFFB45309)],
  ),
  _Innovation(
    title: 'Search Pill',
    subtitle: 'An icon that elongates into a focused search field.',
    date: 'Jun 20, 2026',
    coverAsset: 'Assets/feed/post_06.jpg',
    icon: Icons.search_rounded,
    colors: [Color(0xFF3730A3), Color(0xFF4F46E5)],
  ),
];

/// Full-screen view of another member's profile (opened from feed, etc.).
class AuthorProfilePage extends StatelessWidget {
  const AuthorProfilePage({super.key, required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          const AnimatedBlobBackground(),
          ProfileSection(
            name: name,
            contentPadding: EdgeInsets.fromLTRB(0, top, 0, 24),
            onBack: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}

/// Profile with cover banner, overlapping avatar, identity row, stats, and
/// innovations feed.
class ProfileSection extends StatefulWidget {
  const ProfileSection({
    super.key,
    required this.name,
    this.contentPadding = EdgeInsets.zero,
    this.onBack,
  });

  final String name;
  final EdgeInsets contentPadding;

  /// When set, this is treated as another person's profile: back replaces
  /// the options menu, and cover/avatar cameras are hidden.
  final VoidCallback? onBack;

  @override
  State<ProfileSection> createState() => _ProfileSectionState();
}

class _ProfileSectionState extends State<ProfileSection>
    with TickerProviderStateMixin {
  int _titleIndex = 0;
  Uint8List? _avatarBytes;
  Uint8List? _coverBytes;
  String? _cvFileName;
  late _LearnerInfo _info = _defaultLearnerInfo(widget.name);

  static const _collaborators = 128;
  static const _collaborating = 64;
  static const _innovationCount = 6;
  static const _avatarSize = 92.0;
  static const _coverHeight = 168.0;

  late final AnimationController _entrance = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..forward();

  late final AnimationController _wave = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  )..repeat();

  @override
  void dispose() {
    _entrance.dispose();
    _wave.dispose();
    super.dispose();
  }

  void _openPeopleSheet(
    BuildContext context, {
    required String title,
    required String subtitle,
    required List<_Person> people,
  }) {
    HapticFeedback.mediumImpact();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: _ink.withValues(alpha: .28),
      builder: (_) => _PeopleSheet(
        title: title,
        subtitle: subtitle,
        people: people,
      ),
    );
  }

  Widget _stagger({required int index, required Widget child}) {
    final start = (index * .1).clamp(0.0, .6);
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

  Future<Uint8List?> _pickImage() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.image,
        withData: true,
      );
      return result?.files.single.bytes;
    } catch (_) {
      if (!mounted) return null;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text('Could not open the photo picker'),
        ),
      );
      return null;
    }
  }

  Future<void> _changePhoto() async {
    HapticFeedback.mediumImpact();
    final bytes = await _pickImage();
    if (bytes != null && mounted) {
      setState(() => _avatarBytes = bytes);
    }
  }

  Future<void> _changeCover() async {
    HapticFeedback.mediumImpact();
    final bytes = await _pickImage();
    if (bytes != null && mounted) {
      setState(() => _coverBytes = bytes);
    }
  }

  Future<void> _manageCv() async {
    HapticFeedback.mediumImpact();
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['pdf', 'doc', 'docx'],
        withData: false,
      );
      final file = result?.files.single;
      if (file == null || !mounted) return;
      setState(() => _cvFileName = file.name);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          backgroundColor: _ink.withValues(alpha: .92),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          content: Text(
            'CV updated · ${file.name}',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
          duration: const Duration(milliseconds: 2200),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text('Could not open the CV picker'),
        ),
      );
    }
  }

  void _cycleTitle() {
    HapticFeedback.selectionClick();
    setState(() => _titleIndex = (_titleIndex + 1) % _titles.length);
  }

  void _openProfileMenu() {
    HapticFeedback.selectionClick();
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: _ink.withValues(alpha: .28),
      builder: (ctx) => _ProfileMenuSheet(
        cvFileName: _cvFileName,
        onEditInfo: () {
          Navigator.of(ctx).pop();
          _openEditProfile();
        },
        onChangeCover: () {
          Navigator.of(ctx).pop();
          _changeCover();
        },
        onChangePhoto: () {
          Navigator.of(ctx).pop();
          _changePhoto();
        },
        onManageCv: () {
          Navigator.of(ctx).pop();
          _manageCv();
        },
      ),
    );
  }

  Future<void> _openEditProfile() async {
    HapticFeedback.mediumImpact();
    final updated = await Navigator.of(context).push<_LearnerInfo>(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 380),
        reverseTransitionDuration: const Duration(milliseconds: 280),
        pageBuilder: (_, animation, __) => FadeTransition(
          opacity: CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          ),
          child: _EditProfilePage(info: _info),
        ),
      ),
    );
    if (updated != null && mounted) {
      setState(() => _info = updated);
    }
  }

  @override
  Widget build(BuildContext context) {
    final padding = widget.contentPadding;
    final title = _titles[_titleIndex];
    final overlap = _avatarSize * .55;
    final displayName =
        _info.displayName.isEmpty ? widget.name : _info.displayName;

    return ListView(
      padding: EdgeInsets.only(bottom: padding.bottom + 6),
      children: [
        _stagger(
          index: 0,
          child: _CoverHeader(
            coverHeight: _coverHeight,
            avatarSize: _avatarSize,
            topInset: padding.top,
            overlap: overlap,
            coverBytes: _coverBytes,
            avatarBytes: _avatarBytes,
            name: displayName,
            accent: title.colors,
            wave: _wave,
            onChangeCover: widget.onBack == null ? _changeCover : null,
            onChangeAvatar: widget.onBack == null ? _changePhoto : null,
            onMenu: widget.onBack == null ? _openProfileMenu : null,
            onBack: widget.onBack,
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          child: Column(
            children: [
              _stagger(
                index: 1,
                child: Column(
                  children: [
                    Text(
                      displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: _ink,
                        letterSpacing: -.4,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _TitleBadgeChip(
                      badge: title,
                      wave: _wave,
                      onTap: _cycleTitle,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${_info.school} · ${_info.educationLevel} · ${_info.major}',
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: _ink.withValues(alpha: .48),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _info.bio,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13.5,
                        height: 1.45,
                        color: _ink.withValues(alpha: .72),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              _stagger(
                index: 2,
                child: _StatsRow(
                  collaborators: _collaborators,
                  collaborating: _collaborating,
                  innovations: _innovationCount,
                  onCollaborators: () => _openPeopleSheet(
                    context,
                    title: 'Collaborators',
                    subtitle: 'People following you',
                    people: _collaboratorsList,
                  ),
                  onCollaborating: () => _openPeopleSheet(
                    context,
                    title: 'Collaborating',
                    subtitle: 'People you follow',
                    people: _collaboratingList,
                  ),
                ),
              ),
              const SizedBox(height: 22),
              _stagger(
                index: 3,
                child: const Center(
                  child: Text(
                    'Innovations',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: _ink,
                      letterSpacing: -.2,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _stagger(index: 4, child: _InnovationsFeed(wave: _wave)),
            ],
          ),
        ),
      ],
    );
  }
}

// ----------------------------------------------------------------- cover

class _CoverHeader extends StatelessWidget {
  const _CoverHeader({
    required this.coverHeight,
    required this.avatarSize,
    required this.topInset,
    required this.overlap,
    required this.coverBytes,
    required this.avatarBytes,
    required this.name,
    required this.accent,
    required this.wave,
    this.onChangeCover,
    this.onChangeAvatar,
    this.onMenu,
    this.onBack,
  });

  final double coverHeight;
  final double avatarSize;
  final double topInset;
  final double overlap;
  final Uint8List? coverBytes;
  final Uint8List? avatarBytes;
  final String name;
  final List<Color> accent;
  final AnimationController wave;
  final VoidCallback? onChangeCover;
  final VoidCallback? onChangeAvatar;
  final VoidCallback? onMenu;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final totalHeight = coverHeight + (avatarSize - overlap);

    return SizedBox(
      height: totalHeight,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: coverHeight,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (coverBytes != null)
                  Image.memory(coverBytes!, fit: BoxFit.cover)
                else
                  FastAssetImage(asset: _defaultCover, fit: BoxFit.cover),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0x33071323),
                        Color(0x00071323),
                        Color(0x66071323),
                      ],
                      stops: [0, .45, 1],
                    ),
                  ),
                ),
                Positioned(
                  top: topInset + 10,
                  left: 16,
                  child: _GlassIconButton(
                    icon: onBack != null
                        ? Icons.arrow_back_rounded
                        : Icons.more_horiz_rounded,
                    tooltip: onBack != null ? 'Back' : 'Profile options',
                    onTap: onBack ?? onMenu ?? () {},
                  ),
                ),
                if (onChangeCover != null)
                  Positioned(
                    top: topInset + 10,
                    right: 16,
                    child: _GlassIconButton(
                      icon: Icons.photo_camera_outlined,
                      tooltip: 'Change cover',
                      onTap: onChangeCover!,
                    ),
                  ),
              ],
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            top: coverHeight - overlap,
            child: Center(
              child: _AvatarBadge(
                size: avatarSize,
                name: name,
                bytes: avatarBytes,
                wave: wave,
                accent: accent,
                onCamera: onChangeAvatar,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GlassIconButton extends StatelessWidget {
  const _GlassIconButton({
    required this.icon,
    required this.onTap,
    this.tooltip,
  });

  final IconData icon;
  final VoidCallback onTap;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final button = LiquidPressable(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      rippleColor: Colors.white,
      intensity: 1.1,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: .22),
          border: Border.all(color: Colors.white.withValues(alpha: .65)),
        ),
        child: Icon(icon, size: 18, color: Colors.white),
      ),
    );
    if (tooltip == null) return button;
    return Tooltip(message: tooltip!, child: button);
  }
}

// ----------------------------------------------------------- profile menu

class _ProfileMenuSheet extends StatelessWidget {
  const _ProfileMenuSheet({
    required this.onEditInfo,
    required this.onChangeCover,
    required this.onChangePhoto,
    required this.onManageCv,
    this.cvFileName,
  });

  final VoidCallback onEditInfo;
  final VoidCallback onChangeCover;
  final VoidCallback onChangePhoto;
  final VoidCallback onManageCv;
  final String? cvFileName;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 18),
      child: FastGlass(
        borderRadius: BorderRadius.circular(28),
        opacity: .94,
        padding: const EdgeInsets.fromLTRB(10, 12, 10, 14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 42,
              height: 4.5,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                color: _ink.withValues(alpha: .18),
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Profile',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: _ink,
                letterSpacing: -.2,
              ),
            ),
            const SizedBox(height: 10),
            _MenuRow(
              icon: Icons.edit_outlined,
              title: 'Edit profile & personal information',
              subtitle: 'Student details, bio, school, and more',
              onTap: onEditInfo,
            ),
            _MenuRow(
              icon: Icons.photo_camera_outlined,
              title: 'Change cover photo',
              subtitle: 'Update your banner image',
              onTap: onChangeCover,
            ),
            _MenuRow(
              icon: Icons.account_circle_outlined,
              title: 'Change profile photo',
              subtitle: 'Update your avatar',
              onTap: onChangePhoto,
            ),
            _MenuRow(
              icon: Icons.description_outlined,
              title: 'My CV',
              subtitle: cvFileName == null
                  ? 'Upload or update your CV (PDF, DOC)'
                  : 'Current · $cvFileName',
              onTap: onManageCv,
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuRow extends StatelessWidget {
  const _MenuRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FastTap(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: BrandColors.accent.withValues(alpha: .16),
              ),
              child: Icon(icon, size: 20, color: BrandColors.accent),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: _ink,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11.5,
                      color: _ink.withValues(alpha: .48),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: _ink.withValues(alpha: .3),
            ),
          ],
        ),
      ),
    );
  }
}

// -------------------------------------------------------- edit profile

class _EditProfilePage extends StatefulWidget {
  const _EditProfilePage({required this.info});

  final _LearnerInfo info;

  @override
  State<_EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<_EditProfilePage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _wave = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2800),
  )..repeat();

  late final _displayName = TextEditingController(text: widget.info.displayName);
  late final _fullName = TextEditingController(text: widget.info.fullName);
  late final _bio = TextEditingController(text: widget.info.bio);
  late final _email = TextEditingController(text: widget.info.email);
  late final _phone = TextEditingController(text: widget.info.phone);
  late final _dob = TextEditingController(text: widget.info.dateOfBirth);
  late final _gender = TextEditingController(text: widget.info.gender);
  late final _city = TextEditingController(text: widget.info.city);
  late final _country = TextEditingController(text: widget.info.country);
  late final _permanentAddress =
      TextEditingController(text: widget.info.permanentAddress);
  late final _temporaryAddress =
      TextEditingController(text: widget.info.temporaryAddress);
  late final _zipCode = TextEditingController(text: widget.info.zipCode);
  late final _school = TextEditingController(text: widget.info.school);
  late final _faculty = TextEditingController(text: widget.info.faculty);
  late final _degree = TextEditingController(text: widget.info.degree);
  late final _major = TextEditingController(text: widget.info.major);
  late final _yearLevel = TextEditingController(text: widget.info.yearLevel);
  late final _studentId = TextEditingController(text: widget.info.studentId);
  late final _enrollmentYear =
      TextEditingController(text: widget.info.enrollmentYear);
  late final _skills = TextEditingController(text: widget.info.skills);
  late final _hobby = TextEditingController(text: widget.info.hobby);
  late final _goals = TextEditingController(text: widget.info.learningGoals);
  late final _language = TextEditingController(text: widget.info.language);
  late final _portfolio = TextEditingController(text: widget.info.portfolio);
  late final _facebook = TextEditingController(text: widget.info.facebook);
  late final _linkedin = TextEditingController(text: widget.info.linkedin);
  late final _instagram = TextEditingController(text: widget.info.instagram);
  late final _github = TextEditingController(text: widget.info.github);
  late String _educationLevel = widget.info.educationLevel;

  @override
  void dispose() {
    _wave.dispose();
    for (final c in [
      _displayName,
      _fullName,
      _bio,
      _email,
      _phone,
      _dob,
      _gender,
      _city,
      _country,
      _permanentAddress,
      _temporaryAddress,
      _zipCode,
      _school,
      _faculty,
      _degree,
      _major,
      _yearLevel,
      _studentId,
      _enrollmentYear,
      _skills,
      _hobby,
      _goals,
      _language,
      _portfolio,
      _facebook,
      _linkedin,
      _instagram,
      _github,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  void _save() {
    HapticFeedback.mediumImpact();
    Navigator.of(context).pop(
      _LearnerInfo(
        displayName: _displayName.text.trim(),
        fullName: _fullName.text.trim(),
        bio: _bio.text.trim(),
        email: _email.text.trim(),
        phone: _phone.text.trim(),
        dateOfBirth: _dob.text.trim(),
        gender: _gender.text.trim(),
        city: _city.text.trim(),
        country: _country.text.trim(),
        permanentAddress: _permanentAddress.text.trim(),
        temporaryAddress: _temporaryAddress.text.trim(),
        zipCode: _zipCode.text.trim(),
        school: _school.text.trim(),
        faculty: _faculty.text.trim(),
        educationLevel: _educationLevel,
        degree: _degree.text.trim(),
        major: _major.text.trim(),
        yearLevel: _yearLevel.text.trim(),
        studentId: _studentId.text.trim(),
        enrollmentYear: _enrollmentYear.text.trim(),
        skills: _skills.text.trim(),
        hobby: _hobby.text.trim(),
        learningGoals: _goals.text.trim(),
        language: _language.text.trim(),
        portfolio: _portfolio.text.trim(),
        facebook: _facebook.text.trim(),
        linkedin: _linkedin.text.trim(),
        instagram: _instagram.text.trim(),
        github: _github.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: BrandColors.canvas,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const AnimatedBlobBackground(),
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 4, 16, 8),
                  child: Row(
                    children: [
                      FastTap(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          Navigator.of(context).pop();
                        },
                        borderRadius: BorderRadius.circular(999),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: .7),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: .95),
                            ),
                          ),
                          child: Icon(
                            Icons.close_rounded,
                            size: 20,
                            color: _ink.withValues(alpha: .85),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'Edit information',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: _ink,
                            letterSpacing: -.3,
                          ),
                        ),
                      ),
                      FastTap(
                        onTap: _save,
                        borderRadius: BorderRadius.circular(999),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 9,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(999),
                            color: BrandColors.secondarySurface,
                          ),
                          child: const Text(
                            'Save',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.fromLTRB(20, 4, 20, 28 + bottom),
                    children: [
                      const _FormSectionTitle('Profile'),
                      _FormField(
                        label: 'Display name',
                        controller: _displayName,
                        hint: 'How you appear on Innovator',
                        wave: _wave,
                      ),
                      _FormField(
                        label: 'Full name',
                        controller: _fullName,
                        hint: 'Legal / official name',
                        wave: _wave,
                      ),
                      _FormField(
                        label: 'Bio',
                        controller: _bio,
                        hint: 'A short intro about you',
                        maxLines: 4,
                        wave: _wave,
                      ),
                      const SizedBox(height: 18),
                      const _FormSectionTitle('Personal'),
                      _FormField(
                        label: 'Email',
                        controller: _email,
                        hint: 'student@school.edu',
                        keyboard: TextInputType.emailAddress,
                        wave: _wave,
                      ),
                      _FormField(
                        label: 'Phone',
                        controller: _phone,
                        hint: '+977 …',
                        keyboard: TextInputType.phone,
                        wave: _wave,
                      ),
                      _FormField(
                        label: 'Date of birth',
                        controller: _dob,
                        hint: 'DD Mon YYYY',
                        wave: _wave,
                      ),
                      _FormField(
                        label: 'Gender',
                        controller: _gender,
                        hint: 'Optional',
                        wave: _wave,
                      ),
                      _FormField(
                        label: 'City',
                        controller: _city,
                        hint: 'Where you study / live',
                        wave: _wave,
                      ),
                      _FormField(
                        label: 'Country',
                        controller: _country,
                        hint: 'Country',
                        wave: _wave,
                      ),
                      _FormField(
                        label: 'Permanent address',
                        controller: _permanentAddress,
                        hint: 'Full permanent address',
                        maxLines: 2,
                        wave: _wave,
                      ),
                      _FormField(
                        label: 'Temporary address',
                        controller: _temporaryAddress,
                        hint: 'Current / temporary address',
                        maxLines: 2,
                        wave: _wave,
                      ),
                      _FormField(
                        label: 'Zip code',
                        controller: _zipCode,
                        hint: 'Postal / ZIP code',
                        keyboard: TextInputType.number,
                        wave: _wave,
                      ),
                      const SizedBox(height: 18),
                      const _FormSectionTitle('Student / learner'),
                      _EducationLevelPicker(
                        value: _educationLevel,
                        wave: _wave,
                        onChanged: (level) =>
                            setState(() => _educationLevel = level),
                      ),
                      const SizedBox(height: 12),
                      _FormField(
                        label: 'School / University',
                        controller: _school,
                        hint: 'Institution name',
                        wave: _wave,
                      ),
                      _FormField(
                        label: 'Faculty / Department',
                        controller: _faculty,
                        hint: 'e.g. School of Technology',
                        wave: _wave,
                      ),
                      _FormField(
                        label: 'Degree / Program',
                        controller: _degree,
                        hint: 'Bachelor, Master, Diploma…',
                        wave: _wave,
                      ),
                      _FormField(
                        label: 'Major / Field of study',
                        controller: _major,
                        hint: 'e.g. Computer Science',
                        wave: _wave,
                      ),
                      _FormField(
                        label: 'Year level',
                        controller: _yearLevel,
                        hint: '1st Year, 2nd Year, Graduate…',
                        wave: _wave,
                      ),
                      _FormField(
                        label: 'Student ID',
                        controller: _studentId,
                        hint: 'Campus ID number',
                        wave: _wave,
                      ),
                      _FormField(
                        label: 'Enrollment year',
                        controller: _enrollmentYear,
                        hint: 'YYYY',
                        keyboard: TextInputType.number,
                        wave: _wave,
                      ),
                      const SizedBox(height: 18),
                      const _FormSectionTitle('Learning'),
                      _FormField(
                        label: 'Skills & interests',
                        controller: _skills,
                        hint: 'Comma-separated skills',
                        maxLines: 2,
                        wave: _wave,
                      ),
                      _FormField(
                        label: 'Hobby',
                        controller: _hobby,
                        hint: 'What you enjoy outside class',
                        maxLines: 2,
                        wave: _wave,
                      ),
                      _FormField(
                        label: 'Learning goals',
                        controller: _goals,
                        hint: 'What you want to achieve',
                        maxLines: 3,
                        wave: _wave,
                      ),
                      _FormField(
                        label: 'Languages',
                        controller: _language,
                        hint: 'Languages you speak',
                        wave: _wave,
                      ),
                      _FormField(
                        label: 'Portfolio',
                        controller: _portfolio,
                        hint: 'https://…',
                        keyboard: TextInputType.url,
                        wave: _wave,
                      ),
                      const SizedBox(height: 18),
                      const _FormSectionTitle('Social links'),
                      _FormField(
                        label: 'Facebook profile link',
                        controller: _facebook,
                        hint: 'https://facebook.com/…',
                        keyboard: TextInputType.url,
                        wave: _wave,
                      ),
                      _FormField(
                        label: 'LinkedIn profile link',
                        controller: _linkedin,
                        hint: 'https://linkedin.com/in/…',
                        keyboard: TextInputType.url,
                        wave: _wave,
                      ),
                      _FormField(
                        label: 'Instagram profile link',
                        controller: _instagram,
                        hint: 'https://instagram.com/…',
                        keyboard: TextInputType.url,
                        wave: _wave,
                      ),
                      _FormField(
                        label: 'GitHub profile link',
                        controller: _github,
                        hint: 'https://github.com/…',
                        keyboard: TextInputType.url,
                        wave: _wave,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FormSectionTitle extends StatelessWidget {
  const _FormSectionTitle(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, top: 4),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w800,
          color: _ink,
          letterSpacing: -.2,
        ),
      ),
    );
  }
}

/// Liquid chip row for picking education level.
class _EducationLevelPicker extends StatelessWidget {
  const _EducationLevelPicker({
    required this.value,
    required this.wave,
    required this.onChanged,
  });

  static const options = [
    'School level',
    '+2 level',
    'Bachelor level',
    'Master level',
    'PhD',
    'ECA courses',
  ];

  final String value;
  final AnimationController wave;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: 8),
          child: Text(
            'Education level',
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              letterSpacing: .2,
              color: _ink.withValues(alpha: .48),
            ),
          ),
        ),
        AnimatedBuilder(
          animation: wave,
          builder: (context, _) {
            return Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final option in options)
                  _EducationChip(
                    label: option,
                    selected: value == option,
                    wave: wave,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      onChanged(option);
                    },
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _EducationChip extends StatelessWidget {
  const _EducationChip({
    required this.label,
    required this.selected,
    required this.wave,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final AnimationController wave;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(999);

    return LiquidPressable(
      onTap: onTap,
      borderRadius: radius,
      rippleColor: selected ? Colors.white : _ink,
      intensity: .9,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          borderRadius: radius,
          border: Border.all(
            color: selected
                ? BrandColors.accent.withValues(alpha: .45)
                : Colors.white.withValues(alpha: .75),
            width: selected ? 1.3 : 1.05,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: BrandColors.secondarySurface.withValues(alpha: .2),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: ClipRRect(
          borderRadius: radius,
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
            child: Stack(
              children: [
                Positioned.fill(
                  child: ColoredBox(
                    color: Colors.white.withValues(alpha: selected ? .2 : .16),
                  ),
                ),
                if (selected)
                  Positioned.fill(
                    child: CustomPaint(
                      painter: WaveFillPainter(
                        phase: wave.value * 2 * pi,
                        fill: 1.15,
                        color: BrandColors.secondarySurface.withValues(
                          alpha: .92,
                        ),
                        amplitude: 2.4,
                        frequency: 1.4,
                      ),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -.1,
                      color: selected
                          ? Colors.white
                          : _ink.withValues(alpha: .72),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FormField extends StatefulWidget {
  const _FormField({
    required this.label,
    required this.controller,
    required this.hint,
    required this.wave,
    this.maxLines = 1,
    this.keyboard = TextInputType.text,
  });

  final String label;
  final TextEditingController controller;
  final String hint;
  final AnimationController wave;
  final int maxLines;
  final TextInputType keyboard;

  @override
  State<_FormField> createState() => _FormFieldState();
}

class _FormFieldState extends State<_FormField> {
  final _focus = FocusNode();
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _focus.addListener(() {
      final next = _focus.hasFocus;
      if (next != _focused) setState(() => _focused = next);
    });
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(20);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AnimatedBuilder(
        animation: widget.wave,
        builder: (context, _) {
          final fill = _focused ? .42 : .18;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOutCubic,
            decoration: BoxDecoration(
              borderRadius: radius,
              border: Border.all(
                color: _focused
                    ? BrandColors.accent.withValues(alpha: .55)
                    : Colors.white.withValues(alpha: .72),
                width: _focused ? 1.4 : 1.1,
              ),
              boxShadow: [
                if (_focused)
                  BoxShadow(
                    color: BrandColors.accent.withValues(alpha: .16),
                    blurRadius: 22,
                    offset: const Offset(0, 8),
                  )
                else
                  BoxShadow(
                    color: _ink.withValues(alpha: .05),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
              ],
            ),
            child: ClipRRect(
              borderRadius: radius,
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.white.withValues(
                                alpha: _focused ? .38 : .22,
                              ),
                              Colors.white.withValues(
                                alpha: _focused ? .16 : .08,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Positioned.fill(
                      child: CustomPaint(
                        painter: WaveFillPainter(
                          phase: widget.wave.value * 2 * pi +
                              widget.label.hashCode * .01,
                          fill: fill,
                          color: _ink.withValues(
                            alpha: _focused ? .10 : .05,
                          ),
                          amplitude: _focused ? 3.6 : 2.2,
                          frequency: 1.45,
                        ),
                      ),
                    ),
                    if (_focused)
                      Positioned.fill(
                        child: CustomPaint(
                          painter: WaveFillPainter(
                            phase: widget.wave.value * 2 * pi + 1.4,
                            fill: .28,
                            color: BrandColors.accent.withValues(alpha: .10),
                            amplitude: 2.8,
                            frequency: 1.2,
                          ),
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.label,
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              letterSpacing: .2,
                              color: _focused
                                  ? BrandColors.accent.withValues(alpha: .85)
                                  : _ink.withValues(alpha: .48),
                            ),
                          ),
                          const SizedBox(height: 4),
                          TextField(
                            controller: widget.controller,
                            focusNode: _focus,
                            maxLines: widget.maxLines,
                            keyboardType: widget.keyboard,
                            style: const TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w600,
                              color: _ink,
                            ),
                            cursorColor: BrandColors.accent,
                            decoration: InputDecoration(
                              isDense: true,
                              border: InputBorder.none,
                              hintText: widget.hint,
                              hintStyle: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: _ink.withValues(alpha: .32),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ----------------------------------------------------------------- avatar

class _AvatarBadge extends StatelessWidget {
  const _AvatarBadge({
    required this.size,
    required this.name,
    required this.bytes,
    required this.wave,
    required this.accent,
    this.onCamera,
  });

  final double size;
  final String name;
  final Uint8List? bytes;
  final AnimationController wave;
  final List<Color> accent;
  final VoidCallback? onCamera;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3.5),
              boxShadow: [
                BoxShadow(
                  color: _ink.withValues(alpha: .18),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: ClipOval(
              child: SizedBox(
                width: size,
                height: size,
                child: bytes != null
                    ? Image.memory(bytes!, fit: BoxFit.cover)
                    : Stack(
                        fit: StackFit.expand,
                        children: [
                          DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  accent.first.withValues(alpha: .9),
                                  accent.last,
                                ],
                              ),
                            ),
                          ),
                          AnimatedBuilder(
                            animation: wave,
                            builder: (context, _) => CustomPaint(
                              painter: WaveFillPainter(
                                phase: wave.value * 2 * pi,
                                fill: .3,
                                color: Colors.white.withValues(alpha: .12),
                                amplitude: 4,
                                frequency: 1.3,
                              ),
                            ),
                          ),
                          Center(
                            child: Text(
                              name.isEmpty ? '?' : name[0].toUpperCase(),
                              style: TextStyle(
                                fontSize: size * .38,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
          if (onCamera != null)
            Positioned(
              right: -2,
              bottom: -2,
              child: LiquidPressable(
                onTap: onCamera!,
                borderRadius: BorderRadius.circular(16),
                rippleColor: Colors.white,
                intensity: 1.2,
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: BrandColors.secondarySurface,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: const Icon(
                    Icons.camera_alt_rounded,
                    size: 14,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ----------------------------------------------------------------- badge

class _TitleBadgeChip extends StatelessWidget {
  const _TitleBadgeChip({
    required this.badge,
    required this.wave,
    required this.onTap,
  });

  final _TitleBadge badge;
  final AnimationController wave;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return LiquidPressable(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      rippleColor: Colors.white,
      intensity: 1.1,
      child: AnimatedBuilder(
        animation: wave,
        builder: (context, _) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: badge.colors,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: CustomPaint(
                      painter: WaveFillPainter(
                        phase: wave.value * 2 * pi,
                        fill: .28,
                        color: Colors.white.withValues(alpha: .12),
                        amplitude: 2.5,
                        frequency: 1.4,
                      ),
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(badge.icon, size: 14, color: Colors.white),
                      const SizedBox(width: 6),
                      Text(
                        badge.label,
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: .2,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.verified_rounded,
                        size: 13,
                        color: Colors.white.withValues(alpha: .9),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ------------------------------------------------------------------ stats

/// Open premium metrics — no card, no border. Editorial numbers with soft
/// hairline separators and a gold accent mark under each value.
class _StatsRow extends StatelessWidget {
  const _StatsRow({
    required this.collaborators,
    required this.collaborating,
    required this.innovations,
    required this.onCollaborators,
    required this.onCollaborating,
  });

  final int collaborators;
  final int collaborating;
  final int innovations;
  final VoidCallback onCollaborators;
  final VoidCallback onCollaborating;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      child: Row(
        children: [
          Expanded(
            child: _StatCell(
              value: collaborators,
              label: 'Collaborators',
              onTap: onCollaborators,
            ),
          ),
          _StatDivider(),
          Expanded(
            child: _StatCell(
              value: collaborating,
              label: 'Collaborating',
              onTap: onCollaborating,
            ),
          ),
          _StatDivider(),
          Expanded(
            child: _StatCell(
              value: innovations,
              label: 'Innovation',
            ),
          ),
        ],
      ),
    );
  }
}

class _StatDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 28,
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            _ink.withValues(alpha: 0),
            _ink.withValues(alpha: .14),
            _ink.withValues(alpha: 0),
          ],
        ),
      ),
    );
  }
}

class _StatCell extends StatelessWidget {
  const _StatCell({
    required this.value,
    required this.label,
    this.onTap,
  });

  final int value;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return FastTap(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap?.call();
      },
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        child: Column(
          children: [
            Text(
              '$value',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: _ink,
                letterSpacing: -.6,
                height: 1,
              ),
            ),
            const SizedBox(height: 6),
            Container(
              width: 18,
              height: 2.5,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(2),
                color: BrandColors.accent,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: .2,
                color: _ink.withValues(alpha: .48),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ----------------------------------------------------------- people sheet

class _PeopleSheet extends StatelessWidget {
  const _PeopleSheet({
    required this.title,
    required this.subtitle,
    required this.people,
  });

  final String title;
  final String subtitle;
  final List<_Person> people;

  @override
  Widget build(BuildContext context) {
    final maxH = MediaQuery.sizeOf(context).height * .78;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxH),
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            child: FastGlass(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(32),
              ),
              opacity: .94,
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 12),
                    Container(
                      width: 42,
                      height: 4.5,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        color: _ink.withValues(alpha: .18),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(22, 16, 22, 6),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  title,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                    color: _ink,
                                    letterSpacing: -.3,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  '$subtitle · ${people.length} shown',
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    color: _ink.withValues(alpha: .48),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          FastTap(
                            onTap: () => Navigator.of(context).pop(),
                            borderRadius: BorderRadius.circular(999),
                            child: Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withValues(alpha: .55),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: .95),
                                ),
                              ),
                              child: Icon(
                                Icons.close_rounded,
                                size: 18,
                                color: _ink.withValues(alpha: .75),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Flexible(
                      child: ListView.separated(
                        shrinkWrap: true,
                        padding: const EdgeInsets.fromLTRB(14, 8, 14, 18),
                        itemCount: people.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          return _PersonTile(person: people[index]);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PersonTile extends StatelessWidget {
  const _PersonTile({required this.person});

  final _Person person;

  @override
  Widget build(BuildContext context) {
    final letter = person.name.isEmpty ? '?' : person.name[0].toUpperCase();

    return FastTap(
      onTap: () => HapticFeedback.selectionClick(),
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: person.colors,
                ),
              ),
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: person.colors,
                  ),
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
                child: Center(
                  child: Text(
                    letter,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    person.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color: _ink,
                      letterSpacing: -.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    person.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: _ink.withValues(alpha: .48),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: _ink.withValues(alpha: .28),
            ),
          ],
        ),
      ),
    );
  }
}

// ------------------------------------------------------------ innovations

class _InnovationsFeed extends StatelessWidget {
  const _InnovationsFeed({required this.wave});

  final AnimationController wave;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < _innovations.length; i++) ...[
          if (i > 0) const SizedBox(height: 14),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: Duration(milliseconds: 380 + i * 60),
            curve: Curves.easeOutCubic,
            builder: (context, t, child) => Transform.translate(
              offset: Offset(0, 14 * (1 - t.clamp(0, 1))),
              child: Opacity(opacity: t.clamp(0, 1), child: child),
            ),
            child: _InnovationFeedCard(
              item: _innovations[i],
              wave: wave,
              index: i,
            ),
          ),
        ],
      ],
    );
  }
}

/// Mirrors the news-feed liquid glass card: frosted surface, feed header,
/// body copy, and a media block with a living wave fill.
class _InnovationFeedCard extends StatefulWidget {
  const _InnovationFeedCard({
    required this.item,
    required this.wave,
    required this.index,
  });

  final _Innovation item;
  final AnimationController wave;
  final int index;

  @override
  State<_InnovationFeedCard> createState() => _InnovationFeedCardState();
}

class _InnovationFeedCardState extends State<_InnovationFeedCard> {
  bool _liked = false;

  _Innovation get item => widget.item;

  @override
  Widget build(BuildContext context) {
    return FastGlass(
      borderRadius: BorderRadius.circular(26),
      opacity: .28,
      borderWidth: 1.1,
      padding: const EdgeInsets.fromLTRB(16, 15, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _InnovationAvatar(item: item),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _ink,
                        letterSpacing: -.2,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      'Innovation · ${item.date}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11.5,
                        color: _ink.withValues(alpha: .45),
                      ),
                    ),
                  ],
                ),
              ),
              FastTap(
                onTap: () {},
                borderRadius: BorderRadius.circular(999),
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: Icon(
                    Icons.more_horiz_rounded,
                    size: 20,
                    color: _ink.withValues(alpha: .4),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            item.subtitle,
            style: TextStyle(
              fontSize: 13.5,
              height: 1.5,
              color: _ink.withValues(alpha: .82),
            ),
          ),
          const SizedBox(height: 12),
          _InnovationMedia(
            item: item,
            wave: widget.wave,
            index: widget.index,
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _InnovationAction(
                icon: _liked
                    ? Icons.favorite_rounded
                    : Icons.favorite_border_rounded,
                label: _liked ? '25' : '24',
                active: _liked,
                activeColor: const Color(0xFFE0245E),
                onTap: () {
                  HapticFeedback.lightImpact();
                  setState(() => _liked = !_liked);
                },
              ),
              _InnovationAction(
                icon: Icons.chat_bubble_outline_rounded,
                label: '6',
                onTap: () => HapticFeedback.selectionClick(),
              ),
              _InnovationAction(
                icon: Icons.repeat_rounded,
                label: '3',
                onTap: () => HapticFeedback.selectionClick(),
              ),
              _InnovationAction(
                icon: Icons.ios_share_rounded,
                label: 'Share',
                onTap: () => HapticFeedback.selectionClick(),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InnovationAvatar extends StatelessWidget {
  const _InnovationAvatar({required this.item});

  final _Innovation item;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: item.colors,
        ),
      ),
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: item.colors,
          ),
          border: Border.all(color: Colors.white, width: 1.5),
        ),
        child: Icon(item.icon, size: 20, color: Colors.white),
      ),
    );
  }
}

class _InnovationMedia extends StatelessWidget {
  const _InnovationMedia({
    required this.item,
    required this.wave,
    required this.index,
  });

  final _Innovation item;
  final AnimationController wave;
  final int index;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 188,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: .4)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          FastAssetImage(
            asset: item.coverAsset,
            fit: BoxFit.cover,
            width: MediaQuery.sizeOf(context).width,
            height: 188,
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: .18),
                  Colors.transparent,
                  Colors.black.withValues(alpha: .45),
                ],
                stops: const [0, .45, 1],
              ),
            ),
          ),
          // Living liquid pool — same language as the rest of the app.
          AnimatedBuilder(
            animation: wave,
            builder: (context, _) => Stack(
              fit: StackFit.expand,
              children: [
                CustomPaint(
                  painter: WaveFillPainter(
                    phase: wave.value * 2 * pi + index,
                    fill: .28,
                    color: Colors.white.withValues(alpha: .22),
                    amplitude: 5,
                    frequency: 1.35,
                  ),
                ),
                CustomPaint(
                  painter: WaveFillPainter(
                    phase: wave.value * 2 * pi + index + 1.2,
                    fill: .16,
                    color: Colors.white.withValues(alpha: .14),
                    amplitude: 3.5,
                    frequency: 1.8,
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            left: 12,
            top: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                color: Colors.black.withValues(alpha: .4),
                border: Border.all(color: Colors.white.withValues(alpha: .3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.image_outlined,
                    size: 12,
                    color: Colors.white.withValues(alpha: .9),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Photo',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withValues(alpha: .9),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            left: 14,
            bottom: 12,
            right: 14,
            child: Text(
              item.date,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.white.withValues(alpha: .92),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InnovationAction extends StatelessWidget {
  const _InnovationAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.active = false,
    this.activeColor = _ink,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool active;
  final Color activeColor;

  @override
  Widget build(BuildContext context) {
    final color = active ? activeColor : _ink.withValues(alpha: .55);

    return FastTap(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedScale(
              scale: active ? 1.18 : 1,
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOutBack,
              child: Icon(icon, size: 18, color: color),
            ),
            const SizedBox(width: 6),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: color,
              ),
              child: Text(label),
            ),
          ],
        ),
      ),
    );
  }
}
