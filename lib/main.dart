import 'package:finance_app/app.dart';
import 'package:finance_app/core/errors/crash_reporting_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';

void main() {
  final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();

  // Preserve native cold-boot splash screen while initial engines and services initialize
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  // Initialize Crashlytics & Sentry error reporting with PII/financial data scrubber
  CrashReportingService.instance.initialize();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF0A0F1D),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  runApp(const FinanceApp());
}
