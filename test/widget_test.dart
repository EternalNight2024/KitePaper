import 'package:flutter_test/flutter_test.dart';

import 'package:kitepaper/core/models.dart';
import 'package:kitepaper/core/qti.dart';

void main() {
  const questions = [
    Question(
      id: 'q1',
      stem: '1 + 1 = ?',
      type: QuestionType.single,
      options: ['1', '2'],
      answers: ['B'],
      score: 2,
      knowledge: '数学',
      analysis: '基础加法',
    ),
    Question(
      id: 'q2',
      stem: '选出偶数',
      type: QuestionType.multiple,
      options: ['2', '3', '4'],
      answers: ['A', 'C'],
      score: 4,
    ),
    Question(
      id: 'q3',
      stem: '填空：Flutter',
      type: QuestionType.fillBlank,
      answers: ['flutter'],
      score: 2,
    ),
    Question(
      id: 'q4',
      stem: '简述你的理解',
      type: QuestionType.essay,
      answers: ['参考答案'],
      score: 6,
    ),
  ];

  final paper = Paper(
    id: 'p1',
    title: '测试卷',
    questions: questions,
    createdAt: DateTime(2026, 1, 1),
  );

  test('QTI 导出后可完整导入', () {
    final xml = exportQti(paper);
    expect(xml, contains('questestinterop'));
    expect(xml, contains(qtiProfile));

    final restored = importQti(xml);
    expect(restored.title, '测试卷');
    expect(restored.questions.length, questions.length);
    for (var i = 0; i < questions.length; i++) {
      expect(restored.questions[i].type, questions[i].type);
      expect(restored.questions[i].stem, questions[i].stem);
      expect(restored.questions[i].options, questions[i].options);
      expect(restored.questions[i].answers, questions[i].answers);
      expect(restored.questions[i].score, questions[i].score);
      expect(restored.questions[i].analysis, questions[i].analysis);
    }
  });

  test('非法 QTI 会抛出 FormatException', () {
    expect(
      () => importQti('<not-qti/>'),
      throwsA(isA<FormatException>()),
    );
  });

  test('客观题判分与简答题待批阅', () {
    final result = gradePaper(paper, {
      'q1': ['B'],
      'q2': ['A', 'C'],
      'q3': [' Flutter '],
      'q4': ['任意作答'],
    });

    expect(result.score, 8);
    expect(result.total, 14);
    expect(result.correctCount, 3);
    expect(result.wrongCount, 0);
    expect(result.pendingCount, 1);
  });

  test('错误与未作答计入错题', () {
    final result = gradePaper(paper, {
      'q1': ['A'],
      'q2': ['A'],
    });

    expect(result.score, 0);
    expect(result.correctCount, 0);
    expect(result.wrongCount, 3);
    expect(result.wrongStems.length, 3);
    expect(result.pendingCount, 1);
  });

  test('教师/学生模式编码可持久化往返', () {
    for (final mode in AppMode.values) {
      expect(appModeFromCode(mode.code), mode);
    }
    expect(appModeFromCode(null), AppMode.teacher);
    expect(appModeFromCode('unknown'), AppMode.teacher);
    expect(AppMode.teacher.label, '教师模式');
    expect(AppMode.student.label, '学生模式');
  });
}
