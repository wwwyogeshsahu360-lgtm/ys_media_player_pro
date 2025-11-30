// lib/shared/services/remote_control_server.dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../../features/cast/domain/remote_player_state.dart';
import 'log_service.dart';

/// Lightweight HTTP server exposing a JSON control API on local network.
///
/// This is **opt-in** and must be toggled from Settings. It is disabled
/// by default and respects user consent.
///
/// Endpoints (all require `X-YS-TOKEN: <token>` header):
///   POST /control/play   { "mediaId": "abc", "startAtMs": 0 }
///   POST /control/pause
///   POST /control/seek   { "positionMs": 120000 }
///   GET  /control/status
///
/// For now these endpoints control a *mock* remote player state, the same
/// state type used by CastManager. You can later plug this into your
/// PlayerController.
class RemoteControlServer {
  RemoteControlServer._internal();

  static final RemoteControlServer instance = RemoteControlServer._internal();

  final LogService _log = LogService.instance;

  HttpServer? _server;
  String _token = _generateToken();
  int _port = 3380;

  RemotePlayerState _state = RemotePlayerState.initial();

  // Callbacks which can be wired to real player later.
  Future<void> Function(String mediaId, Duration? startAt)? onPlay;
  Future<void> Function()? onPause;
  Future<void> Function(Duration position)? onSeek;
  Future<RemotePlayerState> Function()? onStatus;

  String get token => _token;

  int get port => _port;

  bool get isRunning => _server != null;

  Future<void> start({int port = 3380}) async {
    if (_server != null) return;
    _port = port;

    try {
      _server = await HttpServer.bind(InternetAddress.anyIPv4, _port);
      _log.log('[RemoteControlServer] listening on port $_port');

      // ignore: unawaited_futures
      _server!.listen(_handleRequest);
    } catch (e, st) {
      _log.logError('[RemoteControlServer] failed to bind: $e', st);
      _server = null;
    }
  }

  Future<void> stop() async {
    final HttpServer? srv = _server;
    if (srv == null) return;
    await srv.close(force: true);
    _server = null;
    _log.log('[RemoteControlServer] stopped');
  }

  String regenerateToken() {
    _token = _generateToken();
    _log.log('[RemoteControlServer] token regenerated (not logged for safety)');
    return _token;
  }

  static String _generateToken() {
    final int millis = DateTime.now().millisecondsSinceEpoch;
    return millis.toRadixString(36);
  }

  Future<void> _handleRequest(HttpRequest request) async {
    // CORS
    request.response.headers
        .set('Access-Control-Allow-Origin', '*', preserveHeaderCase: true);
    request.response.headers.set('Access-Control-Allow-Methods',
        'GET, POST, OPTIONS',
        preserveHeaderCase: true);
    request.response.headers.set(
        'Access-Control-Allow-Headers', 'Content-Type,X-YS-TOKEN',
        preserveHeaderCase: true);

    if (request.method == 'OPTIONS') {
      await request.response.close();
      return;
    }

    final String providedToken = request.headers.value('X-YS-TOKEN') ?? '';
    if (providedToken.isEmpty || providedToken != _token) {
      request.response.statusCode = HttpStatus.unauthorized;
      request.response.write(jsonEncode(<String, dynamic>{
        'error': 'unauthorized',
        'message': 'Missing or invalid token',
      }));
      await request.response.close();
      return;
    }

    try {
      if (request.method == 'GET' &&
          request.uri.path == '/control/status') {
        await _handleStatus(request);
      } else if (request.method == 'POST' &&
          request.uri.path == '/control/play') {
        await _handlePlay(request);
      } else if (request.method == 'POST' &&
          request.uri.path == '/control/pause') {
        await _handlePause(request);
      } else if (request.method == 'POST' &&
          request.uri.path == '/control/seek') {
        await _handleSeek(request);
      } else {
        request.response.statusCode = HttpStatus.notFound;
        request.response.write(
            jsonEncode(<String, dynamic>{'error': 'not_found'}));
        await request.response.close();
      }
    } catch (e, st) {
      _log.logError('[RemoteControlServer] handler error: $e', st);
      request.response.statusCode = HttpStatus.internalServerError;
      request.response.write(
        jsonEncode(<String, dynamic>{
          'error': 'server_error',
          'message': e.toString(),
        }),
      );
      await request.response.close();
    }
  }

  Future<void> _handleStatus(HttpRequest req) async {
    final RemotePlayerState state =
    onStatus != null ? await onStatus!() : _state;
    req.response.statusCode = HttpStatus.ok;
    req.response.write(jsonEncode(state.toJson()));
    await req.response.close();
  }

  Future<void> _handlePlay(HttpRequest req) async {
    final String body = await utf8.decoder.bind(req).join();
    final Map<String, dynamic> json =
    body.isEmpty ? <String, dynamic>{} : jsonDecode(body);
    final String mediaId = json['mediaId'] as String? ?? '';
    final int startAtMs = json['startAtMs'] as int? ?? 0;
    final Duration startAt = Duration(milliseconds: startAtMs);

    if (onPlay != null && mediaId.isNotEmpty) {
      await onPlay!(mediaId, startAt);
    }
    _state = _state.copyWith(
      isPlaying: true,
      position: startAt,
      mediaId: mediaId,
    );

    req.response.statusCode = HttpStatus.ok;
    req.response.write(jsonEncode(<String, dynamic>{'ok': true}));
    await req.response.close();
  }

  Future<void> _handlePause(HttpRequest req) async {
    if (onPause != null) {
      await onPause!();
    }
    _state = _state.copyWith(isPlaying: false);

    req.response.statusCode = HttpStatus.ok;
    req.response.write(jsonEncode(<String, dynamic>{'ok': true}));
    await req.response.close();
  }

  Future<void> _handleSeek(HttpRequest req) async {
    final String body = await utf8.decoder.bind(req).join();
    final Map<String, dynamic> json =
    body.isEmpty ? <String, dynamic>{} : jsonDecode(body);
    final int positionMs = json['positionMs'] as int? ?? 0;
    final Duration pos = Duration(milliseconds: positionMs);

    if (onSeek != null) {
      await onSeek!(pos);
    }
    _state = _state.copyWith(position: pos);

    req.response.statusCode = HttpStatus.ok;
    req.response.write(jsonEncode(<String, dynamic>{'ok': true}));
    await req.response.close();
  }
}
