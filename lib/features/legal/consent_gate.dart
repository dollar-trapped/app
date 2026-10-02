import 'package:flutter/material.dart';
import '../shared/data/dollar_repository.dart';
import 'consent_versions.dart';
import 'legal_documents.dart';

class ConsentGate extends StatefulWidget {
  const ConsentGate({super.key, required this.repository, required this.child});
  final DollarRepository repository;
  final Widget child;
  @override
  State<ConsentGate> createState() => _ConsentGateState();
}

class _ConsentGateState extends State<ConsentGate> with WidgetsBindingObserver {
  Map<String, dynamic>? _status;
  String? _error;
  bool _busy = false;
  bool _terms = false, _privacy = false;
  bool _required(String key) =>
      (_status?[key] as Map?)?['reagreementRequired'] == true;
  bool get _outdated =>
      (_required('terms') &&
          (_status!['terms'] as Map)['currentVersion'] !=
              bundledTermsVersion) ||
      (_required('privacy') &&
          (_status!['privacy'] as Map)['currentVersion'] !=
              bundledPrivacyVersion);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _load();
  }

  Future<void> _load() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final status = await widget.repository.getTermsAgreements();
      for (final key in ['terms', 'privacy']) {
        if (status[key] is! Map ||
            (status[key] as Map)['reagreementRequired'] is! bool) {
          throw const FormatException('Invalid consent status');
        }
      }
      if (mounted) {
        setState(() {
          _status = status;
          _terms = false;
          _privacy = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _error = '약관 동의 상태를 확인하지 못했습니다. 다시 시도해 주세요.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _agree() async {
    if (_busy ||
        _outdated ||
        (_required('terms') && !_terms) ||
        (_required('privacy') && !_privacy)) {
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      if (_required('terms')) {
        await widget.repository.agreeToDocument('SERVICE', bundledTermsVersion);
      }
      if (_required('privacy')) {
        await widget.repository.agreeToDocument(
          'PRIVACY',
          bundledPrivacyVersion,
        );
      }
    } catch (_) {
      if (mounted) setState(() => _error = '동의를 저장하지 못했습니다. 다시 확인해 주세요.');
      return;
    } finally {
      if (mounted) setState(() => _busy = false);
    }
    if (mounted) await _load();
  }

  @override
  Widget build(BuildContext context) {
    if (_status != null &&
        _error == null &&
        !_required('terms') &&
        !_required('privacy')) {
      return widget.child;
    }
    return Scaffold(
      appBar: AppBar(title: const Text('약관 동의 확인')),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_busy) const LinearProgressIndicator(),
              if (_status != null && _outdated)
                const Text('약관이 변경되었습니다. 앱을 최신 버전으로 업데이트해 주세요.')
              else if (_status != null) ...[
                const Text('서비스 이용을 계속하려면 변경된 필수 문서를 확인하고 동의해 주세요.'),
                if (_required('terms')) ...[
                  TextButton(
                    onPressed: () => openTerms(context),
                    child: const Text('이용약관 보기'),
                  ),
                  CheckboxListTile(
                    title: const Text('[필수] 이용약관 동의'),
                    value: _terms,
                    onChanged: _busy
                        ? null
                        : (value) => setState(() => _terms = value ?? false),
                  ),
                ],
                if (_required('privacy')) ...[
                  TextButton(
                    onPressed: () => openPrivacyPolicy(context),
                    child: const Text('개인정보처리방침 보기'),
                  ),
                  CheckboxListTile(
                    title: const Text('[필수] 개인정보 수집·이용 동의'),
                    value: _privacy,
                    onChanged: _busy
                        ? null
                        : (value) => setState(() => _privacy = value ?? false),
                  ),
                ],
                FilledButton(
                  onPressed:
                      _busy ||
                          (_required('terms') && !_terms) ||
                          (_required('privacy') && !_privacy)
                      ? null
                      : _agree,
                  child: const Text('동의하고 계속하기'),
                ),
              ],
              if (_error != null) Text(_error!),
              if (!_busy)
                TextButton(onPressed: _load, child: const Text('다시 확인')),
            ],
          ),
        ),
      ),
    );
  }
}
