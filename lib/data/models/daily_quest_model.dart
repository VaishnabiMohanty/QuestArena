enum DailyQuestStatus { unanswered, correct, wrong }

class DailyQuest {
  final String id;
  final String questionId;
  final String question;
  final String correctAnswer;
  final List<String> options;
  final String categoryName;
  final int categoryId;
  final DailyQuestStatus status;
  final String? selectedAnswer;

  DailyQuest({
    required this.id,
    required this.questionId,
    required this.question,
    required this.correctAnswer,
    required this.options,
    required this.categoryName,
    required this.categoryId,
    this.status = DailyQuestStatus.unanswered,
    this.selectedAnswer,
  });

  bool get isCompleted => status != DailyQuestStatus.unanswered;

  Map<String, dynamic> toJson() => {
    'id': id,
    'questionId': questionId,
    'question': question,
    'correctAnswer': correctAnswer,
    'options': options,
    'categoryName': categoryName,
    'categoryId': categoryId,
    'status': status.name,
    'selectedAnswer': selectedAnswer,
  };

  factory DailyQuest.fromJson(Map<String, dynamic> json) => DailyQuest(
    id: json['id'],
    questionId: json['questionId'] ?? '',
    question: json['question'],
    correctAnswer: json['correctAnswer'],
    options: List<String>.from(json['options']),
    categoryName: json['categoryName'],
    categoryId: json['categoryId'] ?? 0,
    status: DailyQuestStatus.values.byName(json['status'] ?? 'unanswered'),
    selectedAnswer: json['selectedAnswer'],
  );

  DailyQuest copyWith({
    DailyQuestStatus? status,
    String? selectedAnswer,
  }) => DailyQuest(
    id: id,
    questionId: questionId,
    question: question,
    correctAnswer: correctAnswer,
    options: options,
    categoryName: categoryName,
    categoryId: categoryId,
    status: status ?? this.status,
    selectedAnswer: selectedAnswer ?? this.selectedAnswer,
  );
}
