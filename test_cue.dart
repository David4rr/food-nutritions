import 'package:flutter/material.dart';
import 'package:cue/cue.dart';

class ExpandingRoute<T> extends PageRouteBuilder<T> with CueModalRouteMixin<T> {
  ExpandingRoute() : super(pageBuilder: (c, a, s) => Container());

  @override
  CueMotion get motion => const CueMotion.smooth();
  
  @override
  CueMotion? get reverseMotion => null;
  
  @override
  bool get hideOnPushNext => true;
  
  @override
  AnimationStatusListener? get onAnimationStatusChanged => null;
}
