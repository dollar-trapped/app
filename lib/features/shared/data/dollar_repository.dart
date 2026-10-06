import '../../gacha/data/wish_ticket_models.dart';
import '../../inventory/data/cosmetic_inventory_repository.dart';
import '../../gacha/data/gacha_models.dart';
import 'api_models.dart';

/// Contract used by presentation code, independent of the HTTP implementation.
abstract interface class DollarRepository
    implements CosmeticInventoryRepository {
  Future<Map<String, dynamic>> getTermsVersions();
  Future<Map<String, dynamic>> getTermsAgreements();
  Future<void> agreeToDocument(String document, String version);
  Future<AuthSession> signUp({
    required String email,
    required String password,
    required String nickname,
    required String verificationToken,
    required String termsVersion,
    required String privacyVersion,
  });
  Future<void> requestEmailVerification({required String email});
  Future<String> verifyEmail({required String email, required String code});
  Future<AuthSession> logIn({required String email, required String password});
  Future<void> logOut();
  Future<void> requestPasswordReset(String email);
  Future<String> verifyPasswordReset(String email, String code);
  Future<void> resetPassword(String token, String password);
  Future<CosmeticCatalog> getCosmeticCatalog();
  Future<WishTicketState> getWishTickets();
  Future<WishTicketReceipt> exchangeWishTicket(String operationId);
  Future<WishTicketReceipt> redeemWishTicket(
    String operationId,
    String cosmeticId,
  );
  Future<ChipExchange> exchangeChips(String operationId);
  Future<CosmeticDraw> drawCosmetic(String requestId);
  Future<CosmeticBatchDraw> drawCosmeticBatch(String requestId);
  Future<AdRewardSession> createAdRewardSession(String requestId);
  Future<AdRewardSession> getAdRewardSession(String sessionId);

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
