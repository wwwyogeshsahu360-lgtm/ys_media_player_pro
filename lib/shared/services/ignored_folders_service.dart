import 'package:shared_preferences/shared_preferences.dart';

/// IgnoredFoldersService
/// ======================
/// Simple local storage for a set of ignored folder paths.
/// Used by FoldersTab (and can be used by other layers in future).
class IgnoredFoldersService {
  IgnoredFoldersService._internal();

  static final IgnoredFoldersService instance =
  IgnoredFoldersService._internal();

  static const String _prefsKey = 'ys_ignored_folder_paths';

  Set<String> _cached = <String>{};
  bool _loaded = false;

  /// Loads ignored folder paths from SharedPreferences (cached after first call).
  Future<Set<String>> loadIgnoredFolders() async {
    if (_loaded) return _cached;

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final List<String>? stored = prefs.getStringList(_prefsKey);
    _cached = stored == null ? <String>{} : stored.toSet();
    _loaded = true;
    return _cached;
  }

  /// Returns the current in-memory ignored folders set, loading it if needed.
  Future<Set<String>> getIgnoredFolders() async {
    if (!_loaded) {
      await loadIgnoredFolders();
    }
    return _cached;
  }

  /// Adds a folder path to the ignored list.
  Future<void> addIgnoredFolder(String path) async {
    if (path.isEmpty) return;
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await loadIgnoredFolders();
    _cached.add(path);
    await prefs.setStringList(_prefsKey, _cached.toList(growable: false));
  }

  /// Removes a folder path from the ignored list.
  Future<void> removeIgnoredFolder(String path) async {
    if (path.isEmpty) return;
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await loadIgnoredFolders();
    _cached.remove(path);
    await prefs.setStringList(_prefsKey, _cached.toList(growable: false));
  }

  /// Clears the ignored folders list.
  Future<void> clearIgnoredFolders() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    _cached.clear();
    await prefs.remove(_prefsKey);
  }
}
