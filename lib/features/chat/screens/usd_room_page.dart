import 'package:dollar_trapped/features/chat/widgets/message_list.dart';
import 'package:dollar_trapped/features/chat/widgets/rate_bar.dart';
import 'package:dollar_trapped/features/ads/widgets/usd_room_ads.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import 'package:dollar_trapped/core/auth/token_store.dart';
import 'package:dollar_trapped/core/network/api_config.dart';
import 'package:dollar_trapped/core/network/api_exception.dart';
import 'package:dollar_trapped/core/realtime/dollar_socket.dart';
import 'package:dollar_trapped/features/auth/screens/auth_page.dart';
import 'package:dollar_trapped/features/shared/data/api_models.dart';
import 'package:dollar_trapped/features/shared/data/dollar_repository.dart';

class UsdRoomPage extends StatefulWidget {
  const UsdRoomPage({
    super.key,
    required this.onRateBarTap,
    required this.repository,
  });

  final VoidCallback onRateBarTap;
  final DollarRepository repository;

  @override
  State<UsdRoomPage> createState() => _UsdRoomPageState();
}

class _UsdRoomPageState extends State<UsdRoomPage> {
  static const _ink = Color(0xFF151916);
  static const _muted = Color(0xFF667069);
  static const _surface = Color(0xFFF5F7F5);
  static const _line = Color(0xFFE1E6E2);
  static const _action = Color(0xFF008A29);

  final _messageController = TextEditingController();
  final _messageScrollController = ScrollController();
  late Future<MessagePage> _messagesFuture;
  final _realtimeMessages = <RealtimeMessage>[];
  final _blockedUserIds = <String>{};
  DollarSocket? _socket;
  StreamSubscription<RealtimeMessage>? _messageSubscription;
  StreamSubscription<DollarSocketState>? _stateSubscription;
  StreamSubscription<String>? _deletionSubscription;
  StreamSubscription<SocketError>? _errorSubscription;
  StreamSubscription<String>? _sendFailureSubscription;
  var _socketState = DollarSocketState.disconnected;
  var _ownsSocket = false;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _messagesFuture = widget.repository.getMessages();
    _loadModerationContext();
    _socket = context.read<DollarSocket?>();
    if (_socket == null) {
      final tokenStore = context.read<TokenStore?>();
      if (tokenStore == null) return;
      _socket = DollarSocket(
        url: ApiConfig.webSocketUrl,
        tokenStore: tokenStore,
      );
      _ownsSocket = true;
    }
    final socket = _socket!;
    _messageSubscription = socket.messages.listen((message) {
      if (!mounted || _isBlockedRealtimeMessage(message)) return;
      setState(() => _realtimeMessages.add(message));
    });
    _stateSubscription = socket.states.listen((state) {
      if (mounted) setState(() => _socketState = state);
    });
    _deletionSubscription = socket.deletedMessageIds.listen((messageId) {
      if (mounted) {
        setState(
          () => _realtimeMessages.removeWhere(
            (message) => message.id == messageId,
          ),
        );
      }
    });
    _errorSubscription = socket.errors.listen((error) {
      if (!mounted) return;
      if (error.code == 'TOKEN_EXPIRED') {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute<void>(builder: (_) => const AuthPage()),
          (route) => false,
        );
        return;
      }
      if (error.scope == 'SEND_MESSAGE' &&
          (error.code == 'BAD_REQUEST' || error.code == 'VALIDATION_ERROR')) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('메시지 내용을 확인해 주세요.')));
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    });
    _sendFailureSubscription = socket.failedMessageIds.listen((_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('메시지 전송에 실패했어요. 다시 시도해 주세요.')),
      );
    });
    socket.connect();
  }

  void _reloadMessages() {
    setState(() => _messagesFuture = widget.repository.getMessages());
  }

  Future<void> _loadModerationContext() async {
    try {
      final results = await Future.wait([
        widget.repository.getMe(),
        widget.repository.getBlockedUsers(),
      ]);
      if (!mounted) return;
      final user = results[0] as User;
      final blockedUsers = results[1] as List<BlockedUser>;
      setState(() {
        _currentUserId = user.id;
        _blockedUserIds.addAll(blockedUsers.map((user) => user.userId));
      });
    } catch (_) {
      // Chat reading remains available when moderation context cannot load.
    }
  }

  bool _isBlockedRealtimeMessage(RealtimeMessage message) {
    final author = message.data['author'];
    final authorId = author is Map ? author['id'] as String? : null;
    return authorId != null && _blockedUserIds.contains(authorId);
  }

  Future<void> _moderateMessage({
    required String messageId,
    required String authorId,
  }) async {
    final action = await showModalBottomSheet<_MessageAction>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('신고'),
              onTap: () => Navigator.pop(context, _MessageAction.report),
            ),
            ListTile(
              title: const Text('차단'),
              onTap: () => Navigator.pop(context, _MessageAction.block),
            ),
          ],
        ),
      ),
    );
    if (!mounted || action == null) return;
    if (action == _MessageAction.report) {
      await _reportMessage(messageId);
    } else {
      await _blockUser(authorId);
    }
  }

  Future<void> _reportMessage(String messageId) async {
    try {
      await widget.repository.reportMessage(messageId, reason: 'OTHER');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('신고되었습니다.')));
      }
    } on ApiException catch (error) {
      if (!mounted) return;
      final message =
          error.statusCode == 409 || error.code == 'ALREADY_REPORTED'
          ? '이미 신고한 메시지입니다.'
          : error.userMessage;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('신고하지 못했습니다. 다시 시도해 주세요.')),
        );
      }
    }
  }

  Future<void> _blockUser(String userId) async {
    setState(() {
      _blockedUserIds.add(userId);
      _realtimeMessages.removeWhere((message) {
        final author = message.data['author'];
        return author is Map && author['id'] == userId;
      });
    });
    try {
      await widget.repository.blockUser(userId);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('사용자를 차단했습니다.')));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('차단하지 못했습니다. 다시 시도해 주세요.')),
        );
      }
    }
  }

  @override
  void dispose() {
    _messageSubscription?.cancel();
    _stateSubscription?.cancel();
    _deletionSubscription?.cancel();
    _errorSubscription?.cancel();
    _sendFailureSubscription?.cancel();
    if (_ownsSocket) _socket?.dispose();
    _messageController.dispose();
    _messageScrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final content = _messageController.text.trim();
    if (content.isEmpty) return;
    final socket = _socket;
    if (socket == null || socket.state != DollarSocketState.authenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('채팅 서버에 연결하거나 로그인한 뒤 전송할 수 있어요.')),
      );
      return;
    }
    await socket.sendMessage(content);
    if (mounted) _messageController.clear();
  }

  String get _socketStatusLabel {
    switch (_socketState) {
      case DollarSocketState.authenticated:
        return '● 실시간 채팅';
      case DollarSocketState.connecting:
      case DollarSocketState.connected:
      case DollarSocketState.authenticating:
      case DollarSocketState.reconnecting:
        return '● 채팅 연결 중';
      case DollarSocketState.disconnected:
        return '● 채팅 오프라인';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 85,
                    height: 32,
                    child: SvgPicture.asset(
                      'assets/images/dollar_wordmark.svg',
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Text(
                        'USD방',
                        style: TextStyle(
                          color: _ink,
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          height: 32 / 24,
                        ),
                      ),
                      SizedBox(width: 12),
                      Text(
                        _socketStatusLabel,
                        style: TextStyle(
                          color: _socketState == DollarSocketState.authenticated
                              ? _action
                              : _muted,
                          fontSize: 12,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: MessageList(
                future: _messagesFuture,
                realtimeMessages: _realtimeMessages,
                blockedUserIds: _blockedUserIds,
                currentUserId: _currentUserId,
                scrollController: _messageScrollController,
                onRetry: _reloadMessages,
                onModerate: _moderateMessage,
              ),
            ),
            InkWell(onTap: widget.onRateBarTap, child: const RateBar()),
            Container(
              height: 76,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      onChanged: (_) => setState(() {}),
                      style: const TextStyle(
                        color: _ink,
                        fontSize: 15,
                        height: 1.6,
                      ),
                      decoration: InputDecoration(
                        hintText: '메시지를 입력하세요',
                        hintStyle: const TextStyle(
                          color: _muted,
                          fontSize: 15,
                          height: 1.6,
                        ),
                        filled: true,
                        fillColor: _surface,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 44,
                    height: 44,
                    child: ElevatedButton(
                      key: const Key('chat-send'),
                      onPressed: _messageController.text.trim().isEmpty
                          ? null
                          : _sendMessage,
                      style: ElevatedButton.styleFrom(
                        elevation: 0,
                        padding: EdgeInsets.zero,
                        backgroundColor: _action,
                        disabledBackgroundColor: _line,
                        foregroundColor: Colors.white,
                        disabledForegroundColor: _muted,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        '↑',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          height: 1,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const UsdRoomAds(),
            const SizedBox(height: 34),
          ],
        ),
      ),
    );
  }
}

enum _MessageAction { report, block }
