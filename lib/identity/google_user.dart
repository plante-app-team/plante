class GoogleUser {
  final String name;
  final String email;
  final String accessToken;
  final DateTime whenObtainedUtc;
  GoogleUser(this.name, this.email, this.accessToken, this.whenObtainedUtc);
}
