import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../services/socket_service.dart';
import '../services/notification_service.dart';
import '../models/notification_model.dart';

class NotificationProvider with ChangeNotifier {
  final SocketService _socketService = SocketService();
  final NotificationService _notificationService = NotificationService();
  
  List<AppNotification> _notifications = [];
  int _unreadCount = 0;
  bool _socketInitialized = false;
  
  List<AppNotification> get notifications => List.unmodifiable(_notifications);
  int get unreadCount => _unreadCount;
  
  // Callbacks for notification events
  Function(Map<String, dynamic>)? _onNotificationCallback;
  
  Future<void> initialize() async {
    if (_socketInitialized) {
      debugPrint('[NotificationProvider] Already initialized');
      return;
    }
    
    try {
      // Initialize notification service
      await _notificationService.initialize();
      
      // Set up socket callback for notifications
      _socketService.onNotification = (data) {
        handleSocketNotification(data);
      };
      
      // Connect socket if not already connected
      if (!_socketService.isConnected && !_socketService.isConnecting) {
        await _socketService.connect();
      }
      
      _socketInitialized = true;
      debugPrint('[NotificationProvider] ✅ Initialized successfully');
    } catch (e) {
      debugPrint('[NotificationProvider] ❌ Error initializing: $e');
    }
  }
  
  void handleSocketNotification(Map<String, dynamic> data) {
    _handleSocketNotification(data);
  }
  
  void _handleSocketNotification(Map<String, dynamic> data) {
    try {
      debugPrint('[NotificationProvider] 📬 Received notification: $data');
      
      final notification = AppNotification.fromJson(data);
      
      // Check for duplicates
      final isDuplicate = _notifications.any(
        (n) =>
            n.type == notification.type &&
            n.metadata?.toString() == notification.metadata?.toString(),
      );
      
      if (isDuplicate) {
        debugPrint('[NotificationProvider] Duplicate notification, skipping');
        return;
      }
      
      // Add to list
      _notifications.insert(0, notification);
      
      // Keep only last 100 notifications
      if (_notifications.length > 100) {
        _notifications = _notifications.sublist(0, 100);
      }
      
      // Increment unread count
      _unreadCount++;
      
      // Show local notification
      _showLocalNotification(notification);
      
      notifyListeners();
      
      debugPrint('[NotificationProvider] ✅ Notification added, total: ${_notifications.length}, unread: $_unreadCount');
    } catch (e) {
      debugPrint('[NotificationProvider] ❌ Error handling notification: $e');
    }
  }
  
  Future<void> _showLocalNotification(AppNotification notification) async {
    try {
      await _notificationService.showLocalNotification(
        title: notification.title,
        body: notification.message,
        payload: notification.id,
        isMessage: notification.type == NotificationType.message,
      );
    } catch (e) {
      debugPrint('[NotificationProvider] Error showing local notification: $e');
    }
  }
  
  void markAsRead(String id) {
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index == -1) return;
    
    if (!_notifications[index].read) {
      _notifications[index] = _notifications[index].copyWith(read: true);
      _unreadCount = (_unreadCount - 1).clamp(0, double.infinity).toInt();
      notifyListeners();
    }
  }
  
  void markAllAsRead() {
    _notifications = _notifications.map((n) => n.copyWith(read: true)).toList();
    _unreadCount = 0;
    notifyListeners();
  }
  
  void removeNotification(String id) {
    final notification = _notifications.firstWhere(
      (n) => n.id == id,
      orElse: () => throw Exception('Notification not found'),
    );
    
    _notifications.removeWhere((n) => n.id == id);
    if (!notification.read) {
      _unreadCount = (_unreadCount - 1).clamp(0, double.infinity).toInt();
    }
    notifyListeners();
  }
  
  void clearAll() {
    _notifications.clear();
    _unreadCount = 0;
    notifyListeners();
  }
  
  @override
  void dispose() {
    _socketInitialized = false;
    super.dispose();
  }
}

