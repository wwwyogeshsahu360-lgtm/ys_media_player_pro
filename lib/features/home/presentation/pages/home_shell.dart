import 'package:flutter/material.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/utils/layout_utils.dart';
import '../../../../shared/controllers/library_controller.dart';
import '../../../videos/presentation/pages/videos_tab.dart';
import '../../../folders/presentation/pages/folders_tab.dart';
import '../../../playlists/presentation/pages/playlists_tab.dart';
import '../../../settings/presentation/pages/settings_tab.dart';

/// features/home
/// =============
/// HomeShell is the primary application shell with a Material 3
/// NavigationBar and 4 main tabs:
/// - Videos
/// - Folders
/// - Playlists
/// - Settings
///
/// It also owns a shared LibraryController instance so that tabs can
/// consume a unified media library state.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  late final LibraryController _libraryController;

  int _currentIndex = 0;
  late final List<Widget> _tabs;

  @override
  void initState() {
    super.initState();
    _libraryController = LibraryController();
    _tabs = <Widget>[
      VideosTab(controller: _libraryController),
      FoldersTab(controller: _libraryController),
      const PlaylistsTab(),
      const SettingsTab(),
    ];

    // Initial load of the media library.
    _libraryController.refresh();
  }

  @override
  void dispose() {
    _libraryController.dispose();
    super.dispose();
  }

  void _onDestinationSelected(int index) {
    if (_currentIndex == index) return;
    setState(() {
      _currentIndex = index;
    });
  }

  String _currentTitle(AppLocalizations l10n) {
    switch (_currentIndex) {
      case 0:
        return l10n.tabVideos;
      case 1:
        return l10n.tabFolders;
      case 2:
        return l10n.tabPlaylists;
      case 3:
        return l10n.tabSettings;
      default:
        return AppConstants.appName;
    }
  }

  List<Widget> _buildActions() {
    // For now, we only expose a manual refresh/rescan button on
    // Videos and Folders tabs.
    if (_currentIndex == 0 || _currentIndex == 1) {
      return <Widget>[
        IconButton(
          icon: const Icon(Icons.refresh),
          tooltip: 'Rescan media',
          onPressed: () {
            _libraryController.refreshFromDevice();
          },
        ),
      ];
    }
    return const <Widget>[];
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;
    final AppLocalizations l10n = AppLocalizations.of(context);

    final bool isTablet = LayoutUtils.isTablet(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _currentTitle(l10n),
          semanticsLabel: _currentTitle(l10n),
        ),
        actions: _buildActions(),
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: _tabs,
      ),
      bottomNavigationBar: NavigationBarTheme(
        data: NavigationBarThemeData(
          indicatorColor: colorScheme.primary.withValues(alpha:0.15),
          labelTextStyle:
          WidgetStateProperty.resolveWith<TextStyle?>((states) {
            final bool isSelected =
            states.contains(WidgetState.selected);
            final TextStyle? base = theme.textTheme.labelMedium;
            if (base == null) return null;
            return base.copyWith(
              fontWeight:
              isSelected ? FontWeight.w600 : FontWeight.w400,
            );
          }),
        ),
        child: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: _onDestinationSelected,
          destinations: <NavigationDestination>[
            NavigationDestination(
              icon: const Icon(Icons.video_library_outlined),
              selectedIcon:
              const Icon(Icons.video_library_rounded),
              label: l10n.tabVideos,
            ),
            NavigationDestination(
              icon: const Icon(Icons.folder_outlined),
              selectedIcon: const Icon(Icons.folder_rounded),
              label: l10n.tabFolders,
            ),
            NavigationDestination(
              icon: const Icon(Icons.playlist_play_outlined),
              selectedIcon:
              const Icon(Icons.playlist_play_rounded),
              label: l10n.tabPlaylists,
            ),
            NavigationDestination(
              icon: const Icon(Icons.settings_outlined),
              selectedIcon:
              const Icon(Icons.settings_rounded),
              label: l10n.tabSettings,
            ),
          ],
        ),
      ),
    );
  }
}
