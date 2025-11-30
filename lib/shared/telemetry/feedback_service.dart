// lib/shared/telemetry/feedback_service.dart
import 'dart:async';

import '../services/consent_service.dart';
import '../services/log_service.dart';
import 'logs_bundle.dart';
import 'telemetry_service.dart';

/// Simple in-memory feedback entry used only for debug UI.
class FeedbackEntry {
  FeedbackEntry({
    required this.message,
    required this.createdAt,
    this.userEmail,
    this.includeDiagnostics = false,
  });

  final String message;
  final DateTime createdAt;
  final String? userEmail;
  final bool includeDiagnostics;
}

/// FeedbackService
/// ===============
/// Handles in-app feedback submission.
class FeedbackService {
  FeedbackService._internal();

  static final FeedbackService instance = FeedbackService._internal();

  final LogService _log = LogService.instance;

  // Stored only in memory; good enough for debug UI.
  final List<FeedbackEntry> _entries = <FeedbackEntry>[];

  Future<void> submitFeedback({
    required String message,
    String? userEmail,
    bool includeDiagnostics = false,
  }) async {
    final ConsentService consent = ConsentService.instance;
    await consent.init();

    Map<String, dynamic> diagnostics = <String, dynamic>{};

    if (includeDiagnostics && consent.shareDiagnostics) {
      final LogsBundle bundle = await LogsBundle.collect();
      diagnostics = <String, dynamic>{
        'logLines': bundle.logLines,
        'logText': bundle.logText,
        'telemetryCount': bundle.telemetryCount,
      };
    }

    final FeedbackEntry entry = FeedbackEntry(
      message: message.trim(),
      createdAt: DateTime.now(),
      userEmail: userEmail,
      includeDiagnostics: includeDiagnostics && consent.shareDiagnostics,
    );
    _entries.add(entry);

    _log.log('[Feedback] User feedback submitted: "${message.trim()}"');

    // Also track via telemetry
    await TelemetryService.instance.trackEvent(
      'feedback_submitted',
      <String, dynamic>{
        'hasEmail': userEmail != null && userEmail.trim().isNotEmpty,
        'hasDiagnostics': includeDiagnostics && consent.shareDiagnostics,
        'diagnosticsIncluded': diagnostics.isNotEmpty,
      },
    );

    // In real app: upload to backend. Here we only log.
  }

  /// Used by debug page to display all collected feedback entries.
  Future<List<FeedbackEntry>> readAll() async =>
      List<FeedbackEntry>.unmodifiable(_entries);
}
