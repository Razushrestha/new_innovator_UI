import 'dart:async';
import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'theme/brand_colors.dart';
import 'package:flutter/services.dart';

import 'widgets/liquid_pressable.dart';
import 'widgets/wave_fill_painter.dart';

const _ink = BrandColors.ink;
const _muted = BrandColors.muted;
const _online = Color(0xFF17A275);

class _Conversation {
  _Conversation({
    required this.name,
    required this.role,
    required this.preview,
    required this.time,
    required this.colors,
    this.unread = 0,
    this.isOnline = false,
  });

  final String name;
  final String role;
  final String preview;
  final String time;
  final List<Color> colors;
  int unread;
  final bool isOnline;
}

enum _AutoDelete { never, hours24 }

class _Msg {
  _Msg(this.text, {required this.mine, required this.time, String? id})
    : id = id ?? UniqueKey().toString();

  final String id;
  final String text;
  final bool mine;
  final String time;
  _AutoDelete autoDelete = _AutoDelete.never;
}

/// Chat as an in-shell section. The conversation list and the open
/// thread melt into each other; bubbles carry liquid inside them, the
/// send orb is a droplet full of ink, and every touch springs.
class ChatSection extends StatefulWidget {
  const ChatSection({super.key, this.contentPadding = EdgeInsets.zero});

  /// Clearances from the shell so content stays clear of the docked bar.
  final EdgeInsets contentPadding;

  @override
  State<ChatSection> createState() => _ChatSectionState();
}

class _ChatSectionState extends State<ChatSection>
    with TickerProviderStateMixin {
  final _composer = TextEditingController();
  final _composerFocus = FocusNode();
  final _listSearch = TextEditingController();
  final _listSearchFocus = FocusNode();
  String _listQuery = '';

  late final List<_Conversation> _conversations = [
    _Conversation(
      name: 'Maya Chen',
      role: 'Innovation Lead',
      preview: 'Ship it to the team build today?',
      time: '2m',
      unread: 2,
      isOnline: true,
      colors: const [Color(0xFF4C1D95), Color(0xFF7C3AED)],
    ),
    _Conversation(
      name: 'Aarav Sharma',
      role: 'Product Designer',
      preview: 'The spring physics feel unreal.',
      time: '28m',
      unread: 1,
      isOnline: true,
      colors: const [Color(0xFF1E3A8A), Color(0xFF2563EB)],
    ),
    _Conversation(
      name: 'Innovator Team',
      role: 'Official',
      preview: 'Welcome to the community!',
      time: '1h',
      unread: 5,
      colors: const [Color(0xFF0F766E), Color(0xFF14B8A6)],
    ),
    _Conversation(
      name: 'Rohan Karki',
      role: 'Flutter Developer',
      preview: 'Pushed the fix, check the branch.',
      time: 'Tue',
      colors: const [Color(0xFF92400E), Color(0xFFB45309)],
    ),
    _Conversation(
      name: 'Priya Thapa',
      role: 'Growth Marketer',
      preview: 'Campaign numbers look great.',
      time: 'Mon',
      colors: const [Color(0xFF9F1239), Color(0xFFE11D48)],
    ),
  ];

  /// People who recently followed you — shown as a circle rail.
  static const _recentFollowers = [
    _RailPerson('Sita Rai', [Color(0xFFBE185D), Color(0xFFF472B6)]),
    _RailPerson('Nabin Gurung', [Color(0xFF0369A1), Color(0xFF38BDF8)]),
    _RailPerson('Anisha Lama', [Color(0xFFB45309), Color(0xFFFBBF24)]),
    _RailPerson('Kiran Basnet', [Color(0xFF047857), Color(0xFF34D399)]),
    _RailPerson('Diya Shrestha', [Color(0xFF6D28D9), Color(0xFFA78BFA)]),
  ];

  final Map<String, List<_Msg>> _messages = {
    'Maya Chen': [
      _Msg(
        'Hey! Did you try the new liquid nav bar?',
        mine: false,
        time: '10:02',
      ),
      _Msg(
        'Just tried it — the drag feels amazing.',
        mine: true,
        time: '10:04',
      ),
      _Msg('Ship it to the team build today?', mine: false, time: '10:05'),
    ],
    'Aarav Sharma': [
      _Msg('The spring physics feel unreal.', mine: false, time: '09:31'),
    ],
    'Innovator Team': [
      _Msg('Welcome to the community!', mine: false, time: '08:12'),
    ],
    'Rohan Karki': [
      _Msg('Pushed the fix, check the branch.', mine: false, time: 'Tue'),
    ],
    'Priya Thapa': [
      _Msg('Campaign numbers look great.', mine: false, time: 'Mon'),
    ],
  };

  static const _replies = [
    'Love that — let’s do it.',
    'On it, give me ten minutes.',
    'That liquid feel is exactly what we wanted.',
    'Perfect, shipping it now.',
  ];

  _Conversation? _open;
  bool _typing = false;
  int _replyIndex = 0;
  int _sendCount = 0;

  /// Pending auto-delete timers keyed by message id.
  final Map<String, Timer> _autoDeleteTimers = {};

  late final AnimationController _entrance = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..forward();

  /// Continuous phase shared by every liquid surface in the chat.
  late final AnimationController _wave = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  )..repeat();

  @override
  void dispose() {
    for (final timer in _autoDeleteTimers.values) {
      timer.cancel();
    }
    _composer.dispose();
    _composerFocus.dispose();
    _listSearch.dispose();
    _listSearchFocus.dispose();
    _entrance.dispose();
    _wave.dispose();
    super.dispose();
  }

  List<_Conversation> get _filteredConversations {
    final q = _listQuery.toLowerCase();
    if (q.isEmpty) return _conversations;
    return _conversations
        .where(
          (c) =>
              c.name.toLowerCase().contains(q) ||
              c.preview.toLowerCase().contains(q) ||
              c.role.toLowerCase().contains(q),
        )
        .toList();
  }

  List<_Conversation> get _recentChats =>
      _conversations.where((c) => c.isOnline || c.unread > 0).toList();

  void _cancelAutoDelete(String messageId) {
    _autoDeleteTimers.remove(messageId)?.cancel();
  }

  void _scheduleAutoDelete(_Msg message) {
    _cancelAutoDelete(message.id);
    // Demo timing: 24h would be too long to feel — use 24s as a stand-in
    // so the liquid delete is visible in the same session. Swap to
    // Duration(hours: 24) for production.
    _autoDeleteTimers[message.id] = Timer(const Duration(seconds: 24), () {
      if (!mounted) return;
      _removeMessage(message.id);
    });
  }

  void _removeMessage(String messageId) {
    _cancelAutoDelete(messageId);
    if (!mounted) return;
    setState(() {
      for (final list in _messages.values) {
        list.removeWhere((m) => m.id == messageId);
      }
    });
  }

  void _setAutoDelete(_Msg message, _AutoDelete mode) {
    setState(() => message.autoDelete = mode);
    if (mode == _AutoDelete.hours24) {
      _scheduleAutoDelete(message);
      _liquidToast('Auto delete in 24 hours');
    } else {
      _cancelAutoDelete(message.id);
      _liquidToast('Auto delete off');
    }
  }

  void _liquidToast(String label) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        elevation: 0,
        duration: const Duration(milliseconds: 1600),
        content: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              gradient: LinearGradient(
                colors: [
                  BrandColors.secondarySurface.withValues(alpha: .95),
                  BrandColors.secondarySurface.withValues(alpha: .92),
                ],
              ),
              border: Border.all(color: Colors.white.withValues(alpha: .28)),
              boxShadow: [
                BoxShadow(
                  color: _ink.withValues(alpha: .22),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 13.5,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openMessageMenu(_Msg message, BuildContext anchor) async {
    HapticFeedback.selectionClick();
    final box = anchor.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;
    final origin = box.localToGlobal(Offset.zero);
    final anchorRect = origin & box.size;

    final action = await Navigator.of(context).push<_MessageMenuAction>(
      _LiquidPopoverRoute(anchorRect: anchorRect, selected: message.autoDelete),
    );
    if (!mounted || action == null) return;
    switch (action) {
      case _MessageMenuAction.autoDelete24h:
        _setAutoDelete(message, _AutoDelete.hours24);
      case _MessageMenuAction.never:
        _setAutoDelete(message, _AutoDelete.never);
      case _MessageMenuAction.delete:
        HapticFeedback.mediumImpact();
        _removeMessage(message.id);
        _liquidToast('Message deleted');
    }
  }

  Widget _stagger({required int index, required Widget child}) {
    final start = (index * .09).clamp(0.0, .6);
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

  void _openConversation(_Conversation conversation) {
    HapticFeedback.selectionClick();
    setState(() {
      _open = conversation;
      conversation.unread = 0;
      _typing = false;
    });
  }

  void _closeConversation() {
    HapticFeedback.selectionClick();
    _composerFocus.unfocus();
    setState(() {
      _open = null;
      _typing = false;
    });
  }

  void _deliverMessage(_Conversation open, String text) {
    setState(() {
      _composer.clear();
      _sendCount++;
      _messages[open.name]!.add(_Msg(text, mine: true, time: 'now'));
    });
    HapticFeedback.mediumImpact();

    // Peer starts typing, then a reply wells up.
    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted || _open != open) return;
      setState(() => _typing = true);
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (!mounted || _open != open) return;
        setState(() {
          _typing = false;
          _messages[open.name]!.add(
            _Msg(
              _replies[_replyIndex % _replies.length],
              mine: false,
              time: 'now',
            ),
          );
          _replyIndex++;
        });
        HapticFeedback.selectionClick();
      });
    });
  }

  void _send() {
    final open = _open;
    final text = _composer.text.trim();
    if (open == null || text.isEmpty) {
      HapticFeedback.selectionClick();
      return;
    }
    _deliverMessage(open, text);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 420),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(.04, 0),
            end: Offset.zero,
          ).animate(animation),
          child: child,
        ),
      ),
      child: _open == null ? _buildList() : _buildThread(_open!),
    );
  }

  // ------------------------------------------------------------------ list

  Widget _buildList() {
    final padding = widget.contentPadding;
    final chats = _filteredConversations;
    return ListView(
      key: const ValueKey('conversations'),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: EdgeInsets.fromLTRB(20, padding.top + 8, 20, padding.bottom + 6),
      children: [
        _stagger(
          index: 0,
          child: _ChatListSearchBar(
            controller: _listSearch,
            focusNode: _listSearchFocus,
            wave: _wave,
            onChanged: (value) => setState(() => _listQuery = value.trim()),
            onClear: () {
              _listSearch.clear();
              _listSearchFocus.requestFocus();
              setState(() => _listQuery = '');
            },
          ),
        ),
        const SizedBox(height: 18),
        _stagger(
          index: 1,
          child: _AvatarRail(
            title: 'Recent',
            wave: _wave,
            people: [
              for (final c in _recentChats)
                _RailPerson(c.name, c.colors, isOnline: c.isOnline),
              ..._recentFollowers,
            ],
            onTapName: (name) {
              final match = _conversations.where((c) => c.name == name);
              if (match.isNotEmpty) {
                _openConversation(match.first);
              } else {
                HapticFeedback.selectionClick();
                _liquidToast('Say hi to $name');
              }
            },
          ),
        ),
        const SizedBox(height: 18),
        _stagger(
          index: 2,
          child: AnimatedBuilder(
            animation: _wave,
            builder: (context, child) => Transform.translate(
              offset: Offset(0, sin(_wave.value * 2 * pi + 1.4) * 2),
              child: child,
            ),
            child: const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Messages',
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: _ink,
                  letterSpacing: -.1,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        if (chats.isEmpty)
          _stagger(
            index: 3,
            child: Padding(
              padding: const EdgeInsets.only(top: 28),
              child: Center(
                child: Text(
                  'No chats for “$_listQuery”',
                  style: const TextStyle(fontSize: 13, color: _muted),
                ),
              ),
            ),
          )
        else
          for (var i = 0; i < chats.length; i++)
            _stagger(
              index: 3 + i,
              child: _ConversationTile(
                conversation: chats[i],
                wave: _wave,
                phaseShift: i * .9,
                onTap: () => _openConversation(chats[i]),
              ),
            ),
      ],
    );
  }

  // ---------------------------------------------------------------- thread

  Widget _buildThread(_Conversation conversation) {
    final padding = widget.contentPadding;
    final messages = _messages[conversation.name]!;
    return Padding(
      key: ValueKey('thread-${conversation.name}'),
      padding: EdgeInsets.fromLTRB(20, padding.top + 8, 20, padding.bottom + 6),
      child: Column(
        children: [
          _ThreadHeader(
            conversation: conversation,
            wave: _wave,
            onBack: _closeConversation,
            onMore: (anchor) {
              final list = _messages[conversation.name];
              if (list == null || list.isEmpty) {
                HapticFeedback.selectionClick();
                _liquidToast('No messages yet');
                return;
              }
              _openMessageMenu(list.last, anchor);
            },
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.builder(
              reverse: true,
              padding: const EdgeInsets.symmetric(vertical: 4),
              itemCount: messages.length + (_typing ? 1 : 0),
              itemBuilder: (context, index) {
                if (_typing && index == 0) {
                  return Align(
                    alignment: Alignment.centerLeft,
                    child: _TypingBubble(wave: _wave),
                  );
                }
                final messageIndex =
                    messages.length - 1 - (index - (_typing ? 1 : 0));
                final message = messages[messageIndex];
                return _Bubble(
                  key: ValueKey(message.id),
                  message: message,
                  wave: _wave,
                  onMore: (anchor) => _openMessageMenu(message, anchor),
                );
              },
            ),
          ),
          const SizedBox(height: 10),
          _buildComposer(),
        ],
      ),
    );
  }

  Widget _buildComposer() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(26),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
              child: AnimatedBuilder(
                animation: Listenable.merge([_wave, _composerFocus]),
                builder: (context, _) {
                  final focused = _composerFocus.hasFocus;
                  return Container(
                    constraints: const BoxConstraints(minHeight: 52),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(26),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white.withValues(alpha: focused ? .7 : .56),
                          Colors.white.withValues(alpha: focused ? .42 : .3),
                        ],
                      ),
                      border: Border.all(
                        color: Colors.white.withValues(
                          alpha: focused ? 1 : .85,
                        ),
                        width: 1.2,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(26),
                      child: Stack(
                        children: [
                          // Liquid pooled along the bottom of the pill,
                          // rising a little while you type.
                          Positioned.fill(
                            child: CustomPaint(
                              painter: WaveFillPainter(
                                phase: _wave.value * 2 * pi,
                                fill: focused ? .2 : .1,
                                color: _ink.withValues(alpha: .05),
                                amplitude: 3,
                                frequency: 1.6,
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 15,
                            ),
                            child: TextField(
                              controller: _composer,
                              focusNode: _composerFocus,
                              minLines: 1,
                              maxLines: 4,
                              textInputAction: TextInputAction.send,
                              onSubmitted: (_) => _send(),
                              style: const TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w500,
                                color: _ink,
                                height: 1.35,
                              ),
                              cursorColor: _ink,
                              decoration: const InputDecoration(
                                isCollapsed: true,
                                border: InputBorder.none,
                                hintText: 'Message…',
                                hintStyle: TextStyle(
                                  fontSize: 14,
                                  color: _muted,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        // Send orb — liquid press only, no flying drop.
        TweenAnimationBuilder<double>(
          key: ValueKey(_sendCount),
          tween: Tween(begin: _sendCount == 0 ? 1 : .92, end: 1),
          duration: const Duration(milliseconds: 420),
          curve: Curves.easeOutCubic,
          builder: (context, t, child) =>
              Transform.scale(scale: t, child: child),
          child: Tooltip(
            message: 'Send',
            child: LiquidPressable(
              onTap: _send,
              borderRadius: BorderRadius.circular(26),
              rippleColor: Colors.white,
              intensity: 1.15,
              child: AnimatedBuilder(
                animation: _wave,
                builder: (context, _) => Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: .5),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: .95),
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _ink.withValues(alpha: .18),
                        blurRadius: 14,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        CustomPaint(
                          painter: WaveFillPainter(
                            phase: _wave.value * 2 * pi + 1.2,
                            fill: .95,
                            color: _ink.withValues(alpha: .28),
                            amplitude: 4,
                            frequency: 1.3,
                          ),
                        ),
                        CustomPaint(
                          painter: WaveFillPainter(
                            phase: _wave.value * 2 * pi,
                            fill: .82,
                            color: const Color(
                              0xFF15181F,
                            ).withValues(alpha: .93),
                            amplitude: 3.4,
                            frequency: 1.5,
                          ),
                        ),
                        const Center(
                          child: Icon(
                            Icons.water_drop_rounded,
                            size: 22,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// -------------------------------------------------------------- list chrome

class _RailPerson {
  const _RailPerson(this.name, this.colors, {this.isOnline = false});

  final String name;
  final List<Color> colors;
  final bool isOnline;
}

/// Top search pill for the chat list — liquid pools inside while focused.
class _ChatListSearchBar extends StatelessWidget {
  const _ChatListSearchBar({
    required this.controller,
    required this.focusNode,
    required this.wave,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final AnimationController wave;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([wave, focusNode]),
      builder: (context, _) {
        final focused = focusNode.hasFocus;
        final hasText = controller.text.isNotEmpty;
        return ClipRRect(
          borderRadius: BorderRadius.circular(26),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              height: 52,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(26),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withValues(alpha: focused ? .68 : .48),
                    Colors.white.withValues(alpha: focused ? .38 : .22),
                  ],
                ),
                border: Border.all(
                  color: Colors.white.withValues(alpha: focused ? .95 : .55),
                  width: 1.1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: _ink.withValues(alpha: focused ? .1 : .04),
                    blurRadius: focused ? 18 : 10,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CustomPaint(
                    painter: WaveFillPainter(
                      phase: wave.value * 2 * pi,
                      fill: focused ? .18 : .08,
                      color: _ink.withValues(alpha: .045),
                      amplitude: 2.8,
                      frequency: 1.5,
                    ),
                  ),
                  Row(
                    children: [
                      const SizedBox(width: 16),
                      Icon(
                        Icons.search_rounded,
                        size: 22,
                        color: _ink.withValues(alpha: .55),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: controller,
                          focusNode: focusNode,
                          onChanged: onChanged,
                          style: const TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w500,
                            color: _ink,
                          ),
                          cursorColor: _ink,
                          decoration: const InputDecoration(
                            isCollapsed: true,
                            border: InputBorder.none,
                            hintText: 'Search chats & people…',
                            hintStyle: TextStyle(
                              fontSize: 14,
                              color: _muted,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                      AnimatedScale(
                        scale: hasText ? 1 : 0,
                        duration: const Duration(milliseconds: 280),
                        curve: Curves.easeOutBack,
                        child: Padding(
                          padding: const EdgeInsets.only(right: 10),
                          child: LiquidPressable(
                            onTap: onClear,
                            borderRadius: BorderRadius.circular(14),
                            rippleColor: Colors.white,
                            intensity: 1.1,
                            child: Container(
                              width: 26,
                              height: 26,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _ink.withValues(alpha: .88),
                              ),
                              child: const Icon(
                                Icons.close_rounded,
                                size: 14,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Horizontal rail of liquid profile circles with a floating title.
class _AvatarRail extends StatelessWidget {
  const _AvatarRail({
    required this.title,
    required this.wave,
    required this.people,
    required this.onTapName,
  });

  final String title;
  final AnimationController wave;
  final List<_RailPerson> people;
  final ValueChanged<String> onTapName;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedBuilder(
          animation: wave,
          builder: (context, child) => Transform.translate(
            offset: Offset(0, sin(wave.value * 2 * pi) * 2),
            child: child,
          ),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              color: _ink,
              letterSpacing: -.1,
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 92,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: people.length,
            separatorBuilder: (_, __) => const SizedBox(width: 14),
            itemBuilder: (context, index) {
              final person = people[index];
              return _PersonCircle(
                person: person,
                wave: wave,
                phaseShift: index * .7,
                onTap: () => onTapName(person.name),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _PersonCircle extends StatelessWidget {
  const _PersonCircle({
    required this.person,
    required this.wave,
    required this.phaseShift,
    required this.onTap,
  });

  final _RailPerson person;
  final AnimationController wave;
  final double phaseShift;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return LiquidPressable(
      onTap: onTap,
      borderRadius: BorderRadius.circular(40),
      rippleColor: Colors.white,
      intensity: 1.15,
      child: SizedBox(
        width: 68,
        child: Column(
          children: [
            AnimatedBuilder(
              animation: wave,
              builder: (context, child) => Transform.translate(
                offset: Offset(0, sin(wave.value * 2 * pi + phaseShift) * 2.4),
                child: child,
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: person.colors,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: person.colors.last.withValues(alpha: .28),
                          blurRadius: 12,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          AnimatedBuilder(
                            animation: wave,
                            builder: (context, _) => CustomPaint(
                              painter: WaveFillPainter(
                                phase: wave.value * 2 * pi + phaseShift,
                                fill: .28,
                                color: Colors.white.withValues(alpha: .14),
                                amplitude: 3,
                                frequency: 1.4,
                              ),
                            ),
                          ),
                          Center(
                            child: Text(
                              person.name[0],
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (person.isOnline)
                    Positioned(
                      right: 2,
                      bottom: 2,
                      child: AnimatedBuilder(
                        animation: wave,
                        builder: (context, _) => Transform.scale(
                          scale:
                              1 + .12 * sin(wave.value * 2 * pi + phaseShift),
                          child: Container(
                            width: 13,
                            height: 13,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _online,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Text(
              person.name.split(' ').first,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: _ink.withValues(alpha: .75),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// -------------------------------------------------------------- list tile

/// Borderless chat row — clean typography, liquid squash on every tap.
class _ConversationTile extends StatelessWidget {
  const _ConversationTile({
    required this.conversation,
    required this.wave,
    required this.phaseShift,
    required this.onTap,
  });

  final _Conversation conversation;
  final AnimationController wave;
  final double phaseShift;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return LiquidPressable(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      rippleColor: _ink,
      intensity: 1.05,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 11),
        child: Row(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: conversation.colors,
                    ),
                  ),
                  child: ClipOval(
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        AnimatedBuilder(
                          animation: wave,
                          builder: (context, _) => CustomPaint(
                            painter: WaveFillPainter(
                              phase: wave.value * 2 * pi + phaseShift,
                              fill: .22,
                              color: Colors.white.withValues(alpha: .12),
                              amplitude: 2.8,
                              frequency: 1.4,
                            ),
                          ),
                        ),
                        Center(
                          child: Text(
                            conversation.name[0],
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (conversation.isOnline)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: AnimatedBuilder(
                      animation: wave,
                      builder: (context, _) => Transform.scale(
                        scale: 1 + .12 * sin(wave.value * 2 * pi + phaseShift),
                        child: Container(
                          width: 13,
                          height: 13,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _online,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    conversation.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: _ink,
                      letterSpacing: -.2,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    conversation.preview,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: conversation.unread > 0
                          ? FontWeight.w600
                          : FontWeight.w400,
                      color: conversation.unread > 0
                          ? _ink.withValues(alpha: .7)
                          : _muted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  conversation.time,
                  style: const TextStyle(fontSize: 11, color: _muted),
                ),
                const SizedBox(height: 6),
                if (conversation.unread > 0)
                  AnimatedBuilder(
                    animation: wave,
                    builder: (context, child) => Transform.translate(
                      offset: Offset(
                        0,
                        sin(wave.value * 2 * pi + phaseShift) * 1.6,
                      ),
                      child: child,
                    ),
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            BrandColors.secondarySurface,
                            BrandColors.secondarySurface,
                          ],
                        ),
                      ),
                      child: Center(
                        child: Text(
                          '${conversation.unread}',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  )
                else
                  const SizedBox(height: 20),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ----------------------------------------------------------------- header

class _ThreadHeader extends StatelessWidget {
  const _ThreadHeader({
    required this.conversation,
    required this.wave,
    required this.onBack,
    required this.onMore,
  });

  final _Conversation conversation;
  final AnimationController wave;
  final VoidCallback onBack;
  final ValueChanged<BuildContext> onMore;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withValues(alpha: .62),
                Colors.white.withValues(alpha: .34),
              ],
            ),
            border: Border.all(color: Colors.white.withValues(alpha: .9)),
          ),
          child: Row(
            children: [
              LiquidPressable(
                onTap: onBack,
                borderRadius: BorderRadius.circular(16),
                rippleColor: _ink,
                intensity: .9,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: .65),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: .95),
                    ),
                  ),
                  child: const Icon(
                    Icons.arrow_back_rounded,
                    size: 18,
                    color: _ink,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: conversation.colors,
                  ),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: .8),
                    width: 1.5,
                  ),
                ),
                child: Center(
                  child: Text(
                    conversation.name[0],
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      conversation.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: _ink,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      conversation.isOnline ? 'Online' : conversation.role,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: conversation.isOnline ? _online : _muted,
                      ),
                    ),
                  ],
                ),
              ),
              LiquidPressable(
                onTap: () => HapticFeedback.selectionClick(),
                borderRadius: BorderRadius.circular(16),
                rippleColor: _ink,
                intensity: .9,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: .65),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: .95),
                    ),
                  ),
                  child: const Icon(
                    Icons.videocam_rounded,
                    size: 18,
                    color: _ink,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              LiquidPressable(
                onTap: () => HapticFeedback.selectionClick(),
                borderRadius: BorderRadius.circular(16),
                rippleColor: _ink,
                intensity: .9,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: .65),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: .95),
                    ),
                  ),
                  child: const Icon(Icons.call_rounded, size: 17, color: _ink),
                ),
              ),
              const SizedBox(width: 8),
              // Liquid 3-dot — opens a small popover just below.
              Builder(
                builder: (buttonContext) => LiquidPressable(
                  onTap: () => onMore(buttonContext),
                  borderRadius: BorderRadius.circular(16),
                  rippleColor: _ink,
                  intensity: 1.1,
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: .65),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: .95),
                      ),
                    ),
                    child: const Icon(
                      Icons.more_horiz_rounded,
                      size: 20,
                      color: _ink,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ----------------------------------------------------------------- bubble

/// A message bubble that lands with an elastic pop. Outgoing bubbles are
/// dark glass with liquid sloshing along their base; incoming ones are
/// frosted white. A liquid 3-dot sits beside every bubble.
class _Bubble extends StatelessWidget {
  const _Bubble({
    super.key,
    required this.message,
    required this.wave,
    required this.onMore,
  });

  final _Msg message;
  final AnimationController wave;
  final ValueChanged<BuildContext> onMore;

  @override
  Widget build(BuildContext context) {
    final mine = message.mine;
    final radius = BorderRadius.only(
      topLeft: const Radius.circular(20),
      topRight: const Radius.circular(20),
      bottomLeft: Radius.circular(mine ? 20 : 6),
      bottomRight: Radius.circular(mine ? 6 : 20),
    );

    final moreButton = Builder(
      builder: (buttonContext) => LiquidPressable(
        onTap: () => onMore(buttonContext),
        borderRadius: BorderRadius.circular(14),
        rippleColor: _ink,
        intensity: 1.05,
        child: Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: .55),
            border: Border.all(color: Colors.white.withValues(alpha: .9)),
          ),
          child: Icon(
            Icons.more_horiz_rounded,
            size: 16,
            color: _ink.withValues(alpha: .55),
          ),
        ),
      ),
    );

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 380),
      curve: Curves.easeOutCubic,
      builder: (context, t, child) => Transform.translate(
        offset: Offset(0, 6 * (1 - t.clamp(0, 1))),
        child: Transform.scale(
          scale: (.94 + .06 * t).clamp(0, 1),
          alignment: mine ? Alignment.bottomRight : Alignment.bottomLeft,
          child: Opacity(opacity: t.clamp(0, 1), child: child),
        ),
      ),
      child: Align(
        alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 9),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (mine) ...[moreButton, const SizedBox(width: 6)],
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 268),
                child: LiquidPressable(
                  onTap: () => onMore(context),
                  borderRadius: radius,
                  rippleColor: mine ? Colors.white : _ink,
                  intensity: .55,
                  child: ClipRRect(
                    borderRadius: radius,
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(15, 10, 15, 8),
                        decoration: BoxDecoration(
                          borderRadius: radius,
                          gradient: mine
                              ? LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    const Color(
                                      0xFF2A2F3E,
                                    ).withValues(alpha: .96),
                                    const Color(
                                      0xFF15181F,
                                    ).withValues(alpha: .93),
                                  ],
                                )
                              : LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Colors.white.withValues(alpha: .72),
                                    Colors.white.withValues(alpha: .44),
                                  ],
                                ),
                          border: Border.all(
                            color: Colors.white.withValues(
                              alpha: mine ? .3 : .9,
                            ),
                          ),
                        ),
                        child: Stack(
                          children: [
                            Positioned.fill(
                              child: AnimatedBuilder(
                                animation: wave,
                                builder: (context, _) => CustomPaint(
                                  painter: WaveFillPainter(
                                    phase:
                                        wave.value * 2 * pi +
                                        message.text.length,
                                    fill: .22,
                                    color: (mine ? Colors.white : _ink)
                                        .withValues(alpha: .05),
                                    amplitude: 2.5,
                                    frequency: 1.4,
                                  ),
                                ),
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  message.text,
                                  style: TextStyle(
                                    fontSize: 13.5,
                                    height: 1.35,
                                    fontWeight: FontWeight.w500,
                                    color: mine ? Colors.white : _ink,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      message.time,
                                      style: TextStyle(
                                        fontSize: 9.5,
                                        color: (mine ? Colors.white : _muted)
                                            .withValues(alpha: mine ? .55 : 1),
                                      ),
                                    ),
                                    if (message.autoDelete ==
                                        _AutoDelete.hours24) ...[
                                      const SizedBox(width: 6),
                                      Icon(
                                        Icons.timer_outlined,
                                        size: 11,
                                        color: (mine ? Colors.white : _ink)
                                            .withValues(alpha: .45),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              if (!mine) ...[const SizedBox(width: 6), moreButton],
            ],
          ),
        ),
      ),
    );
  }
}

// ------------------------------------------------------------ typing dots

/// Three droplets bobbing in sequence while the peer types.
class _TypingBubble extends StatelessWidget {
  const _TypingBubble({required this.wave});

  final AnimationController wave;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              color: Colors.white.withValues(alpha: .6),
              border: Border.all(color: Colors.white.withValues(alpha: .9)),
            ),
            child: AnimatedBuilder(
              animation: wave,
              builder: (context, _) => Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var i = 0; i < 3; i++)
                    Padding(
                      padding: EdgeInsets.only(right: i == 2 ? 0 : 5),
                      child: Transform.translate(
                        offset: Offset(
                          0,
                          sin((wave.value * 2 * pi * 2) - i * .9) * 2.6,
                        ),
                        child: Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _ink.withValues(alpha: .45),
                          ),
                        ),
                      ),
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

// ----------------------------------------------------------- message menu

enum _MessageMenuAction { autoDelete24h, never, delete }

/// Tiny liquid card that wells up just under the 3-dot anchor.
class _LiquidPopoverRoute extends PopupRoute<_MessageMenuAction> {
  _LiquidPopoverRoute({required this.anchorRect, required this.selected});

  final Rect anchorRect;
  final _AutoDelete selected;

  @override
  Color? get barrierColor => _ink.withValues(alpha: .12);

  @override
  bool get barrierDismissible => true;

  @override
  String? get barrierLabel => 'Dismiss';

  @override
  Duration get transitionDuration => const Duration(milliseconds: 340);

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    return _MessageOptionsPopover(
      anchorRect: anchorRect,
      selected: selected,
      animation: animation,
    );
  }
}

class _MessageOptionsPopover extends StatefulWidget {
  const _MessageOptionsPopover({
    required this.anchorRect,
    required this.selected,
    required this.animation,
  });

  final Rect anchorRect;
  final _AutoDelete selected;
  final Animation<double> animation;

  @override
  State<_MessageOptionsPopover> createState() => _MessageOptionsPopoverState();
}

class _MessageOptionsPopoverState extends State<_MessageOptionsPopover>
    with SingleTickerProviderStateMixin {
  static const _width = 240.0;
  static const _height = 168.0;

  late final AnimationController _wave = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  )..repeat();

  @override
  void dispose() {
    _wave.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final padding = MediaQuery.paddingOf(context);

    var left = widget.anchorRect.center.dx - _width / 2;
    left = left.clamp(12.0, size.width - _width - 12);

    // Prefer opening just below the 3-dots; flip above if near the bottom.
    var top = widget.anchorRect.bottom + 8;
    final maxTop = size.height - padding.bottom - _height - 12;
    final openAbove = top > maxTop;
    if (openAbove) {
      top = widget.anchorRect.top - _height - 8;
    }
    top = top.clamp(padding.top + 8, maxTop);

    final curved = CurvedAnimation(
      parent: widget.animation,
      curve: Curves.easeOutBack,
      reverseCurve: Curves.easeInCubic,
    );

    return Material(
      type: MaterialType.transparency,
      child: Stack(
        children: [
          Positioned(
            left: left,
            top: top,
            width: _width,
            child: FadeTransition(
              opacity: curved,
              child: ScaleTransition(
                scale: Tween<double>(begin: .86, end: 1).animate(curved),
                alignment: openAbove
                    ? Alignment.bottomCenter
                    : Alignment.topCenter,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                    child: AnimatedBuilder(
                      animation: _wave,
                      builder: (context, child) => Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.white.withValues(alpha: .88),
                              Colors.white.withValues(alpha: .58),
                            ],
                          ),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: .95),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: _ink.withValues(alpha: .18),
                              blurRadius: 22,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Stack(
                          children: [
                            Positioned.fill(
                              child: CustomPaint(
                                painter: WaveFillPainter(
                                  phase: _wave.value * 2 * pi,
                                  fill: .12,
                                  color: _ink.withValues(alpha: .04),
                                  amplitude: 2.4,
                                  frequency: 1.5,
                                ),
                              ),
                            ),
                            child!,
                          ],
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _PopoverTile(
                              wave: _wave,
                              icon: Icons.timer_outlined,
                              label: 'Auto delete after 24 hour',
                              selected: widget.selected == _AutoDelete.hours24,
                              onTap: () => Navigator.of(
                                context,
                              ).pop(_MessageMenuAction.autoDelete24h),
                            ),
                            const SizedBox(height: 4),
                            _PopoverTile(
                              wave: _wave,
                              icon: Icons.all_inclusive_rounded,
                              label: 'Never',
                              selected: widget.selected == _AutoDelete.never,
                              onTap: () => Navigator.of(
                                context,
                              ).pop(_MessageMenuAction.never),
                            ),
                            const SizedBox(height: 4),
                            _PopoverTile(
                              wave: _wave,
                              icon: Icons.delete_outline_rounded,
                              label: 'Delete message',
                              destructive: true,
                              onTap: () => Navigator.of(
                                context,
                              ).pop(_MessageMenuAction.delete),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PopoverTile extends StatelessWidget {
  const _PopoverTile({
    required this.wave,
    required this.icon,
    required this.label,
    required this.onTap,
    this.selected = false,
    this.destructive = false,
  });

  final AnimationController wave;
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool selected;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final accent = destructive ? const Color(0xFFC0392B) : _ink;

    return LiquidPressable(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      rippleColor: destructive ? accent : (selected ? Colors.white : _ink),
      intensity: 1.2,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: selected ? 1 : 0),
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeInOutCubic,
        builder: (context, t, _) => AnimatedBuilder(
          animation: wave,
          builder: (context, _) {
            final labelColor = destructive
                ? accent
                : Color.lerp(_ink, Colors.white, ((t - .3) / .45).clamp(0, 1))!;
            return Container(
              height: 42,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                color: Colors.white.withValues(alpha: .42),
                border: Border.all(
                  color: destructive
                      ? accent.withValues(alpha: .22)
                      : Color.lerp(
                          Colors.white.withValues(alpha: .7),
                          Colors.white.withValues(alpha: .3),
                          t,
                        )!,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Stack(
                  children: [
                    if (!destructive)
                      Positioned.fill(
                        child: CustomPaint(
                          painter: WaveFillPainter(
                            phase: wave.value * 2 * pi,
                            fill: t * 1.1,
                            color: const Color(
                              0xFF15181F,
                            ).withValues(alpha: .93),
                            amplitude: 2.5,
                            frequency: 1.5,
                          ),
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Row(
                        children: [
                          // Matching side rails keep icon + label optically centered
                          // whether or not the checkmark is showing.
                          const SizedBox(width: 18),
                          Expanded(
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                return Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      icon,
                                      size: 16,
                                      color: destructive
                                          ? accent
                                          : (selected
                                                ? labelColor
                                                : _ink.withValues(alpha: .7)),
                                    ),
                                    const SizedBox(width: 7),
                                    ConstrainedBox(
                                      constraints: BoxConstraints(
                                        maxWidth:
                                            (constraints.maxWidth - 23)
                                                .clamp(0, double.infinity),
                                      ),
                                      child: Text(
                                        label,
                                        maxLines: 1,
                                        softWrap: false,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          letterSpacing: -.1,
                                          height: 1.1,
                                          color: labelColor,
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
                          SizedBox(
                            width: 18,
                            child: selected && !destructive
                                ? Icon(
                                    Icons.check_rounded,
                                    size: 15,
                                    color: labelColor,
                                  )
                                : null,
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
