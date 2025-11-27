import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../services/socket_service.dart';
import '../models/api_models.dart';
import '../services/notification_service.dart';
import '../services/sound_service.dart';
import '../providers/auth_provider.dart';

class MessageProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  final SocketService _socketService = SocketService();
  
  List<Conversation> _conversations = [];
  Map<String, List<Message>> _messages = {};
  bool _isLoading = false;
  String? _errorMessage;
  String? _currentConversationId;
  bool _socketInitialized = false;
  String? _currentUserId; // Store current user ID for notification logic

  List<Conversation> get conversations => _conversations;
  Map<String, List<Message>> get messages => _messages;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get currentConversationId => _currentConversationId;

  List<Message> getMessagesForConversation(String conversationId) {
    return _messages[conversationId] ?? [];
  }

  Future<void> initializeSocket() async {
    if (_socketInitialized && _socketService.isConnected) {
      debugPrint('Socket already initialized and connected');
      return;
    }
    
    try {
      debugPrint('Initializing socket for real-time messages...');
      
      // Set up socket listeners first (before connecting)
      _socketService.onMessage = (data) {
        _handleSocketMessage(data);
      };
      
      _socketService.onMessageNotification = (data) {
        _handleSocketNotification(data);
      };
      
      // Now connect
      await _socketService.connect();
      
      // Wait a bit for connection with better timeout handling
      int waitAttempts = 0;
      while (!_socketService.isConnected && !_socketService.isConnecting && waitAttempts < 5) {
        await Future.delayed(const Duration(milliseconds: 500));
        waitAttempts++;
      }
      
      if (!_socketService.isConnected && !_socketService.isConnecting) {
        debugPrint('⚠️ Socket not connected after initialization attempt');
        // Enable reconnection - it will retry automatically
        _socketService.enableReconnection();
      }
      
      _socketInitialized = true;
      debugPrint('✅ Socket initialized for messages, connected: ${_socketService.isConnected}, connecting: ${_socketService.isConnecting}');
    } catch (e) {
      debugPrint('Error initializing socket: $e');
      _socketInitialized = false;
      // Enable reconnection on error
      _socketService.enableReconnection();
    }
  }

  void _handleSocketMessage(Map<String, dynamic> data) {
    try {
      if (data['message'] == null) return;
      
      final messageData = data['message'] as Map<String, dynamic>;
      final message = Message.fromJson(messageData);
      
      debugPrint('📬 Received real-time message: ${message.id}');
      
      // Add message using existing handler
      handleIncomingMessage(message);
    } catch (e) {
      debugPrint('Error handling socket message: $e');
    }
  }

  void _handleSocketNotification(Map<String, dynamic> data) {
    try {
      if (data['message'] == null) return;
      
      final messageData = data['message'] as Map<String, dynamic>;
      final message = Message.fromJson(messageData);
      
      debugPrint('🔔 Received message notification: ${message.id}');
      
      // Add message using existing handler
      handleIncomingMessage(message);
    } catch (e) {
      debugPrint('Error handling socket notification: $e');
    }
  }

  Future<void> loadConversations() async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      debugPrint('[MessageProvider] Loading conversations...');
      
      // Verify token exists before making API call
      bool hasToken = await _apiService.hasToken();
      if (!hasToken) {
        debugPrint('[MessageProvider] ❌ No token found for loadConversations');
        _errorMessage = 'Authentication token not provided. Please login again.';
        _isLoading = false;
        notifyListeners();
        return;
      }
      
      debugPrint('[MessageProvider] ✅ Token verified, proceeding with API call');

      // Initialize socket if not already done
      await initializeSocket();

      final response = await _apiService.getConversations();
      
      debugPrint('[MessageProvider] getConversations response: success=${response['success']}, hasData=${response['data'] != null}');

      if (response['success'] == true && response['data'] != null) {
        final data = response['data'] as List<dynamic>;
        _conversations = data
            .map((json) => Conversation.fromJson(json as Map<String, dynamic>))
            .toList();
        // Sort by last message time (most recent first)
        _conversations.sort((a, b) {
          final aTime = a.lastMessageAt ?? a.createdAt;
          final bTime = b.lastMessageAt ?? b.createdAt;
          if (aTime == null && bTime == null) return 0;
          if (aTime == null) return 1;
          if (bTime == null) return -1;
          return bTime.compareTo(aTime);
        });
        debugPrint('[MessageProvider] ✅ Loaded ${_conversations.length} conversations');
      } else {
        _errorMessage = response['message'] ?? 'Failed to load conversations';
        debugPrint('[MessageProvider] ❌ Failed to load conversations: $_errorMessage');
        // Set empty list instead of keeping old data
        _conversations = [];
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      debugPrint('[MessageProvider] ❌ Error loading conversations: $e');
      _errorMessage = e.toString();
      _isLoading = false;
      // Set empty list on error
      _conversations = [];
      notifyListeners();
    }
  }

  Future<Conversation?> createConversation() async {
    try {
      // First verify token exists and is valid
      // Try multiple times with delay in case of race condition
      bool hasToken = false;
      String? token;
      
      debugPrint('[MessageProvider] Starting token check for createConversation...');
      
      for (int i = 0; i < 5; i++) {
        hasToken = await _apiService.hasToken();
        debugPrint('[MessageProvider] Token check attempt ${i + 1}: hasToken=$hasToken');
        
        if (hasToken) {
          token = await _apiService.getToken();
          debugPrint('[MessageProvider] Token retrieved, length: ${token?.length ?? 0}');
          
          if (token != null && token.isNotEmpty) {
            debugPrint('[MessageProvider] ✅ Valid token found on attempt ${i + 1}');
            break;
          }
        }
        
        if (i < 4) {
          await Future.delayed(const Duration(milliseconds: 300));
        }
      }
      
      if (!hasToken || token == null || token.isEmpty) {
        debugPrint('[MessageProvider] ❌ No token found after 5 retries');
        debugPrint('[MessageProvider] Final check - hasToken: $hasToken, token: ${token != null ? "exists (${token.length} chars)" : "null"}');
        
        // Try one more direct check
        final directToken = await _apiService.getToken();
        if (directToken != null && directToken.isNotEmpty) {
          debugPrint('[MessageProvider] ✅ Token found on direct check!');
          token = directToken;
        } else {
          _errorMessage = 'Authentication token not provided. Please login again.';
          _isLoading = false;
          notifyListeners();
          return null;
        }
      }
      
      debugPrint('[MessageProvider] ✅ Token verified, length: ${token.length}');

      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final response = await _apiService.createConversation();

      if (response['success'] == true && response['data'] != null) {
        final conversation = Conversation.fromJson(
          response['data'] as Map<String, dynamic>,
        );
        _conversations.insert(0, conversation);
        _isLoading = false;
        notifyListeners();
        return conversation;
      } else {
        _errorMessage = response['message'] ?? 'Failed to create conversation';
        _isLoading = false;
        notifyListeners();
        return null;
      }
    } catch (e) {
      String errorMsg = e.toString();
      if (errorMsg.contains('Authentication token not provided') || 
          errorMsg.contains('401') ||
          errorMsg.contains('Unauthorized')) {
        _errorMessage = 'Your session has expired. Please login again.';
      } else {
        _errorMessage = errorMsg;
      }
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  Future<void> loadMessages(String conversationId, {bool refresh = false}) async {
    try {
      if (!refresh && _messages.containsKey(conversationId)) {
        // Still join the conversation room for real-time updates
        await _socketService.joinConversation(conversationId);
        return; // Already loaded
      }

      _isLoading = true;
      _errorMessage = null;
      _currentConversationId = conversationId;
      notifyListeners();

      // Join conversation room for real-time updates
      await _socketService.joinConversation(conversationId);

      final response = await _apiService.getMessages(conversationId);

      if (response['success'] == true && response['data'] != null) {
        final data = response['data'];
        List<dynamic> messagesList;
        
        // Backend returns messages directly as an array
        if (data is List) {
          messagesList = data;
        } else if (data is Map && data['data'] != null) {
          messagesList = data['data'] as List<dynamic>;
        } else {
          messagesList = [];
        }

        final newMessages = messagesList
            .map((json) {
              try {
                return Message.fromJson(json as Map<String, dynamic>);
              } catch (e) {
                debugPrint('Error parsing message: $e');
                return null;
              }
            })
            .whereType<Message>()
            .toList();
        
        // Sort messages by creation time (oldest first)
        newMessages.sort((a, b) {
          final aTime = a.createdAt ?? DateTime(1970);
          final bTime = b.createdAt ?? DateTime(1970);
          return aTime.compareTo(bTime);
        });

        _messages[conversationId] = newMessages;
        
        // Note: Notifications for new messages are handled in handleIncomingMessage
        // when messages arrive via socket in real-time. We don't notify for messages
        // loaded from API as they are historical messages.
      } else {
        _errorMessage = response['message'] ?? 'Failed to load messages';
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> sendMessage({
    required String conversationId,
    required String content,
    List<String>? attachments,
  }) async {
    try {
      // First verify token exists and is valid before sending
      final hasToken = await _apiService.hasToken();
      if (!hasToken) {
        _errorMessage = 'Authentication token not provided. Please login again.';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // Double-check token is not empty
      final token = await _apiService.getToken();
      if (token == null || token.isEmpty) {
        _errorMessage = 'Authentication token not provided. Please login again.';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      // Optimistically add a temporary message
      final tempMessage = Message(
        id: 'temp-${DateTime.now().millisecondsSinceEpoch}',
        conversationId: conversationId,
        senderId: '', // Will be set by backend
        senderType: 'user',
        content: content,
        isRead: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      if (!_messages.containsKey(conversationId)) {
        _messages[conversationId] = [];
      }
      _messages[conversationId]!.add(tempMessage);
      notifyListeners();

      final response = await _apiService.sendMessage(
        conversationId: conversationId,
        content: content,
        attachments: attachments,
      );

      if (response['success'] == true && response['data'] != null) {
        final message = Message.fromJson(
          response['data'] as Map<String, dynamic>,
        );
        
        // Remove temp message and add real one
        _messages[conversationId]!.removeWhere((m) => m.id == tempMessage.id);
        _messages[conversationId]!.add(message);
        
        // Update conversation's last message
        final conversationIndex = _conversations.indexWhere(
          (c) => c.id == conversationId,
        );
        if (conversationIndex != -1) {
          _conversations[conversationIndex] = Conversation(
            id: _conversations[conversationIndex].id,
            userId: _conversations[conversationIndex].userId,
            adminId: _conversations[conversationIndex].adminId,
            status: _conversations[conversationIndex].status,
            lastMessage: content,
            lastMessageAt: DateTime.now(),
            unreadCount: _conversations[conversationIndex].unreadCount,
            createdAt: _conversations[conversationIndex].createdAt,
            updatedAt: _conversations[conversationIndex].updatedAt,
          );
        }

        // Play send sound
        await SoundService().playSendSound();

        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        // Remove temp message on error
        _messages[conversationId]!.removeWhere((m) => m.id == tempMessage.id);
        _errorMessage = response['message'] ?? 'Failed to send message';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      // Remove temp message on error
      if (_messages.containsKey(conversationId)) {
        _messages[conversationId]!.removeWhere((m) => m.id.startsWith('temp-'));
      }
      
      String errorMsg = e.toString();
      if (errorMsg.contains('Authentication token not provided') || 
          errorMsg.contains('401') ||
          errorMsg.contains('Unauthorized')) {
        _errorMessage = 'Your session has expired. Please login again.';
      } else {
        _errorMessage = errorMsg;
      }
      
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Method to handle incoming messages (called from socket or API)
  // Set current user ID (called when user logs in)
  void setCurrentUserId(String? userId) {
    _currentUserId = userId;
    debugPrint('[MessageProvider] Current user ID set: ${userId ?? "null"}');
  }

  Future<void> handleIncomingMessage(Message message, {BuildContext? context}) async {
    // Add message to local list
    if (!_messages.containsKey(message.conversationId)) {
      _messages[message.conversationId] = [];
    }
    
    // Check if message already exists to avoid duplicates
    final exists = _messages[message.conversationId]!.any((m) => m.id == message.id);
    if (exists) {
      debugPrint('[MessageProvider] Message ${message.id} already exists, skipping');
      return;
    }
    
    // Get current user ID to check if message is from current user
    // Try from context first, then from stored value
    String? currentUserId = _currentUserId;
    if (context != null && currentUserId == null) {
      try {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        currentUserId = authProvider.user?.id;
        if (currentUserId != null) {
          _currentUserId = currentUserId; // Store for future use
        }
      } catch (e) {
        debugPrint('[MessageProvider] Error getting current user: $e');
      }
    }
    
    // Check if message is from current user (don't notify for own messages)
    final isFromCurrentUser = currentUserId != null && message.senderId == currentUserId;
    
    // Check if user is currently viewing this conversation
    final isViewingConversation = _currentConversationId == message.conversationId;
    
    _messages[message.conversationId]!.add(message);
    
    // Sort messages by creation time
    _messages[message.conversationId]!.sort((a, b) {
      final aTime = a.createdAt ?? DateTime(1970);
      final bTime = b.createdAt ?? DateTime(1970);
      return aTime.compareTo(bTime);
    });
    
    // Update conversation's last message
    final conversationIndex = _conversations.indexWhere(
      (c) => c.id == message.conversationId,
    );
    if (conversationIndex != -1) {
      _conversations[conversationIndex] = Conversation(
        id: _conversations[conversationIndex].id,
        userId: _conversations[conversationIndex].userId,
        adminId: _conversations[conversationIndex].adminId,
        status: _conversations[conversationIndex].status,
        lastMessage: message.content,
        lastMessageAt: message.createdAt ?? DateTime.now(),
        unreadCount: !isFromCurrentUser && !isViewingConversation
            ? _conversations[conversationIndex].unreadCount + 1
            : _conversations[conversationIndex].unreadCount,
        createdAt: _conversations[conversationIndex].createdAt,
        updatedAt: _conversations[conversationIndex].updatedAt,
      );
    } else {
      // If conversation doesn't exist, reload conversations
      loadConversations();
    }
    
    // Play sound and show notification for new messages (not from current user)
    // Only if user is not currently viewing the conversation
    if (!isFromCurrentUser && !isViewingConversation) {
      debugPrint('[MessageProvider] 📬 New message received, playing sound and showing notification');
      
      // Play notification sound
      await SoundService().playMessageSound();
      
      // Show notification with appropriate title
      final notificationTitle = message.senderType == 'admin' 
          ? 'New Message from Support'
          : 'New Message';
      
      final notificationBody = message.content.length > 80 
          ? '${message.content.substring(0, 80)}...'
          : message.content;
      
      await NotificationService().showLocalNotification(
        title: notificationTitle,
        body: notificationBody,
        payload: message.conversationId,
        isMessage: true,
      );
    } else if (isFromCurrentUser) {
      debugPrint('[MessageProvider] Message from current user, skipping notification');
    } else if (isViewingConversation) {
      debugPrint('[MessageProvider] User is viewing conversation, skipping notification');
    }
    
    notifyListeners();
  }

  Future<void> markAsRead(String conversationId) async {
    try {
      await _apiService.markConversationAsRead(conversationId);
      
      // Update local conversation
      final conversationIndex = _conversations.indexWhere(
        (c) => c.id == conversationId,
      );
      if (conversationIndex != -1) {
        _conversations[conversationIndex] = Conversation(
          id: _conversations[conversationIndex].id,
          userId: _conversations[conversationIndex].userId,
          adminId: _conversations[conversationIndex].adminId,
          status: _conversations[conversationIndex].status,
          lastMessage: _conversations[conversationIndex].lastMessage,
          lastMessageAt: _conversations[conversationIndex].lastMessageAt,
          unreadCount: 0,
          createdAt: _conversations[conversationIndex].createdAt,
          updatedAt: _conversations[conversationIndex].updatedAt,
        );
        notifyListeners();
      }
    } catch (e) {
      // Silently fail - not critical
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}

