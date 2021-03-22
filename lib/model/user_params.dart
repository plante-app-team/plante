import 'package:equatable/equatable.dart';
import 'package:untitled_vegan_app/model/gender.dart';

class UserParams extends Equatable {
  final String name;
  final Gender? gender;
  final DateTime? birthday;
  final bool? eatsMilk;
  final bool? eatsEggs;
  final bool? eatsHoney;

  UserParams(
      this.name,
      {
        this.gender,
        this.birthday,
        this.eatsMilk,
        this.eatsEggs,
        this.eatsHoney
      });

  @override
  List<Object?> get props => [name, gender, birthday, eatsMilk, eatsEggs, eatsHoney];
}
