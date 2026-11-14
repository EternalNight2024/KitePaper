import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'models.dart';

class AppStore extends ChangeNotifier {
  AppStore();

  static const _questionsKey = 'kitepaper.questions';
  static const _papersKey = 'kitepaper.papers';
  static const _resultsKey = 'kitepaper.results';

  final List<Question> _questions = [];
  final List<Paper> _papers = [];
  final List<ExamResult> _results = [];
  bool _loaded = false;

  List<Question> get questions => List.unmodifiable(_questions);
  List<Paper> get papers => List.unmodifiable(_papers);
  List<ExamResult> get results => List.unmodifiable(_results);
  bool get loaded => _loaded;

  Future<void> load() async {
    if (_loaded) return;
    final prefs = await SharedPreferences.getInstance();
    _questions.addAll(_read(prefs.getString(_questionsKey), Question.fromJson));
    _papers.addAll(_read(prefs.getString(_papersKey), Paper.fromJson));
    _results.addAll(_read(prefs.getString(_resultsKey), ExamResult.fromJson));

    if (_questions.isEmpty && _papers.isEmpty) {
      _questions.addAll(_demoQuestions);
      _papers.add(Paper(
        id: 'demo-paper',
        title: '纸鸢示例试卷 · 离线体验',
        description: '内置示例，可直接练习，也可导出为 QTI 分享给他人。',
        questions: List.unmodifiable(_demoQuestions),
        durationMinutes: 30,
        createdAt: DateTime.now(),
      ));
      await _persist();
    }
    _loaded = true;
    notifyListeners();
  }

  Future<void> addQuestion(Question question) async {
    _questions.add(question);
    await _persist();
    notifyListeners();
  }

  Future<void> addQuestions(Iterable<Question> items) async {
    final existing = _questions.map((q) => q.id).toSet();
    for (final question in items) {
      _questions.add(existing.contains(question.id)
          ? Question(
              id: newId(),
              stem: question.stem,
              type: question.type,
              options: question.options,
              answers: question.answers,
              score: question.score,
              knowledge: question.knowledge,
              analysis: question.analysis,
            )
          : question);
    }
    await _persist();
    notifyListeners();
  }

  Future<void> removeQuestion(String id) async {
    _questions.removeWhere((question) => question.id == id);
    await _persist();
    notifyListeners();
  }

  Future<void> addPaper(Paper paper) async {
    _papers.insert(0, paper);
    await _persist();
    notifyListeners();
  }

  Future<void> removePaper(String id) async {
    _papers.removeWhere((paper) => paper.id == id);
    await _persist();
    notifyListeners();
  }

  Future<void> addResult(ExamResult result) async {
    _results.insert(0, result);
    await _persist();
    notifyListeners();
  }

  Future<void> clearResults() async {
    _results.clear();
    await _persist();
    notifyListeners();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _questionsKey, jsonEncode(_questions.map((q) => q.toJson()).toList()));
    await prefs.setString(
        _papersKey, jsonEncode(_papers.map((p) => p.toJson()).toList()));
    await prefs.setString(
        _resultsKey, jsonEncode(_results.map((r) => r.toJson()).toList()));
  }
}

List<T> _read<T>(
  String? raw,
  T Function(Map<String, dynamic> json) fromJson,
) {
  if (raw == null || raw.isEmpty) return <T>[];
  try {
    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .map((item) => fromJson(Map<String, dynamic>.from(item as Map)))
        .toList();
  } catch (_) {
    return <T>[];
  }
}

final AppStore store = AppStore();

final List<Question> _demoQuestions = [
  const Question(
    id: 'demo-q1',
    stem: 'Flutter 中用于描述界面配置的基本单元是？',
    type: QuestionType.single,
    options: ['Widget', 'Activity', 'ViewController', 'Component'],
    answers: ['A'],
    score: 2,
    knowledge: 'Flutter 基础',
    analysis: 'Flutter 中几乎所有界面元素都是 Widget，通过组合 Widget 构建 UI。',
  ),
  const Question(
    id: 'demo-q2',
    stem: '以下哪些属于 Dart 的核心类型？',
    type: QuestionType.multiple,
    options: ['String', 'int', 'Widget', 'List'],
    answers: ['A', 'B', 'D'],
    score: 4,
    knowledge: 'Dart 语言',
    analysis: 'Widget 是 Flutter 框架中的类，不是 Dart 语言内置类型。',
  ),
  const Question(
    id: 'demo-q3',
    stem: 'QTI 是一套用于试题与测验互操作的标准。',
    type: QuestionType.trueFalse,
    options: ['正确', '错误'],
    answers: ['A'],
    score: 2,
    knowledge: 'QTI 标准',
    analysis: 'QTI（Question and Test Interoperability）由 IMS Global 制定。',
  ),
  const Question(
    id: 'demo-q4',
    stem: 'Flutter 布局中父级向下传递的尺寸限制称为 ______。',
    type: QuestionType.fillBlank,
    answers: ['constraints'],
    score: 2,
    knowledge: 'Flutter 布局',
    analysis: '父 Widget 传递 constraints，子 Widget 在其约束内决定自身大小。',
  ),
  const Question(
    id: 'demo-q5',
    stem: '简述 StatelessWidget 与 StatefulWidget 的区别。',
    type: QuestionType.essay,
    answers: ['StatelessWidget 无可变状态；StatefulWidget 持有 State 并可调用 setState 重建。'],
    score: 6,
    knowledge: 'Flutter 基础',
    analysis: '简答题在纯离线模式下标记为「待批阅」，不计入自动得分。',
  ),
];
