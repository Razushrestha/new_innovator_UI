import 'dart:async';
import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'models/api_response.dart';
import 'models/chat_models.dart';
import 'services/auth_session.dart';
import 'services/chat_api.dart';
import 'theme/brand_colors.dart';
import 'widgets/liquid_pressable.dart';
import 'widgets/wave_fill_painter.dart';

const _ink = BrandColors.ink;
const _muted = BrandColors.muted;
const _online = Color(0xFF17A275);

const _avatarPalettes = <List<Color>>[
  [Color(0xFF4C1D95), Color(0xFF7C3AED)],
  [Color(0xFF1E3A8A), Color(0xFF2563EB)],
  [Color(0xFF0F766E), Color(0xFF14B8A6)],
  [Color(0xFF92400E), Color(0xFFB45309)],
  [Color(0xFF9F1239), Color(0xFFE11D48)],
  [Color(0xFF0369A1), Color(0xFF38BDF8)],
  [Color(0xFF047857), Color(0xFF34D399)],
  [Color(0xFF6D28D9), Color(0xFFA78BFA)],
];

List<Color> _colorsFor(String seed) {
  final i = seed.hashCode.abs() % _avatarPalettes.length;
  return _avatarPalettes[i];
}

String _formatChatTime(DateTime? dt) {
  if (dt == null) return '';
  final now = DateTime.now();
  final diff = now.difference(dt);
  if (diff.inMinutes < 1) return 'now';
  if (diff.inHours < 1) return '${diff.inMinutes}m';
  if (diff.inDays < 1) return '${diff.inHours}h';
  if (diff.inDays < 7) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[dt.weekday - 1];
  }
  return '${dt.day}/${dt.month}';
}

String _formatBubbleTime(DateTime? dt) {
  if (dt == null) return '';
  final local = dt.toLocal();
  final h = local.hour.toString().padLeft(2, '0');
  final m = local.minute.toString().padLeft(2, '0');
  return '$h:$m';
}

class _Conversation {
  _Conversation({
    required this.id,
    required this.name,
    required this.role,
    required this.preview,
    required this.time,
    required this.colors,
    this.peerUserId,
    this.unread = 0,
    this.isOnline = false,
  });

  final String id;
  final String name;
  final String role;
  final String preview;
  final String time;
  final List<Color> colors;
  final String? peerUserId;
  int unread;
  final bool isOnline;

  factory _Conversation.fromApi(ChatConversation c) {
    final me = AuthSession.instance.userId;
    final peer = c.peerOf(me);
    final name = peer?.username?.trim().isNotEmpty == true
        ? peer!.username!.trim()
        : 'Chat';
    final preview = c.lastMessage?.content?.trim().isNotEmpty == true
        ? c.lastMessage!.content!.trim()
        : 'No messages yet';
    return _Conversation(
      id: c.id,
      name: name,
      role: 'Direct',
      preview: preview,
      time: _formatChatTime(c.lastMessage?.createdAt ?? c.createdAt),
      colors: _colorsFor(peer?.userId ?? c.id),
      peerUserId: peer?.userId,
      unread: c.unreadCount,
    );
  }
}

enum _AutoDelete { never, hours24 }

class _Msg {
  _Msg(
    this.text, {
    required this.mine,
    required this.time,
    String? id,
    this.createdAt,
  }) : id = id ?? UniqueKey().toString();

  final String id;
  final String text;
  final bool mine;
  final String time;
  final DateTime? createdAt;
  _AutoDelete autoDelete = _AutoDelete.never;

  factory _Msg.fromApi(ChatMessage m) {
    final me = AuthSession.instance.userId;
    return _Msg(
      m.content?.trim().isNotEmpty == true ? m.content!.trim() : '(empty)',
      id: m.id,
      mine: m.senderId == me,
      time: _formatBubbleTime(m.createdAt),
      createdAt: m.createdAt,
    );
  }
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

  final _chatApi = ChatApi();
  final List<_Conversation> _conversations = [];
  final Map<String, List<_Msg>> _messages = {};

  _Conversation? _open;
  bool _loadingList = true;
  bool _loadingThread = false;
  bool _sending = false;
  String? _listError;
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
  void initState() {
    super.initState();
    _loadConversations();
  }

  Future<void> _loadConversations() async {
    if (!AuthSession.instance.isSignedIn) {
      setState(() {
        _loadingList = false;
        _listError = 'Sign in to load chats';
        _conversations.clear();
      });
      return;
    }
    setState(() {
      _loadingList = true;
      _listError = null;
    });
    try {
      final remote = await _chatApi.listConversations();
      if (!mounted) return;
      setState(() {
        _conversations
          ..clear()
          ..addAll(remote.map(_Conversation.fromApi));
        _loadingList = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingList = false;
        _listError = e.message;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingList = false;
        _listError = 'Could not load chats';
      });
    }
  }

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
    // Best-effort remote delete (local already updated for snappy UI).
    unawaited(() async {
      try {
        await _chatApi.deleteMessage(messageId);
      } catch (_) {
        if (mounted) _liquidToast('Could not delete on server');
      }
    }());
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

  Future<void> _openConversation(_Conversation conversation) async {
    HapticFeedback.selectionClick();
    final cached = _messages[conversation.id];
    setState(() {
      _open = conversation;
      conversation.unread = 0;
      _loadingThread = cached == null;
    });
    try {
      final remote = await _chatApi.listMessages(conversation.id);
      unawaited(() async {
        try {
          await _chatApi.markRead(conversation.id);
        } catch (_) {}
      }());
      if (!mounted || _open?.id != conversation.id) return;
      final mapped = remote
          .where((m) => !m.isDeleted)
          .map(_Msg.fromApi)
          .toList();
      setState(() {
        _messages[conversation.id] = mapped;
        _loadingThread = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _loadingThread = false);
      if (cached == null) _liquidToast(e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingThread = false);
      if (cached == null) _liquidToast('Could not load messages');
    }
  }

  void _closeConversation() {
    HapticFeedback.selectionClick();
    _composerFocus.unfocus();
    setState(() {
      _open = null;
      _loadingThread = false;
    });
    // List already reflects local unread=0; skip full refetch on every back.
  }

  Future<void> _deliverMessage(_Conversation open, String text) async {
    if (_sending) return;
    setState(() {
      _composer.clear();
      _sending = true;
      _sendCount++;
    });
    HapticFeedback.mediumImpact();

    try {
      final sent = await _chatApi.sendMessage(open.id, content: text);
      if (!mounted || _open?.id != open.id) return;
      final msg = _Msg.fromApi(sent);
      setState(() {
        final list = _messages.putIfAbsent(open.id, () => <_Msg>[]);
        list.add(msg);
        _sending = false;
        final idx = _conversations.indexWhere((c) => c.id == open.id);
        if (idx >= 0) {
          _conversations[idx] = _Conversation(
            id: open.id,
            name: open.name,
            role: open.role,
            preview: text,
            time: 'now',
            colors: open.colors,
            peerUserId: open.peerUserId,
            unread: 0,
            isOnline: open.isOnline,
          );
          if (_open?.id == open.id) _open = _conversations[idx];
        }
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _sending = false);
      _liquidToast(e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _sending = false);
      _liquidToast('Could not send message');
    }
  }

  void _send() {
    final open = _open;
    final text = _composer.text.trim();
    if (open == null || text.isEmpty) {
      HapticFeedback.selectionClick();
      return;
    }
    unawaited(_deliverMessage(open, text));
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
    return RefreshIndicator(
      color: BrandColors.secondarySurface,
      onRefresh: _loadConversations,
      child: ListView(
        key: const ValueKey('conversations'),
        physics: const AlwaysScrollableScrollPhysics(
          parent: ClampingScrollPhysics(),
        ),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding:
            EdgeInsets.fromLTRB(20, padding.top + 8, 20, padding.bottom + 6),
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
          const SizedBox(height: 14),
          _stagger(
            index: 1,
            child: Row(
              children: [
                const Expanded(
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
                LiquidPressable(
                  onTap: _showNewChatSheet,
                  borderRadius: BorderRadius.circular(999),
                  rippleColor: _ink,
                  intensity: .7,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      color: BrandColors.secondarySurface.withValues(alpha: .92),
                    ),
                    child: const Text(
                      'New chat',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          if (_loadingList)
            const Padding(
              padding: EdgeInsets.only(top: 48),
              child: Center(
                child: CircularProgressIndicator(strokeWidth: 2.4),
              ),
            )
          else if (_listError != null)
            Padding(
              padding: const EdgeInsets.only(top: 36),
              child: Column(
                children: [
                  Text(
                    _listError!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 13.5, color: _muted),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: _loadConversations,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            )
          else if (chats.isEmpty)
            _stagger(
              index: 2,
              child: Padding(
                padding: const EdgeInsets.only(top: 36),
                child: Center(
                  child: Text(
                    _listQuery.isEmpty
                        ? 'No conversations yet.\nTap New chat to start.'
                        : 'No chats for “$_listQuery”',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 13, color: _muted),
                  ),
                ),
              ),
            )
          else ...[
            if (_recentChats.isNotEmpty) ...[
              _stagger(
                index: 2,
                child: _AvatarRail(
                  title: 'Recent',
                  wave: _wave,
                  people: [
                    for (final c in _recentChats)
                      _RailPerson(c.name, c.colors, isOnline: c.isOnline),
                  ],
                  onTapName: (name) {
                    final match = _conversations.where((c) => c.name == name);
                    if (match.isNotEmpty) _openConversation(match.first);
                  },
                ),
              ),
              const SizedBox(height: 14),
            ],
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
        ],
      ),
    );
  }

  Future<void> _showNewChatSheet() async {
    HapticFeedback.selectionClick();
    final usernameCtrl = TextEditingController();
    final userIdCtrl = TextEditingController();
    final created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            bottom: MediaQuery.viewInsetsOf(ctx).bottom + 16,
          ),
          child: Material(
            color: Colors.white.withValues(alpha: .94),
            borderRadius: BorderRadius.circular(22),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Start a chat',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: _ink,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Enter the peer’s auth user ID (UUID) and optional username.',
                    style: TextStyle(
                      fontSize: 12.5,
                      color: _ink.withValues(alpha: .5),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: userIdCtrl,
                    decoration: const InputDecoration(
                      labelText: 'User ID (required)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: usernameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Username (optional)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 14),
                  FilledButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    style: FilledButton.styleFrom(
                      backgroundColor: BrandColors.secondarySurface,
                    ),
                    child: const Text('Create'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
    final userId = userIdCtrl.text.trim();
    final username = usernameCtrl.text.trim();
    usernameCtrl.dispose();
    userIdCtrl.dispose();
    if (created != true || userId.isEmpty) return;

    try {
      final conv = await _chatApi.createConversation(
        participantUserId: userId,
        participantUsername: username.isEmpty ? null : username,
      );
      if (!mounted) return;
      final local = _Conversation.fromApi(conv);
      setState(() {
        _conversations.removeWhere((c) => c.id == local.id);
        _conversations.insert(0, local);
        _messages[local.id] = [];
      });
      await _openConversation(local);
    } on ApiException catch (e) {
      if (mounted) _liquidToast(e.message);
    } catch (_) {
      if (mounted) _liquidToast('Could not create chat');
    }
  }

  // ---------------------------------------------------------------- thread

  Widget _buildThread(_Conversation conversation) {
    final padding = widget.contentPadding;
    final messages = _messages[conversation.id] ?? const <_Msg>[];
    return Padding(
      key: ValueKey('thread-${conversation.id}'),
      padding: EdgeInsets.fromLTRB(20, padding.top + 8, 20, padding.bottom + 6),
      child: Column(
        children: [
          _ThreadHeader(
            conversation: conversation,
            wave: _wave,
            onBack: _closeConversation,
            onMore: (anchor) async {
              HapticFeedback.selectionClick();
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Delete conversation?'),
                  content: const Text(
                    'This removes the chat from your list on the server.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Delete'),
                    ),
                  ],
                ),
              );
              if (confirm == true) await _deleteConversation(conversation);
            },
          ),
          const SizedBox(height: 12),
          Expanded(
            child: _loadingThread
                ? const Center(
                    child: CircularProgressIndicator(strokeWidth: 2.4),
                  )
                : ListView.builder(
                    reverse: true,
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final messageIndex = messages.length - 1 - index;
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

  Future<void> _deleteConversation(_Conversation conversation) async {
    try {
      await _chatApi.deleteConversation(conversation.id);
      if (!mounted) return;
      setState(() {
        _conversations.removeWhere((c) => c.id == conversation.id);
        _messages.remove(conversation.id);
        if (_open?.id == conversation.id) _open = null;
      });
      _liquidToast('Conversation deleted');
    } on ApiException catch (e) {
      if (mounted) _liquidToast(e.message);
    } catch (_) {
      if (mounted) _liquidToast('Could not delete conversation');
    }
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
                  alignment: Alignment.center,
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
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Matching side rails keep icon + label optically centered
                          // whether or not the checkmark is showing.
                          const SizedBox(width: 18),
                          Expanded(
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                return Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.center,
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
                                          height: 1,
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
