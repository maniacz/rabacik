import 'package:flutter/material.dart';
import 'main.dart';

class LoggingRouteAware extends RouteAware {
  final String screenName;
  LoggingRouteAware(this.screenName);

  @override
  void didPush() {
    print('************* Route PUSH: $screenName');
  }

  @override
  void didPop() {
    print('************* Route POP: $screenName');
  }

  @override
  void didPopNext() {
    print('************* Route POP NEXT: $screenName');
  }

  @override
  void didPushNext() {
    print('************* Route PUSH NEXT: $screenName');
  }
}