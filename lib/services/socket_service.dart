import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/app_config.dart';

class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  IO.Socket? _socket;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  bool _isConnected = false;
  bool _isConnecting = false;
  final List<String> _joinedRooms = [];
  Timer? _reconnectTimer;
  Timer? _healthCheckTimer;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 10;
  static const int _initialReconnectDelay = 2; // seconds
  static const int _maxReconnectDelay = 60; // seconds
  bool _shouldReconnect = true;
  DateTime? _lastMessageTime;
  int _authFailureCount = 0;
  static const int _maxAuthFailures = 3;
  DateTime? _lastAuthFailure;
  static const int _authFailureCooldown = 300; // 5 minutes in seconds

  bool get isConnected => _isConnected && _socket?.connected == true;
  bool get isConnecting => _isConnecting;
  IO.Socket? get socket => _socket;

  // Callbacks
  Function(Map<String, dynamic>)? onMessage;
  Function(Map<String, dynamic>)? onMessageNotification;
  Function(Map<String, dynamic>)? onTyping;
  Function(Map<String, dynamic>)? onNotification;

  Future<void> connect({bool forceReconnect = false}) async {
    // Check if we can reconnect (not in auth failure cooldown)
    if (!_canReconnect() && !forceReconnect) {
      debugPrint('⚠️ Cannot connect - in auth failure cooldown or disabled');
      return;
    }
    
    if (_socket != null && _socket!.connected && !forceReconnect) {
      debugPrint('✅ Socket already connected');
      return;
    }

    if (_isConnecting && !forceReconnect) {
      debugPrint('⏳ Socket connection already in progress');
      return;
    }

    // Cancel any existing reconnect timer
    _reconnectTimer?.cancel();
    _reconnectTimer = null;

    _isConnecting = true;

    // Disconnect existing socket if any
    if (_socket != null) {
      try {
        _socket!.disconnect();
        _socket!.dispose();
      } catch (e) {
        debugPrint('Error disposing old socket: $e');
      }
      _socket = null;
    }

    try {
      final token = await _storage.read(key: 'userToken');
      if (token == null || token.isEmpty) {
        debugPrint('⚠️ No token available for socket connection');
        _isConnecting = false;
        _shouldReconnect = false;
        return;
      }

      // Clean token - remove quotes if present
      String cleanToken = token.trim();
      if (cleanToken.startsWith('"') || cleanToken.startsWith("'")) {
        cleanToken = cleanToken.substring(1);
      }
      if (cleanToken.endsWith('"') || cleanToken.endsWith("'")) {
        cleanToken = cleanToken.substring(0, cleanToken.length - 1);
      }

      if (cleanToken.isEmpty) {
        debugPrint('⚠️ Token is empty after cleaning');
        _isConnecting = false;
        _shouldReconnect = false;
        return;
      }

      // Socket.IO server URL (same as API base URL)
      final socketUrl = AppConfig.socketUrl;

      debugPrint('🔌 Connecting to socket server: $socketUrl (attempt ${_reconnectAttempts + 1})');
      debugPrint('🔑 Token length: ${cleanToken.length}');

      _socket = IO.io(
        socketUrl,
        IO.OptionBuilder()
            .setTransports(['websocket', 'polling'])
            .setAuth({'token': cleanToken})
            .enableAutoConnect()
            .disableReconnection() // Disable built-in reconnection, use our custom logic
            .setTimeout(20000)
            .build(),
      );

      _setupEventListeners();
      
      // Wait for connection with timeout
      await _waitForConnection(timeout: const Duration(seconds: 10));
      
      if (!_isConnected) {
        debugPrint('⚠️ Connection timeout, will retry automatically');
        _scheduleReconnect();
      }
      
      _isConnecting = false;
    } catch (e) {
      debugPrint('❌ Error connecting socket: $e');
      _isConnected = false;
      _isConnecting = false;
      _scheduleReconnect();
    }
  }

  Future<void> _waitForConnection({required Duration timeout}) async {
    final completer = Completer<void>();
    Timer? timeoutTimer;
    bool connectionEstablished = false;

    void onConnect(_) {
      if (!connectionEstablished) {
        connectionEstablished = true;
        timeoutTimer?.cancel();
        if (!completer.isCompleted) {
          completer.complete();
        }
      }
    }

    void onConnectError(_) {
      if (!connectionEstablished && !completer.isCompleted) {
        timeoutTimer?.cancel();
        completer.complete();
      }
    }

    if (_socket != null) {
      _socket!.onConnect(onConnect);
      _socket!.onConnectError(onConnectError);
    }

    timeoutTimer = Timer(timeout, () {
      if (!connectionEstablished && !completer.isCompleted) {
        completer.complete();
      }
    });

    await completer.future;

    if (_socket != null) {
      _socket!.off('connect', onConnect);
      _socket!.off('connect_error', onConnectError);
    }
  }

  void _handleAuthFailure() {
    _authFailureCount++;
    _lastAuthFailure = DateTime.now();
    
    debugPrint('⚠️ Authentication failure count: $_authFailureCount/$_maxAuthFailures');
    
    if (_authFailureCount >= _maxAuthFailures) {
      debugPrint('❌ Max authentication failures reached - stopping reconnection');
      _shouldReconnect = false;
      _reconnectTimer?.cancel();
      _reconnectTimer = null;
    }
  }

  bool _canReconnect() {
    // Check if we're in auth failure cooldown
    if (_lastAuthFailure != null && _authFailureCount >= _maxAuthFailures) {
      final timeSinceFailure = DateTime.now().difference(_lastAuthFailure!);
      if (timeSinceFailure.inSeconds < _authFailureCooldown) {
        final remaining = _authFailureCooldown - timeSinceFailure.inSeconds;
        debugPrint('⏳ Auth failure cooldown: ${remaining}s remaining');
        return false;
      } else {
        // Cooldown expired, reset and allow reconnection
        debugPrint('✅ Auth failure cooldown expired - resetting');
        _authFailureCount = 0;
        _lastAuthFailure = null;
        _shouldReconnect = true;
      }
    }
    
    return _shouldReconnect;
  }

  void _scheduleReconnect() {
    if (!_canReconnect()) {
      debugPrint('⚠️ Reconnection disabled or in cooldown');
      return;
    }

    if (_reconnectAttempts >= _maxReconnectAttempts) {
      debugPrint('❌ Max reconnection attempts reached');
      _shouldReconnect = false;
      return;
    }

    // Exponential backoff: 2s, 4s, 8s, 16s, 32s, max 60s
    final delay = (_initialReconnectDelay * (1 << _reconnectAttempts)).clamp(
      _initialReconnectDelay,
      _maxReconnectDelay,
    );

    _reconnectAttempts++;
    debugPrint('🔄 Scheduling reconnect in ${delay}s (attempt $_reconnectAttempts/$_maxReconnectAttempts)');

    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(Duration(seconds: delay), () {
      if (_shouldReconnect && !_isConnected && !_isConnecting) {
        connect(forceReconnect: true);
      }
    });
  }

  void _resetReconnectAttempts() {
    _reconnectAttempts = 0;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
  }

  void _startHealthCheck() {
    _healthCheckTimer?.cancel();
    _healthCheckTimer = Timer.periodic(const Duration(seconds: 20), (timer) {
      if (!_isConnected || _socket == null || !_socket!.connected) {
        debugPrint('⚠️ Health check failed - socket not connected');
        if (_shouldReconnect && !_isConnecting) {
          connect(forceReconnect: true);
        }
        return;
      }

      // Send ping to server to keep connection alive
      try {
        _socket!.emit('ping');
        debugPrint('🏓 Sent ping to server');
      } catch (e) {
        debugPrint('❌ Error sending ping: $e');
      }

      // Check if we haven't received any messages in a while (optional)
      if (_lastMessageTime != null) {
        final timeSinceLastMessage = DateTime.now().difference(_lastMessageTime!);
        if (timeSinceLastMessage.inMinutes > 5) {
          debugPrint('⚠️ No messages received in ${timeSinceLastMessage.inMinutes} minutes');
        }
      }
    });
  }

  void _stopHealthCheck() {
    _healthCheckTimer?.cancel();
    _healthCheckTimer = null;
  }

  void _setupEventListeners() {
    if (_socket == null) return;

    _socket!.onConnect((_) {
      debugPrint('✅ Socket connected successfully');
      _isConnected = true;
      _isConnecting = false;
      _resetReconnectAttempts();
      // Reset auth failure count on successful connection
      _authFailureCount = 0;
      _lastAuthFailure = null;
      _startHealthCheck();
      
      // Rejoin any rooms that were previously joined
      final roomsToRejoin = List<String>.from(_joinedRooms);
      for (final roomId in roomsToRejoin) {
        debugPrint('🔄 Rejoining room: $roomId');
        _socket!.emit('join_conversation', roomId);
      }
    });

    // Listen for connection confirmation from server
    _socket!.on('connected', (data) {
      debugPrint('✅ Server confirmed connection: $data');
      _isConnected = true;
      _isConnecting = false;
    });

    // Handle ping/pong for keep-alive
    _socket!.on('pong', (data) {
      debugPrint('🏓 Received pong from server');
    });

    _socket!.onDisconnect((reason) {
      debugPrint('❌ Socket disconnected: $reason');
      _isConnected = false;
      _isConnecting = false;
      _stopHealthCheck();
      
      // Don't clear rooms on disconnect - we'll rejoin on reconnect
      // _joinedRooms.clear();
      
      // Log disconnect reason for debugging
      debugPrint('   → Disconnect reason: $reason');
      debugPrint('   → Should reconnect: $_shouldReconnect');
      debugPrint('   → Auth failures: $_authFailureCount/$_maxAuthFailures');
      
      // Schedule reconnection if it was an unexpected disconnect
      if (_shouldReconnect && reason != 'io client disconnect') {
        // Check if it's an auth-related disconnect
        if (reason.toString().toLowerCase().contains('authentication') || 
            reason.toString().toLowerCase().contains('unauthorized')) {
          debugPrint('   → Auth-related disconnect detected');
          _handleAuthFailure();
          if (!_canReconnect()) {
            debugPrint('   → Reconnection blocked due to auth failures');
            return;
          }
        }
        debugPrint('🔄 Unexpected disconnect, will attempt to reconnect');
        _scheduleReconnect();
      } else {
        debugPrint('   → Reconnection skipped (client disconnect or disabled)');
      }
    });

    _socket!.onReconnect((attemptNumber) {
      debugPrint('🔄 Socket reconnected after $attemptNumber attempts');
      _isConnected = true;
      _isConnecting = false;
      _resetReconnectAttempts();
      _startHealthCheck();
      
      // Rejoin rooms after reconnection
      final roomsToRejoin = List<String>.from(_joinedRooms);
      for (final roomId in roomsToRejoin) {
        debugPrint('🔄 Rejoining room after reconnect: $roomId');
        _socket!.emit('join_conversation', roomId);
      }
    });

    _socket!.onReconnectAttempt((attemptNumber) {
      debugPrint('🔄 Socket reconnection attempt #$attemptNumber');
      _isConnecting = true;
    });

    _socket!.onReconnectError((error) {
      debugPrint('❌ Socket reconnection error: $error');
      _isConnecting = true;
    });

    _socket!.onReconnectFailed((_) {
      debugPrint('❌ Socket reconnection failed - max attempts reached');
      _isConnected = false;
      _isConnecting = false;
      _shouldReconnect = false;
      _stopHealthCheck();
      
      // Try manual reconnection after a longer delay
      debugPrint('🔄 Will attempt manual reconnection in 60 seconds');
      Future.delayed(const Duration(seconds: 60), () {
        if (_shouldReconnect && !_isConnected) {
          _reconnectAttempts = 0; // Reset attempts for manual retry
          connect(forceReconnect: true);
        }
      });
    });

    _socket!.onConnectError((error) {
      debugPrint('❌ Socket connection error: $error');
      debugPrint('❌ Error details: ${error.toString()}');
      _isConnected = false;
      _isConnecting = false;
      
      // Check if it's an authentication error
      final errorStr = error.toString().toLowerCase();
      if (errorStr.contains('authentication') || errorStr.contains('401') || errorStr.contains('unauthorized') || errorStr.contains('invalid token')) {
        debugPrint('⚠️ Socket authentication failed - token may be invalid');
        _handleAuthFailure();
      } else {
        // Reset auth failure count on non-auth errors
        _authFailureCount = 0;
        _lastAuthFailure = null;
      }
    });

    _socket!.onError((error) {
      debugPrint('Socket error: $error');
    });

    // Listen for new messages
    _socket!.on('new_message', (data) {
      _lastMessageTime = DateTime.now();
      debugPrint('📬 Received new_message event: $data');
      if (data is Map<String, dynamic> && onMessage != null) {
        onMessage!(data);
      }
    });

    // Listen for message notifications
    _socket!.on('new_message_notification', (data) {
      debugPrint('🔔 Received new_message_notification: $data');
      if (data is Map<String, dynamic> && onMessageNotification != null) {
        onMessageNotification!(data);
      }
    });

    // Listen for typing indicators
    _socket!.on('typing', (data) {
      debugPrint('⌨️ Received typing event: $data');
      if (data is Map<String, dynamic> && onTyping != null) {
        onTyping!(data);
      }
    });

    // Listen for join confirmation
    _socket!.on('joined_conversation', (data) {
      debugPrint('✅ Joined conversation: $data');
      if (data is Map<String, dynamic> && data['conversationId'] != null) {
        final roomId = data['conversationId'] as String;
        if (!_joinedRooms.contains(roomId)) {
          _joinedRooms.add(roomId);
        }
      }
    });

    // Listen for notifications
    _socket!.on('notification', (data) {
      debugPrint('🔔 Received notification: $data');
      if (data is Map<String, dynamic> && onNotification != null) {
        onNotification!(data);
      }
    });
  }

  Future<void> joinConversation(String conversationId) async {
    if (!isConnected) {
      debugPrint('⚠️ Cannot join conversation - socket not connected');
      await connect();
      // Wait a bit for connection
      await Future.delayed(const Duration(milliseconds: 500));
      if (!isConnected) {
        debugPrint('⚠️ Still not connected after retry');
        return;
      }
    }

    if (_joinedRooms.contains(conversationId)) {
      debugPrint('Already in conversation: $conversationId');
      return;
    }

    debugPrint('📥 Joining conversation: $conversationId');
    _socket?.emit('join_conversation', conversationId);
  }

  Future<void> leaveConversation(String conversationId) async {
    if (!isConnected) return;

    debugPrint('📤 Leaving conversation: $conversationId');
    _socket?.emit('leave_conversation', conversationId);
    _joinedRooms.remove(conversationId);
  }

  void sendMessage(String conversationId, String content) {
    if (!isConnected) {
      debugPrint('⚠️ Cannot send message - socket not connected');
      return;
    }

    debugPrint('📤 Sending message via socket: $conversationId');
    _socket?.emit('send_message', {
      'conversationId': conversationId,
      'content': content,
    });
  }

  void emitTyping(String conversationId, bool isTyping) {
    if (!isConnected) return;

    _socket?.emit('typing', {
      'conversationId': conversationId,
      'isTyping': isTyping,
    });
  }

  Future<void> disconnect() async {
    debugPrint('Disconnecting socket...');
    _shouldReconnect = false;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _stopHealthCheck();
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _isConnected = false;
    _isConnecting = false;
    _joinedRooms.clear();
    _resetReconnectAttempts();
  }

  // Re-enable reconnection (useful when app comes back to foreground)
  void enableReconnection() {
    // Check if we can reconnect (not in cooldown)
    if (!_canReconnect()) {
      debugPrint('⚠️ Cannot enable reconnection - in cooldown or disabled');
      return;
    }
    
    _shouldReconnect = true;
    if (!_isConnected && !_isConnecting) {
      debugPrint('🔄 Re-enabling reconnection, attempting to connect...');
      connect(forceReconnect: true);
    }
  }

  // Force reconnection (useful for manual retry)
  Future<void> reconnect() async {
    debugPrint('🔄 Manual reconnection requested');
    _resetReconnectAttempts();
    // Reset auth failures on manual reconnect
    _authFailureCount = 0;
    _lastAuthFailure = null;
    _shouldReconnect = true;
    await connect(forceReconnect: true);
  }

  void dispose() {
    disconnect();
  }
}

