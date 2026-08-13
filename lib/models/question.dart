import 'dart:math';

class Question {
  final String id;
  final String text;
  final List<String> options;
  final int correctIndex;
  final String explanation;
  final int difficulty;

  Question({
    required this.id,
    required this.text,
    required this.options,
    required this.correctIndex,
    required this.explanation,
    this.difficulty = 1,
  });

  factory Question.shuffled(Question original) {
    final indices = List<int>.generate(original.options.length, (i) => i);
    indices.shuffle(Random());
    return Question(
      id: original.id,
      text: original.text,
      explanation: original.explanation,
      difficulty: original.difficulty,
      options: indices.map((i) => original.options[i]).toList(),
      correctIndex: indices.indexOf(original.correctIndex),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'text': text,
      'options': options,
      'correctIndex': correctIndex,
      'explanation': explanation,
      'difficulty': difficulty,
    };
  }

  factory Question.fromMap(Map<dynamic, dynamic> map) {
    return Question(
      id: map['id'] as String? ?? '',
      text: map['text'] as String? ?? '',
      options: List<String>.from(map['options'] as List? ?? []),
      correctIndex: map['correctIndex'] as int? ?? 0,
      explanation: map['explanation'] as String? ?? '',
      difficulty: map['difficulty'] as int? ?? 1,
    );
  }
}
