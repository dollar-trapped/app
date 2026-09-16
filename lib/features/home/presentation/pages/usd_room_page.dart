import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import '../../../../core/auth/token_store.dart';
import '../../../../core/network/api_config.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/realtime/dollar_socket.dart';
import '../../../auth/presentation/pages/auth_page.dart';
import '../../../shared/data/api_models.dart';
import '../../../shared/data/dollar_repository.dart';

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
      setState(() => _realtimeMessages.insert(0, message));
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
          : error.message;
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
              child: _MessageList(
                future: _messagesFuture,
                realtimeMessages: _realtimeMessages,
                blockedUserIds: _blockedUserIds,
                currentUserId: _currentUserId,
                onRetry: _reloadMessages,
                onModerate: _moderateMessage,
              ),
            ),
            InkWell(onTap: widget.onRateBarTap, child: const _RateBar()),
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
                      onPressed: _messageController.text.isEmpty
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
            const SizedBox(height: 34),
          ],
        ),
      ),
    );
  }
}

class _MessageList extends StatelessWidget {
  const _MessageList({
    required this.future,
    required this.realtimeMessages,
    required this.blockedUserIds,
    required this.currentUserId,
    required this.onRetry,
    required this.onModerate,
  });

  final Future<MessagePage> future;
  final List<RealtimeMessage> realtimeMessages;
  final Set<String> blockedUserIds;
  final String? currentUserId;
  final VoidCallback onRetry;
  final Future<void> Function({
    required String messageId,
    required String authorId,
  })
  onModerate;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<MessagePage>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: TextButton(
              onPressed: onRetry,
              child: const Text('메시지를 다시 불러오기'),
            ),
          );
        }
        final messages = (snapshot.data?.items ?? const <ChatMessage>[])
            .where(
              (message) =>
                  message.author.id == null ||
                  !blockedUserIds.contains(message.author.id),
            )
            .toList();
        if (messages.isEmpty && realtimeMessages.isEmpty) {
          return const Center(
            child: Text(
              '아직 메시지가 없어요.',
              style: TextStyle(color: Color(0xFF667069)),
            ),
          );
        }
        final items = <Widget>[
          ...realtimeMessages
              .where((message) {
                final author = message.data['author'];
                final authorId = author is Map ? author['id'] as String? : null;
                return authorId == null || !blockedUserIds.contains(authorId);
              })
              .map(
                (message) => _RealtimeChatMessage(
                  message: message,
                  currentUserId: currentUserId,
                  onModerate: onModerate,
                ),
              ),
          ...messages.map(
            (message) => _messageWidget(
              message,
              currentUserId: currentUserId,
              onModerate: onModerate,
            ),
          ),
        ];
        return ListView.separated(
          reverse: true,
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          itemCount: items.length,
          separatorBuilder: (_, _) => const SizedBox(height: 24),
          itemBuilder: (_, index) => items[index],
        );
      },
    );
  }

  static String _formatTime(DateTime time) {
    final local = time.toLocal();
    final period = local.hour < 12 ? '오전' : '오후';
    final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
    return '$period $hour:${local.minute.toString().padLeft(2, '0')}';
  }

  static Widget _messageWidget(
    ChatMessage message, {
    required String? currentUserId,
    required Future<void> Function({
      required String messageId,
      required String authorId,
    })
    onModerate,
  }) {
    final profit = message.author.profitRate;
    return _ChatMessage(
      nickname: message.author.nickname,
      holding: message.author.usdAmount == null
          ? ''
          : r'$' + message.author.usdAmount!,
      profit: _profitText(profit),
      profitColor: profit?.startsWith('-') ?? false
          ? const Color(0xFF2463B5)
          : const Color(0xFF008A29),
      message: message.content,
      time: _formatTime(message.createdAt),
      onLongPress:
          currentUserId == null ||
              message.author.id == null ||
              message.author.id == currentUserId
          ? null
          : () =>
                onModerate(messageId: message.id, authorId: message.author.id!),
    );
  }

  static String _profitText(String? profit) {
    if (profit == null) return '';
    final prefix = double.tryParse(profit) != null && !profit.startsWith('-')
        ? '+'
        : '';
    return '$prefix$profit%';
  }
}

class _RealtimeChatMessage extends StatelessWidget {
  const _RealtimeChatMessage({
    required this.message,
    required this.currentUserId,
    required this.onModerate,
  });

  final RealtimeMessage message;
  final String? currentUserId;
  final Future<void> Function({
    required String messageId,
    required String authorId,
  })
  onModerate;

  @override
  Widget build(BuildContext context) {
    final author = message.data['author'] is Map
        ? Map<String, dynamic>.from(message.data['author'] as Map)
        : const <String, dynamic>{};
    final authorId = author['id'] as String?;
    return _ChatMessage(
      nickname: author['nickname'] as String? ?? '익명',
      holding: author['usdAmount'] == null ? '' : "\$${author['usdAmount']}",
      profit: _MessageList._profitText(author['profitRate'] as String?),
      message: message.content,
      time: _MessageList._formatTime(DateTime.now()),
      onLongPress:
          currentUserId == null || authorId == null || authorId == currentUserId
          ? null
          : () => onModerate(messageId: message.id, authorId: authorId),
    );
  }
}

class _ChatMessage extends StatelessWidget {
  const _ChatMessage({
    required this.nickname,
    required this.holding,
    required this.profit,
    required this.message,
    required this.time,
    this.profitColor = const Color(0xFF008A29),
    this.onLongPress,
  });

  final String nickname;
  final String holding;
  final String profit;
  final String message;
  final String time;
  final Color profitColor;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    const alignment = CrossAxisAlignment.start;
    return GestureDetector(
      onLongPress: onLongPress,
      behavior: HitTestBehavior.opaque,
      child: Column(
        crossAxisAlignment: alignment,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                nickname,
                style: const TextStyle(
                  color: Color(0xFF151916),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  height: 20 / 13,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                holding,
                style: const TextStyle(
                  color: Color(0xFF667069),
                  fontSize: 12,
                  height: 1.5,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                profit,
                style: TextStyle(color: profitColor, fontSize: 12, height: 1.5),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            constraints: const BoxConstraints(maxWidth: 304),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F7F5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              message,
              style: const TextStyle(
                color: Color(0xFF151916),
                fontSize: 15,
                height: 1.6,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            time,
            style: const TextStyle(
              color: Color(0xFF667069),
              fontSize: 12,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

enum _MessageAction { report, block }

class _RateBar extends StatelessWidget {
  const _RateBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0xFFE1E6E2))),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'USD/KRW',
                    style: TextStyle(
                      color: Color(0xFF667069),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      height: 20 / 13,
                    ),
                  ),
                  SizedBox(width: 12),
                  Text(
                    '1,346.09원',
                    style: TextStyle(
                      color: Color(0xFF151916),
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 4),
              Text(
                '▼ 8.31 (−0.61%) · 전일 대비',
                style: TextStyle(
                  color: Color(0xFF2463B5),
                  fontSize: 12,
                  height: 1.5,
                ),
              ),
            ],
          ),
          Text(
            '›',
            style: TextStyle(
              color: Color(0xFF667069),
              fontSize: 32,
              fontWeight: FontWeight.w700,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}
