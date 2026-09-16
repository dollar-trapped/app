import 'api_models.dart';

/// Contract used by presentation code, independent of the HTTP implementation.
abstract interface class DollarRepository {
  Future<AuthSession> signUp({
    required String email,
    required String password,
    required String nickname,
    required String verificationToken,
  });
  Future<void> requestEmailVerification({required String email});
  Future<String> verifyEmail({required String email, required String code});
  Future<AuthSession> logIn({required String email, required String password});
  Future<void> logOut();

  Future<User> getMe();
  Future<User> updateMe({
    String? nickname,
    Object? usdAmount,
    Object? averageExchangeRate,
  });
  Future<void> deleteAccount(String password);

  Future<MessagePage> getMessages({
    int limit = 50,
    String? before,
    String? after,
  });
  Future<ReportReceipt> reportMessage(
    String messageId, {
    required String reason,
    String? description,
  });
  Future<List<BlockedUser>> getBlockedUsers();
  Future<void> blockUser(String userId);
  Future<void> unblockUser(String userId);

  Future<ExchangeRate> getUsdKrwRate();
  Future<ExchangeRateHistory> getUsdKrwHistory(String range);
}
