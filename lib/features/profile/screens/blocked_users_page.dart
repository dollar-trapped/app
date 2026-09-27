import '../widgets/profile_layout.dart';
import 'package:flutter/material.dart';
import 'package:dollar_trapped/features/shared/data/api_models.dart';
import 'package:dollar_trapped/features/shared/data/dollar_repository.dart';
import 'package:dollar_trapped/core/network/api_exception.dart';

class BlockedUsersPage extends StatefulWidget {
  const BlockedUsersPage({super.key, required this.repository});

  final DollarRepository repository;

  @override
  State<BlockedUsersPage> createState() => _BlockedUsersPageState();
}

class _BlockedUsersPageState extends State<BlockedUsersPage> {
  late Future<List<BlockedUser>> _blockedUsersFuture;
  String? _unblockingUserId;

  @override
  void initState() {
    super.initState();
    _blockedUsersFuture = widget.repository.getBlockedUsers();
  }

  void _reload() {
    setState(() => _blockedUsersFuture = widget.repository.getBlockedUsers());
  }

  Future<void> _unblock(BlockedUser user) async {
    if (_unblockingUserId != null) return;
    setState(() => _unblockingUserId = user.userId);
    try {
      await widget.repository.unblockUser(user.userId);
      if (!mounted) return;
      _reload();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('차단을 해제했어요. 이 사용자의 채팅이 다시 표시돼요.')),
      );
    } on ApiException catch (error) {
      if (mounted && error.actionableUserMessage.isNotEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.actionableUserMessage)));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('차단을 해제하지 못했습니다. 다시 시도해 주세요.')),
        );
      }
    } finally {
      if (mounted) setState(() => _unblockingUserId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ProfileLayout(
      title: '차단 관리',
      child: FutureBuilder<List<BlockedUser>>(
        future: _blockedUsersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: TextButton(
                onPressed: _reload,
                child: const Text('차단 목록을 다시 불러오기'),
              ),
            );
          }
          final users = snapshot.data ?? const <BlockedUser>[];
          if (users.isEmpty) {
            return const Center(child: Text('차단한 사용자가 없습니다.'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(24),
            itemCount: users.length,
            separatorBuilder: (_, _) => const Divider(color: Color(0xFFE1E6E2)),
            itemBuilder: (context, index) {
              final user = users[index];
              final isUnblocking = _unblockingUserId == user.userId;
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const CircleAvatar(
                  backgroundColor: ProfileStyle.soft,
                  child: Icon(
                    Icons.person_off_outlined,
                    color: ProfileStyle.forest,
                  ),
                ),
                title: Text(user.nickname),
                subtitle: const Text(
                  '이 사용자의 채팅을 숨기고 있어요.',
                  style: ProfileStyle.caption,
                ),
                trailing: TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: ProfileStyle.action,
                  ),
                  onPressed: _unblockingUserId != null
                      ? null
                      : () => _unblock(user),
                  child: Text(isUnblocking ? '해제 중...' : '차단 해제'),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
