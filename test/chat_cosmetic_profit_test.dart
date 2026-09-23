import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dollar_trapped/features/chat/widgets/chat_message_bubble.dart';
import 'package:dollar_trapped/features/gacha/data/cosmetic_models.dart';

void main() {
  final cosmetics = MessageCosmetics.fromJson({
    'nameColor': {'id': 'blue', 'color': '#4477CC', 'rarity': 'COMMON'},
    'nameFont': {'id': 'round', 'font': 'rounded_gothic', 'rarity': 'COMMON'},
    'nameBackground': {
      'id': 'gray',
      'background': 'soft_gray',
      'rarity': 'COMMON',
    },
  });
  Widget bubble(String profit, {String holding = r'$1200.00'}) => MaterialApp(
    home: Scaffold(
      body: Center(
        child: SizedBox(
          width: 280,
          child: ChatMessageBubble(
            nickname: '프론트',
            holding: holding,
            profit: profit,
            message: '메시지',
            time: '오전 9:34',
            cosmetics: cosmetics,
          ),
        ),
      ),
    ),
  );

  testWidgets('equipped nickname retains holding and supplied profit', (
    tester,
  ) async {
    await tester.pumpWidget(bubble('-10.10%'));
    expect(find.text(r'$1200.00'), findsOneWidget);
    expect(find.text('-10.10%'), findsOneWidget);
    final nickname = tester.widget<Text>(find.text('프론트'));
    expect(nickname.style!.color, const Color(0xFF4477CC));
    expect(nickname.style!.fontFamily, 'Jua');
    expect(find.text('수익률 —'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('missing profit shows an explanation instead of disappearing', (
    tester,
  ) async {
    await tester.pumpWidget(bubble(''));
    expect(find.text('수익률 —'), findsOneWidget);
    await tester.tap(find.text('수익률 —'));
    await tester.pumpAndSettle();
    expect(find.text('매수환율 또는 현재 환율 정보가 없어 수익률을 확인할 수 없어요.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('authors without holdings have no profit placeholder', (
    tester,
  ) async {
    await tester.pumpWidget(bubble('', holding: ''));
    expect(find.text('수익률 —'), findsNothing);
  });
}
