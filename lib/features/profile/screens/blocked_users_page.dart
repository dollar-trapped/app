import 'package:dollar_trapped/features/shared/widgets/skeleton.dart';
import 'package:dollar_trapped/core/theme/app_colors.dart';
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
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return Skeleton(
              label: '차단 목록 불러오는 중',
              child: ListView.separated(
                padding: const EdgeInsets.all(24),
                itemCount: 4,
                separatorBuilder: (_, _) => const SizedBox(height: 24),
                itemBuilder: (_, _) => const Row(
                  children: [
                    SkeletonBox(width: 40, height: 40, radius: 20),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SkeletonLine(width: 100, height: 22),
                          SizedBox(height: 8),
                          SkeletonLine(width: 160),
                        ],
                      ),
                    ),
                    SizedBox(width: 12),
                    SkeletonBox(width: 56, height: 36),
                  ],
                ),
              ),
            );
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
            separatorBuilder: (_, _) =>
                Divider(color: AppColors.of(context).line),
            itemBuilder: (context, index) {
              final user = users[index];
              final isUnblocking = _unblockingUserId == user.userId;
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundColor: AppColors.of(context).soft,
                  child: Icon(
                    Icons.person_off_outlined,
                    color: AppColors.of(context).forest,
                  ),
                ),
                title: Text(user.nickname),
                subtitle: Text(
                  '이 사용자의 채팅을 숨기고 있어요.',
                  style: AppColors.of(context).caption,
                ),
                trailing: TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.of(context).action,
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
