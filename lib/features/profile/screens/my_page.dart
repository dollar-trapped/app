import 'package:dollar_trapped/core/theme/app_colors.dart';
import '../../cosmetics/models/cosmetic_models.dart';
import '../../cosmetics/widgets/server_cosmetic_preview.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/realtime/dollar_socket.dart';
import '../../gacha/screens/cosmetic_gacha_page.dart';
import '../../gacha/screens/cosmetic_items_page.dart';
import '../../cosmetics/preview/nickname_appearance.dart';
import '../../shared/data/api_models.dart';
import '../../shared/data/dollar_repository.dart';
import '../widgets/profile_layout.dart';
import 'profile_edit_page.dart';
import 'settings_page.dart';

class MyPage extends StatefulWidget {
  const MyPage({
    super.key,
    required this.onBack,
    required this.repository,
    this.appearance,
  });

  /// Presentation input for Figma variants; no item is granted or persisted.
  final NicknameAppearance? appearance;
  final VoidCallback onBack;
  final DollarRepository repository;
  @override
  State<MyPage> createState() => _MyPageState();
}

class _MyPageState extends State<MyPage> {
  User? _user;
  CosmeticInventory? _inventory;
  CosmeticItem? _item(String? id) {
    for (final item in _inventory?.items ?? <CosmeticItem>[]) {
      if (item.id == id) return item;
    }
    return null;
  }

  String get _equipmentDescription =>
      widget.appearance?.description ??
      [
        _item(_inventory?.equipment.colorId)?.name ?? '기본 글자색',
        _item(_inventory?.equipment.fontId)?.name ?? '기본 글꼴',
        _item(_inventory?.equipment.backgroundId)?.name ?? '배경 없음',
      ].join(' · ');
  String? _error;
  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() => _error = null);
    try {
      final user = await widget.repository.getMe();
      if (mounted) setState(() => _user = user);
      try {
        final inventory = await widget.repository.getMyCosmetics();
        if (mounted) setState(() => _inventory = inventory);
      } catch (_) {
        /* Account details remain usable if inventory is unavailable. */
      }
    } catch (error) {
      if (mounted) {
        setState(
          () => _error = error is ApiException
              ? error.actionableUserMessage
              : '내 정보를 불러오지 못했어요.',
        );
      }
    }
  }

  Future<void> _edit(ProfileEditSection section) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) =>
            ProfileEditPage(repository: widget.repository, section: section),
      ),
    );
    if (saved == true && mounted) await _loadProfile();
  }

  void _openSettings() {
    final socket = context.read<DollarSocket?>();
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SettingsPage(
          repository: widget.repository,
          email: _user?.email,
          socket: socket,
        ),
      ),
    );
  }

  Future<void> _openItems() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => CosmeticItemsPage(
          nickname: _user?.nickname ?? '닉네임',
          repository: widget.repository,
          holding: _user?.usdAmount,
        ),
      ),
    );
    if (mounted) await _loadProfile();
  }

  Future<void> _openGacha() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => CosmeticGachaPage(
          nickname: _user?.nickname ?? '닉네임',
          repository: widget.repository,
        ),
      ),
    );
    if (mounted) await _loadProfile();
  }

  @override
  Widget build(BuildContext context) => ProfileLayout(
    title: '마이페이지',
    onBack: widget.onBack,
    action: TextButton(
      onPressed: _openSettings,
      style: TextButton.styleFrom(
        minimumSize: const Size(60, 44),
        foregroundColor: AppColors.of(context).muted,
      ),
      child: const Text('설정'),
    ),
    child: SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.of(context).surface,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('내 채팅 이름', style: AppColors.of(context).caption),
                const SizedBox(height: 12),
                if (_error != null)
                  TextButton(
                    onPressed: _loadProfile,
                    child: Text('$_error 다시 시도'),
                  )
                else if (_user == null)
                  const SizedBox(
                    height: 32,
                    width: 32,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else if (widget.appearance == null)
                  ServerCosmeticNickname(
                    nickname: _user!.nickname,
                    size: 24,
                    color: _item(_inventory?.equipment.colorId),
                    font: _item(_inventory?.equipment.fontId),
                    background: _item(_inventory?.equipment.backgroundId),
                  )
                else
                  Text(
                    _user!.nickname,
                    style: AppColors.of(
                      context,
                    ).title.copyWith(color: widget.appearance!.color),
                  ),
                const SizedBox(height: 8),
                Text(
                  _equipmentDescription,
                  style: AppColors.of(context).caption,
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 8,
            children: [
              Text('닉네임 꾸미기', style: _sectionStyle(context)),
              Tooltip(
                triggerMode: TooltipTriggerMode.tap,
                showDuration: const Duration(seconds: 15),
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.symmetric(horizontal: 24),
                message:
                    '중복 아이템은 달러칩으로 돌려드려요.\n'
                    'COMMON 1개 · RARE 3개 · SPECIAL 5개\n'
                    '닉네임 뽑기에서 뽑기권으로 교환할 수 있어요.',
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 48),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _inventory == null
                            ? '달러칩 —'
                            : '달러칩 ${_inventory!.dollarChips}',
                        key: const Key('my-dollar-chip-balance'),
                        style: AppColors.of(
                          context,
                        ).caption.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.info_outline_rounded,
                        size: 16,
                        color: AppColors.of(context).muted,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _MenuGroup(
            children: [
              _CosmeticMenuRow(
                icon: Icons.palette_outlined,
                label: '내 아이템 · 꾸미기',
                subtitle: '모은 아이템 관리',
                onTap: _openItems,
              ),
              _CosmeticMenuRow(
                icon: Icons.auto_awesome_outlined,
                label: '닉네임 뽑기',
                subtitle: '글자색 · 글꼴 · 배경 모으기',
                onTap: _openGacha,
              ),
            ],
          ),
          const SizedBox(height: 28),
          Text('내 계정', style: _sectionStyle(context)),
          const SizedBox(height: 12),
          _MenuGroup(
            children: [
              AccountMenuRow(
                label: '닉네임 수정',
                onTap: () => _edit(ProfileEditSection.nickname),
              ),
              AccountMenuRow(
                label: '내 달러 포지션',
                onTap: () => _edit(ProfileEditSection.position),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

TextStyle _sectionStyle(BuildContext context) => TextStyle(
  fontSize: 14,
  height: 1.5,
  fontWeight: FontWeight.w700,
  color: AppColors.of(context).ink,
);

class _MenuGroup extends StatelessWidget {
  const _MenuGroup({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Container(
    clipBehavior: Clip.antiAlias,
    decoration: BoxDecoration(
      border: Border.all(color: AppColors.of(context).line),
      borderRadius: BorderRadius.circular(16),
    ),
    child: Column(
      children: [
        for (var i = 0; i < children.length; i++) ...[
          if (i > 0)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Divider(height: 1, color: AppColors.of(context).line),
            ),
          children[i],
        ],
      ],
    ),
  );
}

class _CosmeticMenuRow extends StatelessWidget {
  const _CosmeticMenuRow({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });
  final IconData icon;
  final String label, subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: AppColors.of(context).background,
    child: InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.of(context).soft,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppColors.of(context).action, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 15,
                      height: 1.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(subtitle, style: AppColors.of(context).caption),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: AppColors.of(context).muted,
            ),
          ],
        ),
      ),
    ),
  );
}
