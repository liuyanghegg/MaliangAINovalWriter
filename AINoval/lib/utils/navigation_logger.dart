import 'package:flutter/material.dart';
import 'package:ainoval/utils/logger.dart';

class NavigationLogger extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    AppLogger.i('NavigationLogger',
        'Pushed route: ${route.settings.name} | from: ${previousRoute?.settings.name}');
    _logRouteDetails(route);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    AppLogger.w('NavigationLogger',
        'Popped route: ${route.settings.name} | to: ${previousRoute?.settings.name}');
    _logRouteDetails(route);
    // Log the stack trace to find the trigger
    AppLogger.d('NavigationLogger', 'Pop stack trace: \n${StackTrace.current}');
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    AppLogger.i('NavigationLogger',
        'Removed route: ${route.settings.name} | previous: ${previousRoute?.settings.name}');
    _logRouteDetails(route);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    AppLogger.i('NavigationLogger',
        'Replaced route: ${oldRoute?.settings.name} with ${newRoute?.settings.name}');
    if (newRoute != null) _logRouteDetails(newRoute);
  }

  void _logRouteDetails(Route<dynamic> route) {
    String widgetType = "Unknown";
    if (route is MaterialPageRoute) {
      widgetType = route.builder.toString();
    } else if (route is PageRoute) {
      widgetType = route.toString();
    }
    AppLogger.d('NavigationLogger',
        'Route details: name=${route.settings.name}, arguments=${route.settings.arguments}, widget=${widgetType}');
  }
} 