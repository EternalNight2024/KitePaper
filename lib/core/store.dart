import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'models.dart';

class AppStore extends ChangeNotifier {
  AppStore();

  static const _questionsKey = 'kitepaper.questions';
  static const _papersKey = 'kitepaper.papers';
  static const _resultsKey = 'kitepaper.results';
  static const _modeKey = 'kitepaper.mode';

  final List<Question> _questions = [];
  final List<Paper> _papers = [];
  final List<ExamResult> _results = [];
  bool _loaded = false;
  AppMode _mode = AppMode.teacher;

  List<Question> get questions => List.unmodifiable(_questions);
  List<Paper> get papers => List.unmodifiable(_papers);
  List<ExamResult> get results => List.unmodifiable(_results);
  bool get loaded => _loaded;
  AppMode get mode => _mode;

  Future<void> load() async {
    if (_loaded) return;
    final prefs = await SharedPreferences.getInstance();
    _mode = appModeFromCode(prefs.getString(_modeKey));
    _questions.addAll(_read(prefs.getString(_questionsKey), Question.fromJson));
    _papers.addAll(_read(prefs.getString(_papersKey), Paper.fromJson));
    _results.addAll(_read(prefs.getString(_resultsKey), ExamResult.fromJson));

    if (_questions.isEmpty && _papers.isEmpty) {
      await restoreTutorial();
    } else {
      await _persist();
    }
    _loaded = true;
    notifyListeners();
  }

  Future<void> setMode(AppMode mode) async {
    if (_mode == mode) return;
    _mode = mode;
    await _persist();
    notifyListeners();
  }

  /// 写入一份内置教程数据与教程试卷；已存在时按 id 补齐缺失的教程题。
  Future<void> restoreTutorial() async {
    final existing = _questions.map((q) => q.id).toSet();
    for (final question in _tutorialQuestions) {
      if (!existing.contains(question.id)) _questions.add(question);
    }
    if (!_papers.any((p) => p.id == _tutorialPaperId)) {
      _papers.insert(
        0,
        Paper(
          id: _tutorialPaperId,
          title: '纸鸢使用教程 · 离线体验',
          description: '内置教程卷：五道题覆盖全部题型，可直接练习或导出为 QTI 分享。',
          questions: List.unmodifiable(_tutorialQuestions),
          durationMinutes: 30,
          createdAt: DateTime.now(),
        ),
      );
    }
    await _persist();
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
    await prefs.setString(_modeKey, _mode.code);
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

const _tutorialPaperId = 'kitepaper-tutorial';

/// 内置教程数据：题目本身即是对五种题型和两种身份的学习。
final List<Question> _tutorialQuestions = [
  const Question(
    id: 'tutorial-q1',
    stem: '教师想把一套练习分享给同事，正确的离线流程是？',
    type: QuestionType.single,
    options: [
      '题库选题 → 组卷 → 导出 QTI 文件',
      '直接把手机交给同事',
      '在成绩页点击「导出」',
      '重启应用后自动分享',
    ],
    answers: ['A'],
    score: 2,
    knowledge: '教师模式 · 分享',
    analysis: '教师模式依次进入「题库」选题、「组卷」生成试卷、「试卷」导出 .qti 文件；'
        '对方在学生模式导入该文件即可刷题。',
  ),
  const Question(
    id: 'tutorial-q2',
    stem: '学生模式中可以完成哪些操作？（多选）',
    type: QuestionType.multiple,
    options: ['导入 QTI 试卷', '逐题练习并即时判分', '查看成绩与错题本', '修改别人的试卷'],
    answers: ['A', 'B', 'C'],
    score: 4,
    knowledge: '学生模式 · 功能',
    analysis: '学生可导入、练习、查看成绩与错题，但不会改动原始题目；试卷内容由教师维护。',
  ),
  const Question(
    id: 'tutorial-q3',
    stem: '简答题在纯离线版本中会被自动计入总分。',
    type: QuestionType.trueFalse,
    options: ['正确', '错误'],
    answers: ['B'],
    score: 2,
    knowledge: '判分规则',
    analysis: '简答题标记为「待批阅」，不计入自动得分，等待服务端或教师批阅接入后补齐。',
  ),
  const Question(
    id: 'tutorial-q4',
    stem: '纸鸢导出的试卷文件后缀名是 ______。',
    type: QuestionType.fillBlank,
    answers: ['qti'],
    score: 2,
    knowledge: 'QTI 互操作',
    analysis: '试卷导出为 .qti 文件（QTI 1.2 单文件子集），导入导出无损，第三方工具可读取标准结构。',
  ),
  const Question(
    id: 'tutorial-q5',
    stem: '结合实际应用，简述教师模式与学生模式的分工。',
    type: QuestionType.essay,
    answers: [
      '教师模式负责维护题库、手动组卷并导出 QTI 分享；学生模式负责导入试卷、'
      '逐题练习、即时判分、交卷评分以及查看成绩和错题本。',
    ],
    score: 6,
    knowledge: '综合 · 离线流程',
    analysis: '两种模式数据互通：题库与试卷保存在本机，通过 QTI 文件完成跨设备分享；'
    '在线批阅与云端同步为后续功能预留位置。',
  ),
];
