import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/message_provider.dart';
import '../providers/auth_provider.dart';
import '../services/backend_auth_service.dart';
import '../models/api_models.dart' hide Material;
import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';
import 'chat_screen.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  Conversation? _selectedConversation;
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _messagesScrollController = ScrollController();
  bool _isSending = false;
  final FocusNode _messageFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final messageProvider = Provider.of<MessageProvider>(context, listen: false);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      // Verify user is authenticated before loading conversations
      if (!authProvider.isAuthenticated || authProvider.user == null) {
        debugPrint('[MessagesScreen] User not authenticated, skipping conversation load');
        return;
      }
      
      try {
        debugPrint('[MessagesScreen] Initializing and loading admin conversation...');
        // Initialize socket for real-time updates
        await messageProvider.initializeSocket();
        
        // Load conversations to check if one exists
        await messageProvider.loadConversations();
        debugPrint('[MessagesScreen] ✅ Conversations loaded: ${messageProvider.conversations.length}');
        
        // Get or create conversation with admin
        Conversation? conversation;
        if (messageProvider.conversations.isNotEmpty) {
          // Use the first (most recent) conversation
          conversation = messageProvider.conversations.first;
          debugPrint('[MessagesScreen] Using existing conversation: ${conversation.id}');
        } else {
          // Create a new conversation
          debugPrint('[MessagesScreen] No existing conversation, creating new one...');
          conversation = await messageProvider.createConversation();
          if (conversation != null) {
            debugPrint('[MessagesScreen] ✅ Created new conversation: ${conversation.id}');
          }
        }
        
        // Navigate directly to chat screen with admin
        if (conversation != null && mounted) {
          _selectConversation(conversation);
        } else if (mounted && messageProvider.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(messageProvider.errorMessage!),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        debugPrint('[MessagesScreen] ❌ Error loading conversation: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error loading conversation: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    });
  }

  // Real-time updates are now handled by socket service - no polling needed

  @override
  void dispose() {
    _messageController.dispose();
    _messagesScrollController.dispose();
    _messageFocusNode.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_messagesScrollController.hasClients) {
        _messagesScrollController.animateTo(
          _messagesScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _selectConversation(Conversation conversation) async {
    setState(() {
      _selectedConversation = conversation;
    });

    final messageProvider = Provider.of<MessageProvider>(context, listen: false);
    try {
        await messageProvider.loadMessages(conversation.id, refresh: true, loadAll: true);
      await messageProvider.markAsRead(conversation.id);
      _scrollToBottom();
      
      // Listen for new messages in this conversation
      _listenForNewMessages(conversation.id);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading messages: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _listenForNewMessages(String conversationId) {
    // Real-time messages are now handled automatically by socket service
    // No manual listening needed - messages will appear via provider updates
  }

  Future<void> _createAndSelectConversation() async {
    final messageProvider = Provider.of<MessageProvider>(context, listen: false);
    
    // Check token directly instead of relying on authProvider.isAuthenticated
    // This handles cases where token exists but user data hasn't loaded yet
    final backendAuthService = BackendAuthService();
    bool hasToken = false;
    String? token;
    
    debugPrint('[MessagesScreen] Checking token before creating conversation...');
    
    // Try multiple times to get token
    for (int i = 0; i < 3; i++) {
      hasToken = await backendAuthService.isLoggedIn();
      if (hasToken) {
        token = await backendAuthService.getToken();
        if (token != null && token.isNotEmpty) {
          debugPrint('[MessagesScreen] ✅ Token found, length: ${token.length}');
          break;
        }
      }
      if (i < 2) {
        await Future.delayed(const Duration(milliseconds: 200));
      }
    }
    
    if (!hasToken || token == null || token.isEmpty) {
      debugPrint('[MessagesScreen] ❌ No token found, cannot create conversation');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please login to start a conversation'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    try {
      
      final conversation = await messageProvider.createConversation();
      
      if (mounted) {
        Navigator.of(context).pop();
      }

      if (conversation != null && mounted) {
        final isWideScreen = MediaQuery.of(context).size.width > 600;
        if (isWideScreen) {
          _selectConversation(conversation);
        } else {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => ChatScreen(conversation: conversation),
            ),
          );
        }
      } else if (mounted && messageProvider.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(messageProvider.errorMessage!),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'Login',
              textColor: Colors.white,
              onPressed: () {
                Navigator.of(context).pushNamed('/auth');
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create conversation: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _sendMessage() async {
    if (_selectedConversation == null) return;
    
    final content = _messageController.text.trim();
    if (content.isEmpty || _isSending) return;

    setState(() {
      _isSending = true;
    });

    final messageProvider = Provider.of<MessageProvider>(context, listen: false);
    final success = await messageProvider.sendMessage(
      conversationId: _selectedConversation!.id,
      content: content,
    );

    if (success) {
      _messageController.clear();
      _scrollToBottom();
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              messageProvider.errorMessage ?? 'Failed to send message',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    if (mounted) {
      setState(() {
        _isSending = false;
      });
    }
  }

  String _formatMessageTime(DateTime? dateTime) {
    if (dateTime == null) return '';
    
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays == 0) {
      final hour = dateTime.hour;
      final minute = dateTime.minute.toString().padLeft(2, '0');
      final period = hour >= 12 ? 'PM' : 'AM';
      final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
      return '$displayHour:$minute $period';
    } else {
      final month = dateTime.month.toString().padLeft(2, '0');
      final day = dateTime.day.toString().padLeft(2, '0');
      final hour = dateTime.hour;
      final minute = dateTime.minute.toString().padLeft(2, '0');
      final period = hour >= 12 ? 'PM' : 'AM';
      final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
      return '$month/$day $displayHour:$minute $period';
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final l10n = AppLocalizations.of(context)!;
    final messageProvider = Provider.of<MessageProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final currentUserId = authProvider.user?.id ?? '';
    
    final isWideScreen = MediaQuery.of(context).size.width > 600;
    final screenHeight = MediaQuery.of(context).size.height;

    // Always show chat view (skip conversations list)
    // Show loading if no conversation is selected yet
    if (!isWideScreen) {
      if (_selectedConversation == null && messageProvider.isLoading) {
        return Scaffold(
          appBar: AppBar(
            title: Text(l10n.translate('messages')),
          ),
          body: const Center(child: CircularProgressIndicator()),
        );
      } else if (_selectedConversation == null) {
        // If still no conversation after loading, show empty state with option to create
        return Scaffold(
          appBar: AppBar(
            title: Text(l10n.translate('messages')),
          ),
          body: _buildEmptyConversationsState(context, l10n),
        );
      } else {
        return _buildChatView(context, l10n, messageProvider, currentUserId, isWideScreen, screenHeight);
      }
    }

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.chat_bubble_outline,
                color: Theme.of(context).colorScheme.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              l10n.translate('messages'),
              style: AppTypography.titleLarge.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            tooltip: 'New conversation',
            onPressed: _createAndSelectConversation,
          ),
        ],
      ),
      body: _selectedConversation == null && messageProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : _selectedConversation == null
              ? _buildEmptyConversationsState(context, l10n)
              : _buildChatView(context, l10n, messageProvider, currentUserId, isWideScreen, screenHeight),
    );
  }


  Widget _buildEmptyConversationsState(BuildContext context, AppLocalizations l10n) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.chat_bubble_outline,
                size: 80,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              l10n.translate('no_conversations'),
              style: AppTypography.titleLarge.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              l10n.translate('start_conversation'),
              style: AppTypography.bodyLarge.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _createAndSelectConversation,
              icon: const Icon(Icons.add),
              label: Text(l10n.translate('start_conversation')),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatView(
    BuildContext context,
    AppLocalizations l10n,
    MessageProvider messageProvider,
    String currentUserId,
    bool isWideScreen,
    double screenHeight,
  ) {
    if (_selectedConversation == null) {
      return _buildEmptyChatState(context, isWideScreen);
    }

    final messages = messageProvider.getMessagesForConversation(_selectedConversation!.id);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: isWideScreen ? null : _buildChatAppBar(context, isWideScreen),
      body: Column(
        children: [
          if (isWideScreen) _buildChatHeader(context),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.background,
              ),
              child: messageProvider.isLoading && messages.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : messages.isEmpty
                      ? _buildEmptyMessagesState(context, l10n)
                      : _buildMessagesList(context, messages, currentUserId, screenHeight),
            ),
          ),
          _buildMessageInput(context, l10n),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildChatAppBar(BuildContext context, bool isWideScreen) {
    return AppBar(
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () {
          setState(() {
            _selectedConversation = null;
          });
        },
      ),
      title: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.support_agent,
              color: Theme.of(context).colorScheme.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Support',
                  style: AppTypography.titleMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.6),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Active',
                      style: AppTypography.labelSmall.copyWith(
                        color: Colors.green.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.support_agent,
              color: Theme.of(context).colorScheme.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Support',
                  style: AppTypography.titleMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.6),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Active',
                      style: AppTypography.bodySmall.copyWith(
                        color: Colors.green.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyChatState(BuildContext context, bool isWideScreen) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: isWideScreen ? null : AppBar(
        title: const Text('Support'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            setState(() {
              _selectedConversation = null;
            });
          },
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.chat_bubble_outline,
                  size: 64,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Select a conversation',
                style: AppTypography.titleLarge.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Choose a conversation from the list to start messaging',
                style: AppTypography.bodyLarge.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyMessagesState(BuildContext context, AppLocalizations l10n) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.chat_bubble_outline,
                size: 64,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              l10n.translate('no_messages'),
              style: AppTypography.titleLarge.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              l10n.translate('start_chat'),
              style: AppTypography.bodyLarge.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessagesList(
    BuildContext context,
    List<Message> messages,
    String currentUserId,
    double screenHeight,
  ) {
    return ListView.builder(
      controller: _messagesScrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final message = messages[index];
        final isMe = message.senderId == currentUserId;
        final showAvatar = index == 0 || 
            (index > 0 && messages[index - 1].senderId != message.senderId);
        
        return _buildMessageBubble(
          context,
          message,
          isMe,
          showAvatar,
        );
      },
    );
  }

  Widget _buildMessageBubble(
    BuildContext context,
    Message message,
    bool isMe,
    bool showAvatar,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe && showAvatar)
            Container(
              width: 32,
              height: 32,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.support_agent,
                color: Theme.of(context).colorScheme.primary,
                size: 18,
              ),
            )
          else if (!isMe)
            const SizedBox(width: 40),
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                color: isMe
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(isMe ? 20 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: isMe
                        ? Theme.of(context).colorScheme.primary.withOpacity(0.3)
                        : Colors.black.withOpacity(0.08),
                    blurRadius: isMe ? 8 : 4,
                    offset: const Offset(0, 2),
                    spreadRadius: isMe ? 1 : 0,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.content,
                    style: AppTypography.bodyMedium.copyWith(
                      color: isMe
                          ? Colors.white
                          : Theme.of(context).colorScheme.onSurface,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _formatMessageTime(message.createdAt),
                        style: AppTypography.labelSmall.copyWith(
                          color: isMe
                              ? Colors.white70
                              : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                      if (isMe) ...[
                        const SizedBox(width: 4),
                        Icon(
                          Icons.done_all,
                          size: 14,
                          color: Colors.white70,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (isMe && showAvatar)
            Container(
              width: 32,
              height: 32,
              margin: const EdgeInsets.only(left: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.secondaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.person,
                color: Theme.of(context).colorScheme.secondary,
                size: 18,
              ),
            )
          else if (isMe)
            const SizedBox(width: 40),
        ],
      ),
    );
  }

  Widget _buildMessageInput(BuildContext context, AppLocalizations l10n) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.shadow.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 8,
        bottom: MediaQuery.of(context).padding.bottom + 8,
      ),
      child: SafeArea(
        top: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Container(
                constraints: const BoxConstraints(maxHeight: 120),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                  ),
                ),
                child: TextField(
                  controller: _messageController,
                  focusNode: _messageFocusNode,
                  decoration: InputDecoration(
                    hintText: l10n.translate('type_message'),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    hintStyle: AppTypography.bodyMedium.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                    ),
                  ),
                  style: AppTypography.bodyMedium,
                  maxLines: null,
                  textCapitalization: TextCapitalization.sentences,
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.primary,
                    Theme.of(context).colorScheme.primary.withOpacity(0.8),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _isSending ? null : _sendMessage,
                  borderRadius: BorderRadius.circular(28),
                  child: Container(
                    width: 56,
                    height: 56,
                    padding: const EdgeInsets.all(16),
                    child: _isSending
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Icon(
                            Icons.send,
                            color: Colors.white,
                            size: 24,
                          ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
