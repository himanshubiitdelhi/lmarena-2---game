import 'dart:async';
import 'dart:ui' show PlatformDispatcher;

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

class FirebaseBootstrap {
  FirebaseBootstrap._();

  static bool initialized = false;

  static Future<bool> initializeSafely() async {
    if (Firebase.apps.isNotEmpty) {
      initialized = true;
      return true;
    }
    try {
      // Native Google Services files make the no-options initialization work.
      // Without them Firebase throws here; the game remains fully offline-playable.
      await Firebase.initializeApp();
      initialized = Firebase.apps.isNotEmpty;
    } catch (_) {
      initialized = false;
    }
    return initialized;
  }
}

class AnalyticsService {
  bool _enabled = false;

  void setEnabled(bool enabled) {
    _enabled = enabled && FirebaseBootstrap.initialized;
    if (FirebaseBootstrap.initialized) {
      unawaited(FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(_enabled).catchError((Object _) {}));
    }
  }

  Future<void> log(String name, [Map<String, Object>? parameters]) async {
    if (!_enabled) return;
    try {
      await FirebaseAnalytics.instance.logEvent(name: name, parameters: parameters);
    } catch (_) {
      // Analytics is optional and must not affect a local run.
    }
  }

  Future<void> runStarted({required bool daily, required int runNumber}) => log(
        'run_start',
        <String, Object>{'daily': daily ? 1 : 0, 'run_number': runNumber},
      );

  Future<void> runEnded({
    required int score,
    required Duration duration,
    required String cause,
    required bool daily,
  }) => log(
        'run_end',
        <String, Object>{
          'score': score,
          'duration_seconds': duration.inSeconds,
          'cause': cause,
          'daily': daily ? 1 : 0,
        },
      );
}

class CrashReportingService {
  bool _enabled = false;

  Future<void> initialize({required bool enabled}) async {
    await setEnabled(enabled);
    FlutterError.onError = (FlutterErrorDetails details) {
      if (_enabled) {
        unawaited(_recordFlutter(details));
      } else {
        FlutterError.presentError(details);
      }
    };
    PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
      if (_enabled) {
        unawaited(_record(error, stack, fatal: true));
      }
      return false;
    };
  }

  Future<void> setEnabled(bool enabled) async {
    _enabled = enabled && FirebaseBootstrap.initialized;
    if (!FirebaseBootstrap.initialized) return;
    try {
      await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(_enabled);
    } catch (_) {
      _enabled = false;
    }
  }

  Future<void> _recordFlutter(FlutterErrorDetails details) async {
    try {
      await FirebaseCrashlytics.instance.recordFlutterFatalError(details);
    } catch (_) {
      FlutterError.presentError(details);
    }
  }

  Future<void> _record(Object error, StackTrace stack, {required bool fatal}) async {
    try {
      await FirebaseCrashlytics.instance.recordError(error, stack, fatal: fatal);
    } catch (_) {
      // If Firebase is not configured, defer to the platform's default handler.
    }
  }
}
