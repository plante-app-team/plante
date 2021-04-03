import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:untitled_vegan_app/ui/base/stepper/stepper_page.dart';

abstract class PageControllerBase {
  StepperPage build(BuildContext context);
}
