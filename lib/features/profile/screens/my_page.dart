import '../../gacha/data/cosmetic_models.dart';
import '../../gacha/widgets/server_cosmetic_preview.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/realtime/dollar_socket.dart';
import '../../gacha/screens/cosmetic_gacha_page.dart';
import '../../gacha/screens/cosmetic_items_page.dart';
import '../../gacha/widgets/nickname_appearance.dart';
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
              ? error.userMessage
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

  @override
  Widget build(BuildContext context) => ProfileLayout(
    title: '마이페이지',
    onBack: widget.onBack,
    action: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Tooltip(
          triggerMode: TooltipTriggerMode.tap,
          preferBelow: true,
          verticalOffset: 18,
          showDuration: const Duration(seconds: 15),
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.symmetric(horizontal: 16),
          constraints: const BoxConstraints(maxWidth: 300),
          decoration: BoxDecoration(
            color: ProfileStyle.forest,
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [
              BoxShadow(
                color: Color(0x26000000),
                blurRadius: 12,
                offset: Offset(0, 4),
              ),
            ],
          ),
          textStyle: const TextStyle(
            fontSize: 12,
            height: 1.6,
            color: Colors.white,
          ),
          message:
              '중복하면 달러칩으로 돌려드립니다.\n\n'
              'COMMON 중복 → 달러칩 1개\n'
              'RARE 중복 → 달러칩 3개\n'
              'SPECIAL 중복 → 달러칩 5개\n\n'
              '닉네임 뽑기에서 달러칩을 뽑기권으로 교환할 수 있어요.',
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            decoration: BoxDecoration(
              color: ProfileStyle.soft,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _inventory == null ? '달러칩 —' : '달러칩 ${_inventory!.dollarChips}',
              key: const Key('my-dollar-chip-balance'),
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: ProfileStyle.action,
              ),
            ),
          ),
        ),
        SizedBox(
          width: 60,
          height: 44,
          child: TextButton(
            onPressed: _openSettings,
            style: TextButton.styleFrom(
              foregroundColor: ProfileStyle.muted,
              textStyle: const TextStyle(
                fontFamily: 'Noto Sans KR',
                fontSize: 13,
                height: 20 / 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            child: const Text('설정'),
          ),
        ),
      ],
    ),
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: ProfileStyle.soft,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('내 채팅 이름', style: ProfileStyle.caption),
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
                    style: ProfileStyle.title.copyWith(
                      color: widget.appearance!.color,
                    ),
                  ),
                const SizedBox(height: 12),
                Text(_equipmentDescription, style: ProfileStyle.caption),
                const SizedBox(height: 12),
                ProfileSecondaryButton(
                  label: '내 아이템 · 꾸미기',
                  onPressed: () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => CosmeticItemsPage(
                          nickname: _user?.nickname ?? '닉네임',
                          repository: widget.repository,
                          holding: _user?.usdAmount,
                        ),
                      ),
                    );
                    if (mounted) await _loadProfile();
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: ProfileStyle.forest,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '작은 재미, 한 번의 뽑기',
                  style: ProfileStyle.caption.copyWith(
                    color: ProfileStyle.soft,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '오늘은 어떤 이름?',
                  style: ProfileStyle.title.copyWith(color: Colors.white),
                ),
                const SizedBox(height: 12),
                const Text(
                  '글자색 · 글꼴 · 배경을 모아보세요.',
                  style: TextStyle(
                    fontSize: 13,
                    height: 20 / 13,
                    fontWeight: FontWeight.w500,
                    color: ProfileStyle.soft,
                  ),
                ),
                const SizedBox(height: 12),
                ProfileSecondaryButton(
                  label: '닉네임 뽑기  →',
                  onPressed: () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => CosmeticGachaPage(
                          nickname: _user?.nickname ?? '닉네임',
                          repository: widget.repository,
                        ),
                      ),
                    );
                    if (mounted) await _loadProfile();
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          AccountMenuRow(
            label: '닉네임 수정',
            onTap: () => _edit(ProfileEditSection.nickname),
          ),
          const SizedBox(height: 4),
          AccountMenuRow(
            label: '내 달러 포지션',
            onTap: () => _edit(ProfileEditSection.position),
          ),
        ],
      ),
    ),
  );
}
