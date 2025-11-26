import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../services/api_service.dart';
import '../models/api_models.dart';
import '../services/notification_service.dart';
import '../services/sound_service.dart';

class MessageProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  
  List<Conversation> _conversations = [];
  Map<String, List<Message>> _messages = {};
  bool _isLoading = false;
  String? _errorMessage;
  String? _currentConversationId;

  List<Conversation> get conversations => _conversations;
  Map<String, List<Message>> get messages => _messages;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get currentConversationId => _currentConversationId;

  List<Message> getMessagesForConversation(String conversationId) {
    return _messages[conversationId] ?? [];
  }

  Future<void> loadConversations() async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final response = await _apiService.getConversations();

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
      } else {
        _errorMessage = response['message'] ?? 'Failed to load conversations';
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Conversation?> createConversation() async {
    try {
      // First verify token exists
      final hasToken = await _apiService.hasToken();
      if (!hasToken) {
        _errorMessage = 'Authentication token not provided. Please login again.';
        notifyListeners();
        return null;
      }

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
        return; // Already loaded
      }

      _isLoading = true;
      _errorMessage = null;
      _currentConversationId = conversationId;
      notifyListeners();

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

        // Check for new admin messages and play sound/show notification
        for (final message in newMessages) {
          if (message.senderType == 'admin' && !message.isRead) {
            // Play sound for unread admin messages
            await SoundService().playMessageSound();
            // Show notification
            await NotificationService().showLocalNotification(
              title: 'New Message from Support',
              body: message.content.length > 50 
                  ? '${message.content.substring(0, 50)}...'
                  : message.content,
              payload: conversationId,
            );
          }
        }
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
      _isLoading = true;
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
        
        // Add message to local list
        if (!_messages.containsKey(conversationId)) {
          _messages[conversationId] = [];
        }
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
        _errorMessage = response['message'] ?? 'Failed to send message';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Method to handle incoming messages (called from socket or API)
  Future<void> handleIncomingMessage(Message message) async {
    // Add message to local list
    if (!_messages.containsKey(message.conversationId)) {
      _messages[message.conversationId] = [];
    }
    
    // Check if message already exists to avoid duplicates
    final exists = _messages[message.conversationId]!.any((m) => m.id == message.id);
    if (exists) return;
    
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
        unreadCount: message.senderType == 'admin' 
            ? _conversations[conversationIndex].unreadCount + 1
            : _conversations[conversationIndex].unreadCount,
        createdAt: _conversations[conversationIndex].createdAt,
        updatedAt: _conversations[conversationIndex].updatedAt,
      );
    } else {
      // If conversation doesn't exist, reload conversations
      loadConversations();
    }
    
    // Play sound and show notification for admin messages
    if (message.senderType == 'admin') {
      await SoundService().playMessageSound();
      await NotificationService().showLocalNotification(
        title: 'New Message from Support',
        body: message.content.length > 50 
            ? '${message.content.substring(0, 50)}...'
            : message.content,
        payload: message.conversationId,
      );
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

