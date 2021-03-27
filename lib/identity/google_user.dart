class GoogleUser {
  final String name;
  final String email;
  final String idToken;
  final DateTime whenObtainedUtc;
  GoogleUser(this.name, this.email, this.idToken, this.whenObtainedUtc);
}
