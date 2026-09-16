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
    setState(() => _unblockingUserId = user.userId);
    try {
      await widget.repository.unblockUser(user.userId);
      _reload();
    } on ApiException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.userMessage)));
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
    return Scaffold(
      appBar: AppBar(title: const Text('차단 관리')),
      body: FutureBuilder<List<BlockedUser>>(
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
            separatorBuilder: (_, _) => const Divider(),
            itemBuilder: (context, index) {
              final user = users[index];
              final isUnblocking = _unblockingUserId == user.userId;
              return ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(user.nickname),
                trailing: TextButton(
                  onPressed: isUnblocking ? null : () => _unblock(user),
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
