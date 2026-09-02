import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:socket_io_client/socket_io_client.dart' as socket_io;
import '../utils/api_constants.dart';
import '../utils/app_logger.dart';

class SocketService extends GetxService with WidgetsBindingObserver {
  socket_io.Socket? _socket;
  String _currentUserId = '';
  
  // Expose the raw socket if needed, though we should prefer emit/on methods
  socket_io.Socket? get socket => _socket;

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    disconnect();
    super.onClose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (_socket != null && _socket!.disconnected) {
        AppLogger.i('App resumed, forcing socket reconnect...', tag: 'SOCKET_SVC');
        _socket!.connect();
      }
    }
  }

  final Map<String, List<dynamic Function(dynamic)>> _eventListeners = {};

  Future<void> connect(String userId) async {
    if (userId.isEmpty) return;
    
    // If already connected with the same user, do nothing
    if (_socket != null && _socket!.connected && _currentUserId == userId) {
      debugPrint('⚡ [SocketService] Already connected for user: $userId');
      return;
    }

    _currentUserId = userId;
    
    String? token;
    try {
      final prefs = await SharedPreferences.getInstance();
      token = prefs.getString(ApiConstants.authTokenKey);
    } catch (e) {
      debugPrint('⚡ [SocketService] Could not retrieve token: $e');
    }

    // Disconnect existing if any
    if (_socket != null) {
      _socket!.disconnect();
      _socket!.dispose();
    }

    debugPrint('⚡ [SocketService] Initializing connection for: $userId');

    _socket = socket_io.io(
      ApiConstants.serverBaseUrl,
      socket_io.OptionBuilder()
          .setTransports(['websocket', 'polling'])
          .enableReconnection()
          .setReconnectionDelay(1000)
          .setReconnectionDelayMax(5000)
          .disableAutoConnect()
          .setQuery({
            'userId': _currentUserId,
            'token': ?token,
          })
          .setAuth({
            'token': ?token,
          })
          .build(),
    );

    _socket!.onConnect((_) {
      debugPrint('✅ [SocketService] Connected via: ${_socket!.io.engine?.transport?.name}');
      if (_currentUserId.isNotEmpty) {
        _socket!.emit(ApiConstants.socketJoinUserRoom, _currentUserId);
      }
    });

    _socket!.onDisconnect((_) {
      AppLogger.w('Socket.IO Globally Disconnected', tag: 'SOCKET_SVC');
    });

    _socket!.onConnectError((err) {
      AppLogger.e('Socket.IO Connect Error: $err', null, null, 'SOCKET_SVC');
    });

    // Reattach all previously registered listeners to the new socket instance
    _eventListeners.forEach((event, handlers) {
      for (var handler in handlers) {
        _socket!.on(event, handler);
      }
    });

    _socket!.connect();
  }

  void disconnect() {
    if (_socket != null) {
      AppLogger.i('Disconnecting Socket.IO', tag: 'SOCKET_SVC');
      _socket!.disconnect();
      _socket!.dispose();
      _socket = null;
    }
    _currentUserId = '';
    // Optional: whether to clear listeners on disconnect. Usually better not to, 
    // so if they log back in, the listeners (like ChatController) still work.
  }

  // Wrapper for socket.on
  void on(String event, dynamic Function(dynamic) handler) {
    if (!_eventListeners.containsKey(event)) {
      _eventListeners[event] = [];
    }
    _eventListeners[event]!.add(handler);
    _socket?.on(event, handler);
  }

  // Wrapper for socket.off
  void off(String event, [dynamic Function(dynamic)? handler]) {
    if (handler != null) {
      _eventListeners[event]?.remove(handler);
      _socket?.off(event, handler);
    } else {
      _eventListeners.remove(event);
      _socket?.off(event);
    }
  }

  // Wrapper for socket.emit
  void emit(String event, [dynamic data]) {
    // Force connect if disconnected when trying to emit
    if (_socket?.connected == false) {
      _socket?.connect();
    }
    _socket?.emit(event, data);
  }
}
