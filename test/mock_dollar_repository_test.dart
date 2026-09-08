import 'package:flutter_test/flutter_test.dart';

import 'package:dollar_trapped/features/shared/data/mock_dollar_repository.dart';

void main() {
  test('keeps user and block-list updates in memory', () async {
    final repository = MockDollarRepository(
      now: DateTime.utc(2026, 9, 8, 9, 18),
    );

    await repository.signUp(
      email: 'new@example.com',
      password: 'password123',
      nickname: '새달러',
    );
    final user = await repository.updateMe(nickname: '파란달러');
    await repository.blockUser('user-2');

    expect(user.email, 'new@example.com');
    expect(user.nickname, '파란달러');
    expect((await repository.getBlockedUsers()).single.userId, 'user-2');
    expect((await repository.getUsdKrwRate()).rate, '1346.09');
  });
}
