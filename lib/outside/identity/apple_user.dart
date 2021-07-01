class AppleUser {
  final String? name;
  final String? email;
  final String authorizationCode;
  final DateTime whenObtainedUtc;
  AppleUser(
      this.name, this.email, this.authorizationCode, this.whenObtainedUtc);
}
