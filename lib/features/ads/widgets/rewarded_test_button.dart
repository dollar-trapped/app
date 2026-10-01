import '../../gacha/widgets/ticket_reward_dialog.dart';
import '../../shared/data/dollar_repository.dart';
import '../../gacha/services/ad_reward_session_service.dart';
import '../../../core/network/api_exception.dart';
import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/ads/rewarded_ad_service.dart';
import '../../../core/ads/ad_config.dart';

class RewardedTestButton extends StatefulWidget {
  const RewardedTestButton({
    super.key,
    this.repository,
    this.onVerified,
    this.enabled = true,
  });
  final bool enabled;
  final DollarRepository? repository;
  final VoidCallback? onVerified;

  @override
  State<RewardedTestButton> createState() => _RewardedTestButtonState();
}

class _RewardedTestButtonState extends State<RewardedTestButton> {
  final _service = RewardedAdService();
  AdRewardSessionService? _rewards;
  bool _busy = false;
  String? _message;

  @override
  void initState() {
    super.initState();
    if (!AdConfig.isTest && widget.repository != null) {
      _rewards = AdRewardSessionService(widget.repository!);
    }
    if (AdConfig.rewardedEnabled) unawaited(_service.preload());
  }

  @override
  void dispose() {
    _rewards?.dispose();
    _service.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    try {
      final granted = await _rewards!.verify();
      if (!mounted) return;
      setState(
        () => _message = granted
            ? null
            : _rewards!.session == null
            ? '보상 확인 기간이 만료됐어요. 다시 시도해 주세요.'
            : '광고 시청은 완료됐어요. 서버에서 보상을 확인 중입니다. 잠시 후 다시 확인해 주세요.',
      );
      if (granted) {
        await showTicketReward(context);
        if (mounted) widget.onVerified?.call();
      }
    } catch (e) {
      if (mounted) {
        setState(
          () => _message = e is ApiException
              ? e.actionableUserMessage
              : '서버에 연결하지 못했어요. 광고를 다시 보지 않고 보상 확인을 재시도할 수 있어요.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _watch() async {
    if (_busy) return;
    if (_rewards == null) {
      if (!AdConfig.isTest) {
        setState(() => _message = '보상 서비스를 준비하지 못했어요. 화면을 다시 열어 주세요.');
        return;
      }
      setState(() => _message = null);
      await _service.show(
        onClosed: (earned) {
          if (!mounted) return;
          setState(
            () => _message = earned
                ? '테스트 광고 시청을 완료했어요. 뽑기권은 지급되지 않습니다.'
                : '테스트 광고 시청이 완료되지 않았어요.',
          );
        },
      );
      return;
    }
    setState(() {
      _busy = true;
      _message = null;
    });
    if (_rewards!.session != null) {
      await _verify();
      return;
    }
    if (_service.status != RewardedStatus.ready) {
      await _service.preload();
      if (mounted) setState(() => _busy = false);
      return;
    }
    try {
      final session = await _rewards!.create();
      if (!mounted) return;
      if (session == null) {
        setState(() => _busy = false);
        return;
      }
      if (session.status != 'PENDING' ||
          !session.expiresAt.isAfter(DateTime.now())) {
        await _verify();
        return;
      }
      await _service.show(
        customData: session.customData,
        onClosed: (earned) {
          if (!mounted) return;
          if (earned) {
            unawaited(_verify());
          } else {
            _rewards!.abandon();
            setState(() {
              _busy = false;
              _message = '광고 시청이 완료되지 않았어요.';
            });
          }
        },
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _busy = false;
          _message = e is ApiException
              ? e.actionableUserMessage
              : '광고 보상 세션을 준비하지 못했어요. 다시 시도해 주세요.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: _service,
    builder: (context, _) {
      final status = _service.status;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              foregroundColor: const Color(0xFF151916),
              backgroundColor: Colors.white,
              side: const BorderSide(color: Color(0xFFE1E6E2)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              textStyle: const TextStyle(
                fontFamily: 'Noto Sans KR',
                fontSize: 16,
                height: 1.5,
                fontWeight: FontWeight.w700,
              ),
            ),
            onPressed:
                !widget.enabled ||
                    !AdConfig.rewardedEnabled ||
                    _busy ||
                    (_rewards?.session == null &&
                        status == RewardedStatus.loading) ||
                    status == RewardedStatus.showing
                ? null
                : () => unawaited(_watch()),
            child: Text(
              !AdConfig.rewardedEnabled
                  ? '보상형 광고 준비 중'
                  : status == RewardedStatus.showing
                  ? (AdConfig.isTest ? '테스트 광고 표시 중…' : '광고 표시 중…')
                  : _busy
                  ? (_rewards?.busy == true ? '서버 보상 확인 중…' : '광고 준비 중…')
                  : _rewards?.session != null
                  ? '보상 다시 확인'
                  : switch (status) {
                      RewardedStatus.loading =>
                        AdConfig.isTest ? '테스트 광고 준비 중…' : '광고 준비 중…',
                      RewardedStatus.showing =>
                        AdConfig.isTest ? '테스트 광고 표시 중…' : '광고 표시 중…',
                      RewardedStatus.failed => '광고 로드 실패 · 다시 준비하기',
                      _ =>
                        AdConfig.isTest
                            ? '▷  테스트 광고 보기 · 보상 없음'
                            : '▷  광고 보고 뽑기권 받기',
                    },
            ),
          ),
          if (const bool.fromEnvironment('AD_REWARD_DIAGNOSTICS'))
            if (_rewards != null)
              ListenableBuilder(
                listenable: _rewards!,
                builder: (context, _) => ExpansionTile(
                  title: const Text('광고 보상 진단'),
                  children: [
                    const Padding(
                      padding: EdgeInsets.all(8),
                      child: Text(
                        '앱이 받은 세션 응답의 주요 필드입니다. Google → 서버 SSV 콜백 원문은 서버 로그에서 확인해야 합니다.',
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: SelectableText(_rewards!.diagnosticText),
                    ),
                  ],
                ),
              )
            else
              const Text(
                '광고 보상 진단: 테스트 광고 모드에서는 서버 보상 세션을 만들지 않습니다. 릴리스 모드로 실행해 주세요.',
              ),
          if (_message?.isNotEmpty == true)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(_message!),
            ),
        ],
      );
    },
  );
}
