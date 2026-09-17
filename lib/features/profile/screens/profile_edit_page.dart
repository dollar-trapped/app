import 'package:flutter/material.dart';
import '../../../core/network/api_exception.dart';
import '../../shared/data/api_models.dart';
import '../../shared/data/dollar_repository.dart';
import '../widgets/info_field.dart';
import '../widgets/profile_layout.dart';

enum ProfileEditSection { nickname, position }

class ProfileEditPage extends StatefulWidget {
  const ProfileEditPage({
    super.key,
    required this.repository,
    required this.section,
  });
  final DollarRepository repository;
  final ProfileEditSection section;
  @override
  State<ProfileEditPage> createState() => _ProfileEditPageState();
}

class _ProfileEditPageState extends State<ProfileEditPage> {
  final _nicknameController = TextEditingController();
  final _holdingController = TextEditingController();
  final _averagePriceController = TextEditingController();
  var _currentRate = 1346.09;
  User? _user;
  String? _errorMessage;
  bool _isLoading = true;
  bool _isSaving = false;
  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final user = await widget.repository.getMe();
      final rate = await widget.repository.getUsdKrwRate();
      if (!mounted) return;
      _nicknameController.text = user.nickname;
      _holdingController.text = user.usdAmount ?? '';
      _averagePriceController.text = user.averageExchangeRate ?? '';
      setState(() {
        _user = user;
        _currentRate = double.tryParse(rate.rate) ?? _currentRate;
      });
    } on ApiException catch (error) {
      if (mounted) setState(() => _errorMessage = error.userMessage);
    } catch (_) {
      if (mounted) setState(() => _errorMessage = '내 정보를 불러오지 못했어요.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveProfile() async {
    if (_user == null || _isSaving) return;
    if (_nicknameController.text.trim().isEmpty) {
      setState(() => _errorMessage = '닉네임을 입력해 주세요.');
      return;
    }
    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });
    try {
      final user = await widget.repository.updateMe(
        nickname: _nicknameController.text.trim(),
        usdAmount: _holdingController.text.replaceAll(',', '').trim().isEmpty
            ? null
            : _holdingController.text.replaceAll(',', '').trim(),
        averageExchangeRate:
            _averagePriceController.text.replaceAll(',', '').trim().isEmpty
            ? null
            : _averagePriceController.text.replaceAll(',', '').trim(),
      );
      if (!mounted) return;
      setState(() => _user = user);
      Navigator.of(context).pop(true);
    } on ApiException catch (error) {
      if (mounted) setState(() => _errorMessage = error.userMessage);
    } catch (_) {
      if (mounted) setState(() => _errorMessage = '변경사항을 저장하지 못했어요.');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    _holdingController.dispose();
    _averagePriceController.dispose();
    super.dispose();
  }

  double? _parseNumber(String value) {
    return double.tryParse(value.replaceAll(',', '').trim());
  }

  String get _positionPreview {
    final nickname = _nicknameController.text.trim().isEmpty
        ? '닉네임'
        : _nicknameController.text.trim();
    final holding = _holdingController.text.trim().isEmpty
        ? '0'
        : _holdingController.text.trim();
    final averagePrice = _parseNumber(_averagePriceController.text);
    final profitRate = averagePrice == null || averagePrice <= 0
        ? null
        : ((_currentRate - averagePrice) / averagePrice) * 100;
    final rateText = profitRate == null
        ? ''
        : ' · ${profitRate >= 0 ? '+' : ''}${profitRate.toStringAsFixed(1)}%';

    return '$nickname  \$$holding$rateText';
  }

  @override
  Widget build(BuildContext context) => ProfileLayout(
    title: widget.section == ProfileEditSection.nickname
        ? '닉네임 수정'
        : '내 달러 포지션',
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else if (_user == null)
            TextButton(
              onPressed: _loadProfile,
              child: Text(_errorMessage ?? '다시 시도'),
            )
          else ...[
            if (widget.section == ProfileEditSection.nickname)
              InfoField(
                label: '닉네임',
                controller: _nicknameController,
                helper: '채팅에 표시되는 이름이에요.',
                onChanged: (_) => setState(() {}),
              )
            else ...[
              const Text(
                '내 달러 포지션 · 선택',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 20),
              InfoField(
                label: '보유량 (USD)',
                controller: _holdingController,
                helper: '보유한 달러 금액',
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 20),
              InfoField(
                label: '평균 매수가 (원)',
                controller: _averagePriceController,
                helper: '1달러당 매수 가격',
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 12),
              const Text(
                '수익률은 평균 매수가와 현재 환율로 계산해요.',
                style: ProfileStyle.caption,
              ),
            ],
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: ProfileStyle.soft,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('채팅에는 이렇게 보여요', style: ProfileStyle.caption),
                  const SizedBox(height: 8),
                  Text(
                    _positionPreview,
                    style: const TextStyle(
                      color: ProfileStyle.action,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(color: Color(0xFFB42318)),
                ),
              ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _isSaving ? null : _saveProfile,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
                backgroundColor: ProfileStyle.action,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(_isSaving ? '저장 중...' : '변경사항 저장'),
            ),
          ],
        ],
      ),
    ),
  );
}
