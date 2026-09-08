/// Runtime API settings. Configure a deployed backend without committing hosts:
/// `flutter run --dart-define=API_BASE_URL=https://api.example.com/api/v1`.
abstract final class ApiConfig {
  static const baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://api.dollar-trapped.example/api/v1',
  );

  static const connectTimeout = Duration(seconds: 10);
  static const receiveTimeout = Duration(seconds: 15);
}
