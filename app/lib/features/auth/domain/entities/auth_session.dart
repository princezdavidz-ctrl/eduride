class AuthSession {
  const AuthSession({
    required this.accessToken,
    required this.userId,
    required this.expiresAt,
    this.isDemoSession = false,
  });

  final String accessToken;
  final String userId;
  final DateTime expiresAt;
  final bool isDemoSession;

  bool get isExpired => DateTime.now().isAfter(expiresAt);
}
