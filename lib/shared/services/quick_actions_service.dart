// lib/shared/services/quick_actions_service.dart
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:quick_actions/quick_actions.dart';

import 'log_service.dart';

/// QuickActionsService
/// ====================
/// Skeleton wrapper around the `quick_actions` plugin.
/// Day 16 requirement: register actions, handle taps.
/// Currently we **only log** taps to avoid tight coupling with AppRouter.
/// You can later inject navigation at app level.
class QuickActionsService {
  QuickActionsService._internal();

  static final QuickActionsService instance =
  QuickActionsService._internal();

  QuickActions? _quickActions;
  bool _initialized = false;

  /// Initialize quick actions.
  /// Safe no-op on web / unsupported platforms.
  Future<void> init() async {
    if (_initialized) return;

    if (kIsWeb) {
      LogService.instance.log(
        '[QuickActionsService] Skipped init on web',
      );
      _initialized = true;
      return;
    }

    try {
      _quickActions = const QuickActions();

      await _quickActions!.setShortcutItems(<ShortcutItem>[
        const ShortcutItem(
          type: 'open_library',
          localizedTitle: 'Open Library',
          icon: 'ic_shortcut_library', // put under android mipmap if desired
        ),
        const ShortcutItem(
          type: 'open_downloads',
          localizedTitle: 'Open Downloads',
          icon: 'ic_shortcut_downloads',
        ),
        const ShortcutItem(
          type: 'play_recent',
          localizedTitle: 'Play Recent',
          icon: 'ic_shortcut_recent',
        ),
      ]);

      await _quickActions!.initialize(_onQuickActionSelected);

      _initialized = true;
      LogService.instance.log('[QuickActionsService] Initialized');
    } catch (e, st) {
      LogService.instance.logError(
        '[QuickActionsService] init error: $e',
        st,
      );
    }
  }

  /// Handle quick action selection.
  ///
  /// NOTE:
  ///  - Currently we only log the event.
  ///  - App-level code (e.g. in main or a root widget) can listen
  ///    to `lastActionStream` and perform navigation.
  final StreamController<String> _lastActionController =
  StreamController<String>.broadcast();

  Stream<String> get lastActionStream => _lastActionController.stream;

  void _onQuickActionSelected(String type) {
    LogService.instance.log(
      '[QuickActionsService] Quick action selected: $type',
    );
    if (!_lastActionController.isClosed) {
      _lastActionController.add(type);
    }

    // ❗ Navigation is intentionally NOT done here to avoid
    // tight coupling with AppRouter. You can handle this stream
    // at app root and call GoRouter navigation there.
  }

  Future<void> dispose() async {
    await _lastActionController.close();
  }
}
