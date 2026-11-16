import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../core/app_background.dart';
import '../core/layout.dart';
import '../core/models.dart';
import '../core/store.dart';
import '../theme/app_theme.dart';
import 'shared_widgets.dart';

class ExamPage extends StatefulWidget {
  const ExamPage({super.key, required this.paper});

  final Paper paper;

  @override
  State<ExamPage> createState() => _ExamPageState();
}

class _ExamPageState extends State<ExamPage> {
  final Map<String, List<String>> _responses = {};
  final TextEditingController _text = TextEditingController();
  int _index = 0;
  ExamResult? _result;

  Question get _current => widget.paper.questions[_index];
  List<String> get _answer => _responses[_current.id] ?? const <String>[];

  @override
  void initState() {
    super.initState();
    _syncText();
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  void _syncText() {
    final question = _current;
    _text.text = question.type.hasOptions
        ? ''
        : (_responses[question.id]?.first ?? '');
  }

  void _select(String letter) {
    setState(() {
      final current = List<String>.from(_answer);
      if (_current.type == QuestionType.multiple) {
        if (!current.remove(letter)) {
          current.add(letter);
        }
      } else {
        current
          ..clear()
          ..add(letter);
      }
      _responses[_current.id] = current;
    });
  }

  void _saveText() {
    if (_current.type.hasOptions) return;
    final value = _text.text.trim();
    if (value.isEmpty) {
      _responses.remove(_current.id);
    } else {
      _responses[_current.id] = [value];
    }
  }

  void _move(int delta) {
    _saveText();
    final next = (_index + delta).clamp(0, widget.paper.questions.length - 1);
    if (next == _index) return;
    setState(() {
      _index = next;
      _syncText();
    });
  }

  Future<void> _submit() async {
    _saveText();
    final result = gradePaper(widget.paper, _responses);
    await store.addResult(result);
    if (!mounted) return;
    setState(() => _result = result);
    GlassToast.show(context,
        message: '交卷完成：${result.score.toStringAsFixed(0)} / '
            '${result.total.toStringAsFixed(0)} 分');
  }

  @override
  Widget build(BuildContext context) {
    return GlassScaffold(
      background: const AppBackground(),
      backgroundColor: appBackgroundColor(Theme.of(context).brightness),
      statusBarStyle: GlassStatusBarStyle.auto,
      appBar: GlassAppBar(
        centerTitle: false,
        title: Text(widget.paper.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleMedium),
        actions: [
          if (_result == null)
            // AppBar actions 为无界宽度，GlassButton.custom 需要显式宽度约束。
            SizedBox(
              width: 68,
              child: GlassButton.custom(
                onTap: _submit,
                height: 32,
                shape: const LiquidRoundedSuperellipse(borderRadius: 11),
                child: Center(
                  child: Text(
                    '交卷',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: CupertinoTheme.of(context)
                          .textTheme
                          .textStyle
                          .color ??
                          CupertinoColors.label,
                      fontFamily: AppTheme.fontFamilyOverride,
                    ),
                  ),
                ),
              ),
            ),
          const SizedBox(width: 4),
        ],
      ),
      body: _result == null ? _questionView() : _resultView(),
    );
  }

  Widget _questionView() {
    final theme = Theme.of(context);
    final question = _current;
    final answered = _answer.isNotEmpty;
    final correct = question.type.isObjective && answered
        ? question.isCorrect(_answer)
        : null;

    return ListView(
      padding: EdgeInsets.fromLTRB(20, appBarSafeTop(context) + 8, 20, 40),
      children: [
        Row(
          children: [
            Text(
              '第 ${_index + 1} / ${widget.paper.questions.length} 题',
              style: theme.textTheme.labelSmall
                  ?.copyWith(letterSpacing: 0.8, fontWeight: FontWeight.w700),
            ),
            const Spacer(),
            Text('${question.type.label} · ${question.score} 分',
                style: theme.textTheme.bodySmall),
          ],
        ),
        const SizedBox(height: 10),
        GlassContainer.card(
          surfaceStyle: GlassSurfaceStyle.solid,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(question.stem, style: theme.textTheme.titleSmall),
              if (question.knowledge.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(question.knowledge, style: theme.textTheme.bodySmall),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (question.type.hasOptions)
          GlassGroupedSection(
            surfaceStyle: GlassSurfaceStyle.solid,
            margin: EdgeInsets.zero,
            children: [
              for (var i = 0; i < question.options.length; i++)
                GlassListTile(
                  leading: CheckMark(
                      selected: _answer.contains(optionLetter(i))),
                  title: Text(
                    '${optionLetter(i)}. ${question.options[i]}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: _answer.contains(optionLetter(i))
                          ? AppTheme.accent
                          : null,
                      fontWeight: _answer.contains(optionLetter(i))
                          ? FontWeight.w600
                          : FontWeight.w400,
                    ),
                  ),
                  onTap: () => _select(optionLetter(i)),
                ),
            ],
          )
        else
          GlassContainer.card(
            surfaceStyle: GlassSurfaceStyle.solid,
            padding: const EdgeInsets.all(14),
            child: GlassTextArea(
              controller: _text,
              placeholder: question.type == QuestionType.essay
                  ? '作答（交卷后标记为待批阅）'
                  : '填写答案',
              minLines: question.type == QuestionType.essay ? 5 : 1,
              maxLines: question.type == QuestionType.essay ? 8 : 3,
              onChanged: (value) {
                final trimmed = value.trim();
                if (trimmed.isEmpty) {
                  _responses.remove(question.id);
                } else {
                  _responses[question.id] = [trimmed];
                }
              },
            ),
          ),
        if (correct != null)
          Padding(
            padding: const EdgeInsets.only(top: 14),
            child: _FeedbackCard(
              correct: correct,
              answers: question.answers,
              analysis: question.analysis,
            ),
          ),
        const SizedBox(height: 22),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            ActionGlassButton(
              label: '上一题',
              icon: CupertinoIcons.chevron_left,
              compact: true,
              onTap: () => _move(-1),
            ),
            ActionGlassButton(
              label: '下一题',
              icon: CupertinoIcons.chevron_right,
              compact: true,
              onTap: () => _move(1),
            ),
            ActionGlassButton(
              label: '交卷',
              icon: CupertinoIcons.checkmark,
              compact: true,
              prominent: true,
              accent: AppTheme.student,
              onTap: _submit,
            ),
          ],
        ),
      ],
    );
  }

  Widget _resultView() {
    final result = _result!;
    final theme = Theme.of(context);
    return ListView(
      padding: EdgeInsets.fromLTRB(20, appBarSafeTop(context) + 8, 20, 40),
      children: [
        GlassContainer.card(
          surfaceStyle: GlassSurfaceStyle.solid,
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${result.score.toStringAsFixed(0)} / '
                  '${result.total.toStringAsFixed(0)}',
                  style: theme.textTheme.displaySmall),
              const SizedBox(height: 6),
              Text(
                  '答对 ${result.correctCount} · 答错 ${result.wrongCount} · '
                  '待批阅 ${result.pendingCount}',
                  style: theme.textTheme.bodySmall),
            ],
          ),
        ),
        const SizedBox(height: 22),
        sectionHeader(context, '本次错题 · ${result.wrongStems.length}'),
        if (result.wrongStems.isEmpty)
          GlassContainer.card(
            surfaceStyle: GlassSurfaceStyle.solid,
            child: const Text('全部答对，太棒了'),
          )
        else
          GlassGroupedSection(
            surfaceStyle: GlassSurfaceStyle.solid,
            margin: EdgeInsets.zero,
            children: [
              for (final stem in result.wrongStems)
                GlassListTile(
                  leading: Icon(CupertinoIcons.xmark_circle,
                      color: AppTheme.destructive),
                  title: Text(
                    stem,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
            ],
          ),
        const SizedBox(height: 22),
        ActionGlassButton(
          label: '返回试卷列表',
          icon: CupertinoIcons.chevron_left,
          onTap: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }
}

class _FeedbackCard extends StatelessWidget {
  const _FeedbackCard({
    required this.correct,
    required this.answers,
    required this.analysis,
  });

  final bool correct;
  final List<String> answers;
  final String analysis;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = correct ? AppTheme.success : AppTheme.destructive;
    return GlassContainer.card(
      surfaceStyle: GlassSurfaceStyle.solid,
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            correct
                ? CupertinoIcons.checkmark_circle_fill
                : CupertinoIcons.xmark_circle_fill,
            size: 20,
            color: color,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(correct ? '回答正确' : '回答错误',
                    style: theme.textTheme.titleSmall?.copyWith(color: color)),
                if (!correct && answers.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text('正确答案 ${answers.join(' / ')}',
                      style: theme.textTheme.bodySmall),
                ],
                if (analysis.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(analysis,
                      maxLines: 3, style: theme.textTheme.bodySmall),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
