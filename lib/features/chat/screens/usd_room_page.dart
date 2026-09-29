import '../../../core/moderation/moderation_status.dart';
import '../../../core/moderation/moderation_dialog.dart';
import '../widgets/report_message_dialog.dart';
import '../widgets/message_actions_sheet.dart';
import 'package:dollar_trapped/features/chat/widgets/message_list.dart';
import 'package:dollar_trapped/features/chat/widgets/rate_bar.dart';
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
    this.isActive = true,
    this.acknowledgedNotices = const {},
  });

  final Set<String> acknowledgedNotices;
  final bool isActive;
  final VoidCallback onRateBarTap;
  final DollarRepository repository;

  @override
  State<UsdRoomPage> createState() => _UsdRoomPageState();
}

class _UsdRoomPageState extends State<UsdRoomPage>
    with AutomaticKeepAliveClientMixin<UsdRoomPage>, WidgetsBindingObserver {
  @override
  bool get wantKeepAlive => true;

  static const _ink = Color(0xFF151916);
  static const _muted = Color(0xFF667069);
  static const _surface = Color(0xFFF5F7F5);
  static const _line = Color(0xFFE1E6E2);
  static const _action = Color(0xFF008A29);

  final _messageController = TextEditingController();
  final _messageScrollController = ScrollController();
  late Future<MessagePage> _messagesFuture;
  late Future<ExchangeRate> _rateFuture;
  Timer? _rateTimer;
  final _realtimeMessages = <RealtimeMessage>[];
  final _blockedUserIds = <String>{};
  final _hiddenMessageIds = <String>{};
  DollarSocket? _socket;
  StreamSubscription<RealtimeMessage>? _messageSubscription;
  StreamSubscription<DollarSocketState>? _stateSubscription;
  StreamSubscription<String>? _deletionSubscription;
  StreamSubscription<SocketError>? _errorSubscription;
  StreamSubscription<String>? _sendFailureSubscription;
  var _socketState = DollarSocketState.disconnected;
  var _ownsSocket = false;
  String? _currentUserId;
  ModerationNotice? _restriction;
  final _shownNotices = <String>{};
  Timer? _moderationPoll, _banExpiry;
  bool _checkingModeration = false;
  bool get _chatRestricted => _restriction?.blocksChat == true;

  Future<void> _applyNotice(ModerationNotice notice) async {
    if (!mounted || !notice.active) return;
    if (notice.blocksChat) {
      setState(() => _restriction = notice);
      FocusManager.instance.primaryFocus?.unfocus();
      _banExpiry?.cancel();
      if (notice.expiresAt != null) {
        _banExpiry = Timer(
          notice.expiresAt!.difference(DateTime.now()),
          () async {
            await _refreshModeration();
          },
        );
      }
    }
    if (!_shownNotices.add(notice.id)) return;
    if (notice.suspended) {
      _moderationPoll?.cancel();
      final tokens = context.read<TokenStore?>();
      await _socket?.disconnect();
      await tokens?.clear();
      if (!mounted) return;
    }
    await showModerationDialog(context, notice, userId: _currentUserId);
    if (mounted && notice.suspended) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(builder: (_) => const AuthPage()),
        (_) => false,
      );
    }
  }

  Future<void> _refreshModeration() async {
    if (_checkingModeration) return;
    _checkingModeration = true;
    try {
      final user = await widget.repository.getMe();
      if (!mounted) return;
      setState(() {
        _currentUserId = user.id;
        _restriction = null;
      });
      for (final notice in user.moderation.notices) {
        await _applyNotice(notice);
      }
    } on ApiException catch (error) {
      final notice = ModerationNotice.fromError(error);
      if (notice != null) await _applyNotice(notice);
    } catch (_) {
      // Keep any known restriction until the server confirms its removal.
    } finally {
      _checkingModeration = false;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && widget.isActive) {
      _refreshModeration();
      _socket?.retryConnection();
      _reloadRate();
    }
  }

  @override
  void initState() {
    super.initState();
    _rateFuture = widget.repository.getUsdKrwRate();
    _rateTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      if (widget.isActive) _reloadRate();
    });
    _shownNotices.addAll(widget.acknowledgedNotices);
    WidgetsBinding.instance.addObserver(this);
    _refreshModeration();
    _moderationPoll = Timer.periodic(const Duration(seconds: 30), (_) {
      if (widget.isActive) _refreshModeration();
    });
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
    _socketState = socket.state;
    _messageSubscription = socket.messages.listen((message) {
      if (!mounted) return;
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
      final notice = ModerationNotice.fromError(
        ApiException(
          statusCode: 403,
          code: error.code,
          message: error.message,
          details: error.details,
        ),
      );
      if (notice != null) {
        unawaited(_applyNotice(notice));
        return;
      }
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
      final message = ApiException(
        statusCode: null,
        code: error.code,
        message: error.message,
        details: error.details,
      ).actionableUserMessage;
      if (message.isEmpty) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    });
    _sendFailureSubscription = socket.failedMessageIds.listen((_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('메시지 전송에 실패했어요. 다시 시도해 주세요.')),
      );
    });
    socket.connect();
  }

  void _reloadRate() {
    setState(() {
      _rateFuture = widget.repository.getUsdKrwRate();
    });
  }

  Future<void> _refreshRoom() async {
    _reloadRate();
    final messages = widget.repository.getMessages();
    setState(() {
      _messagesFuture = messages;
    });
    await Future.wait([
      // FutureBuilder displays failures and keeps the retry action available.
      messages.then<void>((_) {}, onError: (Object _, StackTrace _) {}),
      _socket?.retryConnection() ?? Future<void>.value(),
      _refreshModeration(),
      _loadModerationContext(),
    ]);
  }

  void _reloadMessages() => unawaited(_refreshRoom());

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
        final freshIds = blockedUsers.map((user) => user.userId).toSet();
        final unblocked = _blockedUserIds.difference(freshIds).isNotEmpty;
        _blockedUserIds
          ..clear()
          ..addAll(freshIds);
        if (unblocked) {
          // The server omits blocked authors from history; fetch them again.
          _messagesFuture = widget.repository.getMessages();
          _realtimeMessages.clear();
        }
      });
    } catch (_) {
      // Chat reading remains available when moderation context cannot load.
    }
  }

  @override
  void didUpdateWidget(covariant UsdRoomPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      _reloadRate();
      _loadModerationContext();
      _refreshModeration();
    }
  }

  Future<void> _moderateMessage({
    required String messageId,
    required String authorId,
  }) async {
    FocusManager.instance.primaryFocus?.unfocus();
    final action = await showModalBottomSheet<MessageAction>(
      context: context,
      backgroundColor: Colors.white,
      showDragHandle: true,
      isScrollControlled: true,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * .85,
      ),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const MessageActionsSheet(),
    );
    if (!mounted || action == null) return;
    if (action == MessageAction.hide) {
      setState(() => _hiddenMessageIds.add(messageId));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('메시지를 숨겼어요.'),
          action: SnackBarAction(
            label: '되돌리기',
            onPressed: () {
              if (mounted) setState(() => _hiddenMessageIds.remove(messageId));
            },
          ),
        ),
      );
    } else if (action == MessageAction.report) {
      await _reportMessage(messageId);
    } else {
      await _blockUser(authorId);
    }
  }

  Future<void> _reportMessage(String messageId) async {
    final input = await showDialog<MessageReportInput>(
      context: context,
      builder: (_) => const ReportMessageDialog(),
    );
    if (!mounted || input == null) return;
    try {
      await widget.repository.reportMessage(
        messageId,
        reason: input.reason,
        description: input.description,
      );
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
          : error.actionableUserMessage;
      if (message.isEmpty) return;
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
    setState(() => _blockedUserIds.add(userId));
    try {
      await widget.repository.blockUser(userId);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('사용자를 차단했습니다.')));
      }
    } catch (_) {
      if (mounted) {
        setState(() => _blockedUserIds.remove(userId));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('차단하지 못했습니다. 다시 시도해 주세요.')),
        );
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _moderationPoll?.cancel();
    _rateTimer?.cancel();
    _banExpiry?.cancel();
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
    if (content.isEmpty || _chatRestricted) return;
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
        return '● 채팅 서버 연결 끊김';
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
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
              child: RefreshIndicator(
                onRefresh: _refreshRoom,
                child: MessageList(
                  future: _messagesFuture,
                  realtimeMessages: _realtimeMessages,
                  blockedUserIds: _blockedUserIds,
                  hiddenMessageIds: _hiddenMessageIds,
                  currentUserId: _currentUserId,
                  scrollController: _messageScrollController,
                  onRetry: _reloadMessages,
                  onModerate: _moderateMessage,
                ),
              ),
            ),
            if (_restriction != null)
              MaterialBanner(
                content: Text(
                  '${_restriction!.title}\n${_restriction!.period}',
                ),
                actions: [
                  TextButton(
                    onPressed: () =>
                        showModerationDialog(context, _restriction!),
                    child: const Text('자세히'),
                  ),
                ],
              ),
            InkWell(
              onTap: widget.onRateBarTap,
              child: RateBar(rateFuture: _rateFuture),
            ),
            Container(
              height: 76,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      enabled: !_chatRestricted,
                      onChanged: (_) => setState(() {}),
                      style: const TextStyle(
                        color: _ink,
                        fontSize: 15,
                        height: 1.6,
                      ),
                      decoration: InputDecoration(
                        hintText: _chatRestricted
                            ? '채팅 이용이 제한되었습니다'
                            : '메시지를 입력하세요',
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
                      onPressed:
                          _chatRestricted ||
                              _messageController.text.trim().isEmpty
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
