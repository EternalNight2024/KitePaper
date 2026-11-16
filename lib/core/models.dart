import 'dart:math';

/// 应用使用模式：教师负责出题与组卷，学生负责导入与练习。
enum AppMode { teacher, student }

extension AppModeX on AppMode {
  String get code => this == AppMode.teacher ? 'teacher' : 'student';

  String get label => this == AppMode.teacher ? '教师模式' : '学生模式';

  String get shortLabel => this == AppMode.teacher ? '教师' : '学生';

  String get description => this == AppMode.teacher
      ? '管理题库、手动组卷、导出 QTI 分享'
      : '导入试卷、逐题刷题、查看成绩与错题';
}

AppMode appModeFromCode(String? code) =>
    code == 'student' ? AppMode.student : AppMode.teacher;

enum QuestionType { single, multiple, trueFalse, fillBlank, essay }

extension QuestionTypeX on QuestionType {
  String get code => switch (this) {
        QuestionType.single => 'single',
        QuestionType.multiple => 'multiple',
        QuestionType.trueFalse => 'trueFalse',
        QuestionType.fillBlank => 'fillBlank',
        QuestionType.essay => 'essay',
      };

  String get label => switch (this) {
        QuestionType.single => '单选题',
        QuestionType.multiple => '多选题',
        QuestionType.trueFalse => '判断题',
        QuestionType.fillBlank => '填空题',
        QuestionType.essay => '简答题',
      };

  bool get hasOptions =>
      this == QuestionType.single ||
      this == QuestionType.multiple ||
      this == QuestionType.trueFalse;

  bool get isObjective => this != QuestionType.essay;
}

QuestionType questionTypeFromCode(String? code) => QuestionType.values.firstWhere(
      (type) => type.code == code,
      orElse: () => QuestionType.single,
    );

const optionLetters = ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H'];

String optionLetter(int index) =>
    index < optionLetters.length ? optionLetters[index] : '${index + 1}';

String newId() =>
    '${DateTime.now().microsecondsSinceEpoch}-${Random().nextInt(99999)}';

String _norm(String value) =>
    value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), '');

class Question {
  final String id;
  final String stem;
  final QuestionType type;
  final List<String> options;
  final List<String> answers;
  final double score;
  final String knowledge;
  final String analysis;

  const Question({
    required this.id,
    required this.stem,
    required this.type,
    this.options = const [],
    this.answers = const [],
    this.score = 2,
    this.knowledge = '',
    this.analysis = '',
  });

  factory Question.fromJson(Map<String, dynamic> json) => Question(
        id: json['id'] as String? ?? '',
        stem: json['stem'] as String? ?? '',
        type: questionTypeFromCode(json['type'] as String?),
        options: _strings(json['options']),
        answers: _strings(json['answers']),
        score: (json['score'] as num? ?? 2).toDouble(),
        knowledge: json['knowledge'] as String? ?? '',
        analysis: json['analysis'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'stem': stem,
        'type': type.code,
        'options': options,
        'answers': answers,
        'score': score,
        'knowledge': knowledge,
        'analysis': analysis,
      };

  bool isCorrect(List<String> response) {
    if (!type.isObjective) return false;
    final expected = answers.map(_norm).where((e) => e.isNotEmpty).toList();
    final actual = response.map(_norm).where((e) => e.isNotEmpty).toList();
    if (expected.isEmpty || actual.isEmpty) return false;
    if (type == QuestionType.fillBlank) {
      return actual.length == 1 && expected.contains(actual.first);
    }
    expected.sort();
    actual.sort();
    if (expected.length != actual.length) return false;
    for (var i = 0; i < expected.length; i++) {
      if (expected[i] != actual[i]) return false;
    }
    return true;
  }
}

class Paper {
  final String id;
  final String title;
  final String description;
  final List<Question> questions;
  final int durationMinutes;
  final DateTime createdAt;

  const Paper({
    required this.id,
    required this.title,
    this.description = '',
    required this.questions,
    this.durationMinutes = 30,
    required this.createdAt,
  });

  double get totalScore =>
      questions.fold(0.0, (sum, question) => sum + question.score);

  factory Paper.fromJson(Map<String, dynamic> json) => Paper(
        id: json['id'] as String? ?? newId(),
        title: json['title'] as String? ?? '未命名试卷',
        description: json['description'] as String? ?? '',
        questions: (json['questions'] as List<dynamic>? ?? [])
            .map((e) => Question.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
        durationMinutes: json['durationMinutes'] as int? ?? 30,
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
            DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'questions': questions.map((q) => q.toJson()).toList(),
        'durationMinutes': durationMinutes,
        'createdAt': createdAt.toIso8601String(),
      };
}

class ExamResult {
  final String id;
  final String paperId;
  final String paperTitle;
  final double score;
  final double total;
  final int correctCount;
  final int wrongCount;
  final int pendingCount;
  final List<String> wrongStems;
  final DateTime finishedAt;

  const ExamResult({
    required this.id,
    required this.paperId,
    required this.paperTitle,
    required this.score,
    required this.total,
    required this.correctCount,
    required this.wrongCount,
    required this.pendingCount,
    required this.wrongStems,
    required this.finishedAt,
  });

  factory ExamResult.fromJson(Map<String, dynamic> json) => ExamResult(
        id: json['id'] as String? ?? newId(),
        paperId: json['paperId'] as String? ?? '',
        paperTitle: json['paperTitle'] as String? ?? '',
        score: (json['score'] as num? ?? 0).toDouble(),
        total: (json['total'] as num? ?? 0).toDouble(),
        correctCount: json['correctCount'] as int? ?? 0,
        wrongCount: json['wrongCount'] as int? ?? 0,
        pendingCount: json['pendingCount'] as int? ?? 0,
        wrongStems: _strings(json['wrongStems']),
        finishedAt: DateTime.tryParse(json['finishedAt'] as String? ?? '') ??
            DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'paperId': paperId,
        'paperTitle': paperTitle,
        'score': score,
        'total': total,
        'correctCount': correctCount,
        'wrongCount': wrongCount,
        'pendingCount': pendingCount,
        'wrongStems': wrongStems,
        'finishedAt': finishedAt.toIso8601String(),
      };
}

ExamResult gradePaper(
  Paper paper,
  Map<String, List<String>> responses,
) {
  var score = 0.0;
  var correct = 0;
  var wrong = 0;
  var pending = 0;
  final wrongStems = <String>[];

  for (final question in paper.questions) {
    final response = responses[question.id] ?? const <String>[];
    if (!question.type.isObjective) {
      pending++;
      continue;
    }
    if (question.isCorrect(response)) {
      correct++;
      score += question.score;
    } else {
      wrong++;
      wrongStems.add(question.stem);
    }
  }

  return ExamResult(
    id: newId(),
    paperId: paper.id,
    paperTitle: paper.title,
    score: score,
    total: paper.totalScore,
    correctCount: correct,
    wrongCount: wrong,
    pendingCount: pending,
    wrongStems: wrongStems,
    finishedAt: DateTime.now(),
  );
}

List<String> _strings(dynamic value) => (value as List<dynamic>? ?? [])
    .map((item) => item.toString())
    .toList();
