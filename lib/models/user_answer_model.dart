class UserAnswerModel {
  final String questionId;
  final int selectedIndex;
  final bool isCorrect;
  final bool isFirstCorrect;

  UserAnswerModel({
    required this.questionId,
    required this.selectedIndex,
    required this.isCorrect,
    this.isFirstCorrect = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'questionId': questionId,
      'selectedIndex': selectedIndex,
      'isCorrect': isCorrect,
      'isFirstCorrect': isFirstCorrect,
    };
  }

  factory UserAnswerModel.fromMap(Map<String, dynamic> map) {
    return UserAnswerModel(
      questionId: map['questionId'] ?? '',
      selectedIndex: map['selectedIndex'] ?? 0,
      isCorrect: map['isCorrect'] ?? false,
      isFirstCorrect: map['isFirstCorrect'] ?? false,
    );
  }
}

