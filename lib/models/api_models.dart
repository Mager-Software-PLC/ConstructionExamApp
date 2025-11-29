// API Response Models matching backend structure

class ApiResponse<T> {
  final bool success;
  final String? message;
  final T? data;
  final Map<String, dynamic>? pagination;

  ApiResponse({
    required this.success,
    this.message,
    this.data,
    this.pagination,
  });

  factory ApiResponse.fromJson(Map<String, dynamic> json, T Function(dynamic)? fromJsonT) {
    return ApiResponse<T>(
      success: json['success'] ?? false,
      message: json['message'],
      data: json['data'] != null && fromJsonT != null ? fromJsonT(json['data']) : json['data'] as T?,
      pagination: json['pagination'] as Map<String, dynamic>?,
    );
  }
}

class User {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String? avatar;
  final double progress;
  final String preferredLanguage;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    this.avatar,
    this.progress = 0.0,
    this.preferredLanguage = 'en',
    this.createdAt,
    this.updatedAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      avatar: json['avatar'],
      progress: (json['progress'] ?? 0).toDouble(),
      preferredLanguage: json['preferredLanguage'] ?? 'en',
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'avatar': avatar,
      'progress': progress,
      'preferredLanguage': preferredLanguage,
    };
  }
}

class Category {
  final String id;
  final String name;
  final String? description;
  final String color; // Hex color code
  final String difficulty; // "easy", "medium", "hard"
  final int questionCount;
  final int order;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Category({
    required this.id,
    required this.name,
    this.description,
    required this.color,
    required this.difficulty,
    this.questionCount = 0,
    this.order = 0,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'],
      color: json['color'] ?? '#3b82f6',
      difficulty: json['difficulty'] ?? 'medium',
      questionCount: json['questionCount'] ?? 0,
      order: json['order'] ?? 0,
      isActive: json['isActive'] ?? true,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
    );
  }
}

class Question {
  final String id;
  final String categoryId;
  final Map<String, String> question; // Multilingual
  final List<QuestionOption> options;
  final Map<String, String>? explanation; // Multilingual
  final String difficulty; // 'easy', 'medium', 'hard'
  final int points;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final Map<String, dynamic>? translation; // Current translation from backend

  Question({
    required this.id,
    required this.categoryId,
    required this.question,
    required this.options,
    this.explanation,
    this.difficulty = 'medium',
    this.points = 10,
    this.createdAt,
    this.updatedAt,
    this.translation,
  });

  factory Question.fromJson(Map<String, dynamic> json) {
    // Backend returns questions with translations array structure
    // Handle both old format (question map) and new format (translations array)
    
    String categoryId = '';
    if (json['category'] != null) {
      if (json['category'] is String) {
        categoryId = json['category'];
      } else if (json['category'] is Map) {
        categoryId = json['category']['_id'] ?? json['category']['id'] ?? '';
      }
    }
    categoryId = categoryId.isEmpty ? (json['categoryId'] ?? '') : categoryId;
    
    // Handle translations array from backend
    Map<String, String> questionMap = {};
    List<QuestionOption> optionsList = [];
    Map<String, String>? explanationMap;
    Map<String, dynamic>? currentTranslation;
    
    if (json['translations'] != null && json['translations'] is List) {
      // Backend format: translations array
      final translations = json['translations'] as List<dynamic>;
      
      // Build question map from translations
      for (var trans in translations) {
        if (trans is Map<String, dynamic>) {
          final lang = trans['language'] ?? 'en';
          questionMap[lang] = trans['questionText'] ?? '';
          if (trans['explanation'] != null) {
            explanationMap ??= {};
            explanationMap[lang] = trans['explanation'];
          }
        }
      }
      
      // Get options from first translation (or from translation field if provided)
      if (json['translation'] != null && json['translation'] is Map) {
        currentTranslation = Map<String, dynamic>.from(json['translation']);
        final transOptions = currentTranslation['options'] as List<dynamic>?;
        if (transOptions != null) {
          optionsList = transOptions
              .map((opt) => QuestionOption.fromJson(opt))
              .toList();
        }
      } else if (translations.isNotEmpty) {
        // Use first translation's options
        final firstTrans = translations[0] as Map<String, dynamic>;
        final transOptions = firstTrans['options'] as List<dynamic>?;
        if (transOptions != null) {
          optionsList = transOptions
              .map((opt) => QuestionOption.fromJson(opt))
              .toList();
        }
      }
    } else {
      // Old format: direct question map and options
      questionMap = Map<String, String>.from(json['question'] ?? {});
      optionsList = (json['options'] as List<dynamic>?)
          ?.map((opt) => QuestionOption.fromJson(opt))
          .toList() ?? [];
      explanationMap = json['explanation'] != null
          ? Map<String, String>.from(json['explanation'])
          : null;
    }
    
    // If still no options, try to get from root level
    if (optionsList.isEmpty && json['options'] != null) {
      optionsList = (json['options'] as List<dynamic>?)
          ?.map((opt) => QuestionOption.fromJson(opt))
          .toList() ?? [];
    }
    
    // If still no question text, try to get from root
    if (questionMap.isEmpty && json['questionText'] != null) {
      questionMap['en'] = json['questionText'];
    }

    return Question(
      id: json['_id'] ?? json['id'] ?? '',
      categoryId: categoryId,
      question: questionMap,
      options: optionsList,
      explanation: explanationMap,
      difficulty: json['difficulty'] ?? 'medium',
      points: json['points'] ?? 10,
      createdAt: json['createdAt'] != null 
          ? (json['createdAt'] is String 
              ? DateTime.parse(json['createdAt']) 
              : DateTime.fromMillisecondsSinceEpoch(json['createdAt']))
          : null,
      updatedAt: json['updatedAt'] != null
          ? (json['updatedAt'] is String 
              ? DateTime.parse(json['updatedAt']) 
              : DateTime.fromMillisecondsSinceEpoch(json['updatedAt']))
          : null,
      translation: currentTranslation,
    );
  }

  String getQuestionText(String language) {
    // First try current translation if available
    if (translation != null && translation!['questionText'] != null) {
      return translation!['questionText'].toString();
    }
    // Then try question map
    if (question.containsKey(language)) {
      return question[language]!;
    }
    if (question.containsKey('en')) {
      return question['en']!;
    }
    if (question.isNotEmpty) {
      return question.values.first;
    }
    return '';
  }

  String? getExplanationText(String language) {
    // First try current translation if available
    if (translation != null && translation!['explanation'] != null) {
      return translation!['explanation'].toString();
    }
    // Then try explanation map
    if (explanation == null) return null;
    if (explanation!.containsKey(language)) {
      return explanation![language];
    }
    if (explanation!.containsKey('en')) {
      return explanation!['en'];
    }
    if (explanation!.isNotEmpty) {
      return explanation!.values.first;
    }
    return null;
  }
}

class QuestionOption {
  final Map<String, String> text; // Multilingual
  final bool isCorrect;
  final int? order;

  QuestionOption({
    required this.text,
    required this.isCorrect,
    this.order,
  });

  factory QuestionOption.fromJson(Map<String, dynamic> json) {
    // Backend format: options have 'text' as string (not map)
    // Old format: options have 'text' as map
    Map<String, String> textMap = {};
    
    if (json['text'] is String) {
      // Backend format: single string text
      textMap['en'] = json['text'];
    } else if (json['text'] is Map) {
      // Old format: multilingual map
      textMap = Map<String, String>.from(json['text']);
    } else {
      textMap['en'] = '';
    }

    return QuestionOption(
      text: textMap,
      isCorrect: json['isCorrect'] ?? false,
      order: json['order'],
    );
  }

  String getText(String language) {
    if (text.containsKey(language)) {
      return text[language]!;
    }
    if (text.containsKey('en')) {
      return text['en']!;
    }
    if (text.isNotEmpty) {
      return text.values.first;
    }
    return '';
  }
}

class Conversation {
  final String id;
  final String userId;
  final String? adminId;
  final String status; // 'active', 'resolved', 'archived'
  final String? lastMessage;
  final DateTime? lastMessageAt;
  final int unreadCount;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Conversation({
    required this.id,
    required this.userId,
    this.adminId,
    this.status = 'active',
    this.lastMessage,
    this.lastMessageAt,
    this.unreadCount = 0,
    this.createdAt,
    this.updatedAt,
  });

  factory Conversation.fromJson(Map<String, dynamic> json) {
    // Handle lastMessage - can be a string or an object with content
    String? lastMessageText;
    if (json['lastMessage'] != null) {
      if (json['lastMessage'] is String) {
        lastMessageText = json['lastMessage'];
      } else if (json['lastMessage'] is Map) {
        lastMessageText = json['lastMessage']['content'] ?? json['lastMessage']['_id'];
      }
    }
    
    // Handle userId - can be string or object
    String userIdValue = '';
    if (json['userId'] != null) {
      if (json['userId'] is String) {
        userIdValue = json['userId'];
      } else if (json['userId'] is Map) {
        userIdValue = json['userId']['_id'] ?? json['userId']['id'] ?? '';
      }
    }
    
    // Handle adminId - can be string or object
    String? adminIdValue;
    if (json['adminId'] != null) {
      if (json['adminId'] is String) {
        adminIdValue = json['adminId'];
      } else if (json['adminId'] is Map) {
        adminIdValue = json['adminId']['_id'] ?? json['adminId']['id'];
      }
    }
    
    return Conversation(
      id: json['_id'] ?? json['id'] ?? '',
      userId: userIdValue,
      adminId: adminIdValue,
      status: json['status'] ?? 'active',
      lastMessage: lastMessageText,
      lastMessageAt: json['lastMessageAt'] != null 
          ? (json['lastMessageAt'] is String 
              ? DateTime.parse(json['lastMessageAt'])
              : DateTime.fromMillisecondsSinceEpoch(json['lastMessageAt']))
          : null,
      unreadCount: (json['unreadCount'] ?? 0) is int 
          ? json['unreadCount'] 
          : int.tryParse(json['unreadCount'].toString()) ?? 0,
      createdAt: json['createdAt'] != null 
          ? (json['createdAt'] is String 
              ? DateTime.parse(json['createdAt'])
              : DateTime.fromMillisecondsSinceEpoch(json['createdAt']))
          : null,
      updatedAt: json['updatedAt'] != null 
          ? (json['updatedAt'] is String 
              ? DateTime.parse(json['updatedAt'])
              : DateTime.fromMillisecondsSinceEpoch(json['updatedAt']))
          : null,
    );
  }
}

class Message {
  final String id;
  final String conversationId;
  final String senderId;
  final String senderType; // 'user' or 'admin'
  final String content;
  final bool isRead;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Message({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.senderType,
    required this.content,
    this.isRead = false,
    this.createdAt,
    this.updatedAt,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    // Handle conversationId - can be string or object
    String conversationIdValue = '';
    if (json['conversationId'] != null) {
      if (json['conversationId'] is String) {
        conversationIdValue = json['conversationId'];
      } else if (json['conversationId'] is Map) {
        conversationIdValue = json['conversationId']['_id'] ?? json['conversationId']['id'] ?? '';
      }
    }
    
    // Handle senderId - can be string or object
    String senderIdValue = '';
    if (json['senderId'] != null) {
      if (json['senderId'] is String) {
        senderIdValue = json['senderId'];
      } else if (json['senderId'] is Map) {
        senderIdValue = json['senderId']['_id'] ?? json['senderId']['id'] ?? '';
      }
    }
    
    return Message(
      id: json['_id'] ?? json['id'] ?? '',
      conversationId: conversationIdValue,
      senderId: senderIdValue,
      senderType: json['senderType'] ?? 'user',
      content: json['content'] ?? '',
      isRead: json['isRead'] ?? false,
      createdAt: json['createdAt'] != null 
          ? (json['createdAt'] is String 
              ? DateTime.parse(json['createdAt'])
              : DateTime.fromMillisecondsSinceEpoch(json['createdAt']))
          : null,
      updatedAt: json['updatedAt'] != null 
          ? (json['updatedAt'] is String 
              ? DateTime.parse(json['updatedAt'])
              : DateTime.fromMillisecondsSinceEpoch(json['updatedAt']))
          : null,
    );
  }
}

class Progress {
  final String id;
  final String userId;
  final String categoryId;
  final int totalQuestions;
  final int correctAnswers;
  final int incorrectAnswers;
  final double percentage;
  final DateTime? lastAttempted;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Progress({
    required this.id,
    required this.userId,
    required this.categoryId,
    this.totalQuestions = 0,
    this.correctAnswers = 0,
    this.incorrectAnswers = 0,
    this.percentage = 0.0,
    this.lastAttempted,
    this.createdAt,
    this.updatedAt,
  });

  factory Progress.fromJson(Map<String, dynamic> json) {
    return Progress(
      id: json['_id'] ?? json['id'] ?? '',
      userId: json['userId'] ?? '',
      categoryId: json['categoryId'] ?? '',
      totalQuestions: json['totalQuestions'] ?? 0,
      correctAnswers: json['correctAnswers'] ?? 0,
      incorrectAnswers: json['incorrectAnswers'] ?? 0,
      percentage: (json['percentage'] ?? 0).toDouble(),
      lastAttempted: json['lastAttempted'] != null 
          ? DateTime.parse(json['lastAttempted']) 
          : null,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
    );
  }
}

class Material {
  final String id;
  final String title;
  final String description;
  final String fileUrl;
  final String fileName;
  final int fileSize;
  final String mimeType;
  final String? uploadedByName;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Material({
    required this.id,
    required this.title,
    required this.description,
    required this.fileUrl,
    required this.fileName,
    required this.fileSize,
    required this.mimeType,
    this.uploadedByName,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  factory Material.fromJson(Map<String, dynamic> json) {
    return Material(
      id: json['_id'] ?? json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      fileUrl: json['fileUrl'] ?? '',
      fileName: json['fileName'] ?? '',
      fileSize: json['fileSize'] ?? 0,
      mimeType: json['mimeType'] ?? 'application/pdf',
      uploadedByName: json['uploadedBy'] is Map
          ? json['uploadedBy']['name']
          : null,
      isActive: json['isActive'] ?? true,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
    );
  }

  String get fileSizeFormatted {
    if (fileSize < 1024) return '$fileSize B';
    if (fileSize < 1024 * 1024) return '${(fileSize / 1024).toStringAsFixed(1)} KB';
    return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

class Language {
  final String id;
  final String code;
  final String name;
  final String nativeName;
  final String? flag;
  final bool isActive;
  final int order;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Language({
    required this.id,
    required this.code,
    required this.name,
    required this.nativeName,
    this.flag,
    this.isActive = true,
    this.order = 0,
    this.createdAt,
    this.updatedAt,
  });

  factory Language.fromJson(Map<String, dynamic> json) {
    return Language(
      id: json['_id'] ?? json['id'] ?? '',
      code: json['code'] ?? '',
      name: json['name'] ?? '',
      nativeName: json['nativeName'] ?? '',
      flag: json['flag'],
      isActive: json['isActive'] ?? true,
      order: json['order'] ?? 0,
      createdAt: json['createdAt'] != null 
          ? (json['createdAt'] is String 
              ? DateTime.parse(json['createdAt']) 
              : DateTime.fromMillisecondsSinceEpoch(json['createdAt']))
          : null,
      updatedAt: json['updatedAt'] != null
          ? (json['updatedAt'] is String 
              ? DateTime.parse(json['updatedAt']) 
              : DateTime.fromMillisecondsSinceEpoch(json['updatedAt']))
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'name': name,
      'nativeName': nativeName,
      'flag': flag,
      'isActive': isActive,
      'order': order,
    };
  }
}

