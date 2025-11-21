class QuestionModel {
  final String id;
  final String text;
  final List<String> choices;
  final int correctIndex;

  QuestionModel({
    required this.id,
    required this.text,
    required this.choices,
    required this.correctIndex,
  });

  factory QuestionModel.fromMap(Map<String, dynamic> map, String id) {
    return QuestionModel(
      id: id,
      text: map['text'] ?? '',
      choices: List<String>.from(map['choices'] ?? []),
      correctIndex: map['correctIndex'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'text': text,
      'choices': choices,
      'correctIndex': correctIndex,
    };
  }
}

