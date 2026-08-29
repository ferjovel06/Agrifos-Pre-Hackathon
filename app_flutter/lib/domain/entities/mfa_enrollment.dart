class MfaEnrollment {
  const MfaEnrollment({
    required this.factorId,
    required this.qrCode,
    required this.secret,
  });

  final String factorId;
  final String qrCode;
  final String secret;
}
