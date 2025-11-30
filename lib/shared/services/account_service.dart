// lib/shared/services/account_service.dart
import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

import 'log_service.dart';

/// Very small mock "account" service used by cloud sync.
///
/// There is NO real authentication. We just generate a random user id on
/// "sign in" and keep it in local prefs.
class AccountService {
  AccountService._internal();

  static final AccountService instance = AccountService._internal();

  final LogService _log = LogService.instance;

  static const String _kUserIdKey = 'ys_account_user_id';
  static const String _kEmailKey = 'ys_account_email';

  String? _userId;
  String? _email;

  String? get userId => _userId;

  String? get email => _email;

  bool get isSignedIn => _userId != null;

  Future<void> load() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    _userId = prefs.getString(_kUserIdKey);
    _email = prefs.getString(_kEmailKey);
  }

  Future<void> signInAnonymously() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String id =
        'user_${Random().nextInt(1 << 32).toRadixString(16).padLeft(8, '0')}';
    _userId = id;
    _email = null;
    await prefs.setString(_kUserIdKey, id);
    await prefs.remove(_kEmailKey);
    _log.log('[AccountService] signed in with mock id=$id');
  }

  Future<void> signOut() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kUserIdKey);
    await prefs.remove(_kEmailKey);
    _log.log('[AccountService] signed out');
    _userId = null;
    _email = null;
  }
}
