import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dollar_trapped/features/legal/consent_gate.dart';
import 'package:dollar_trapped/features/legal/consent_versions.dart';
import 'package:dollar_trapped/features/shared/data/mock_dollar_repository.dart';

class _Repo extends MockDollarRepository {
  String current = bundledTermsVersion;
  final agreed = <String>[];
  @override
  Future<Map<String, dynamic>> getTermsAgreements() async => {
    'terms': {
      'currentVersion': current,
      'reagreementRequired': !agreed.contains('SERVICE'),
    },
    'privacy': {
      'currentVersion': bundledPrivacyVersion,
      'reagreementRequired': !agreed.contains('PRIVACY'),
    },
  };
  @override
  Future<void> agreeToDocument(String document, String version) async {
    expect(version, document == 'SERVICE' ? current : bundledPrivacyVersion);
    agreed.add(document);
  }
}

void main() {
  testWidgets(
    'requires explicit consent to both documents before opening app',
    (tester) async {
      final repo = _Repo();
      await tester.pumpWidget(
        MaterialApp(
          home: ConsentGate(repository: repo, child: const Text('home')),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('home'), findsNothing);
      expect(
        tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNull,
      );
      await tester.tap(find.text('[필수] 이용약관 동의'));
      await tester.pump();
      expect(
        tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNull,
      );
      await tester.tap(find.text('[필수] 개인정보 수집·이용 동의'));
      await tester.pump();
      await tester.tap(find.text('동의하고 계속하기'));
      await tester.pumpAndSettle();
      expect(repo.agreed, ['SERVICE', 'PRIVACY']);
      expect(find.text('home'), findsOneWidget);
    },
  );
  testWidgets('does not submit an unknown document version', (tester) async {
    final repo = _Repo()..current = 'future-version';
    await tester.pumpWidget(
      MaterialApp(
        home: ConsentGate(repository: repo, child: const Text('home')),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('업데이트'), findsOneWidget);
    expect(find.byType(CheckboxListTile), findsNothing);
    expect(repo.agreed, isEmpty);
    expect(find.text('home'), findsNothing);
  });
}
