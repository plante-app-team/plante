import 'package:equatable/equatable.dart';

class GoogleUser extends Equatable {
  final String name;
  final String email;
  final String accessToken;
  final DateTime whenObtainedUtc;
  GoogleUser(this.name, this.email, this.accessToken, this.whenObtainedUtc);

  @override
  List<Object?> get props => [name, email, accessToken, whenObtainedUtc];
}
