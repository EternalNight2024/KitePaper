import 'package:flutter/material.dart';

import '../core/models.dart';
import '../core/store.dart';
import '../core/ui.dart';
import '../theme/app_theme.dart';

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
    // 选择题的作答来自选项点击，不能用户输入框内容覆盖/清除。
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
  }

  @override
  Widget build(BuildContext context) {
    return GlassPageScaffold(
      title: widget.paper.title,
      action: _result == null
          ? GlassButton(
              label: '交卷',
              compact: true,
              onPressed: _submit,
            )
          : null,
      child: _result == null ? _questionView() : _resultView(),
    );
  }

  Widget _questionView() {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final question = _current;
    final answered = _answer.isNotEmpty;
    final correct = question.type.isObjective && answered
        ? question.isCorrect(_answer)
        : null;

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 4, 18, 32),
      children: [
        Row(
          children: [
            Text(
              '第 ${_index + 1} / ${widget.paper.questions.length} 题',
              style: theme.textTheme.labelSmall?.copyWith(
                letterSpacing: 0.8,
                fontWeight: FontWeight.w700,
              ),
            ),
            const Spacer(),
            Text(
              '${question.type.label} · ${question.score} 分',
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
        const SizedBox(height: 10),
        GlassPanel(
          heavy: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(question.stem, style: theme.textTheme.titleSmall),
              if (question.knowledge.isNotEmpty) ...[
                const SizedBox(height: 8),
                mutedText(context, question.knowledge),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (question.type.hasOptions)
          for (var i = 0; i < question.options.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 9),
              child: _optionTile(
                letter: optionLetter(i),
                text: question.options[i],
                selected: _answer.contains(optionLetter(i)),
                dark: dark,
                theme: theme,
              ),
            )
        else
          GlassPanel(
            heavy: true,
            child: GlassField(
              controller: _text,
              label: question.type == QuestionType.essay
                  ? '作答（交卷后标记为待批阅）'
                  : '填写答案',
              hint: '输入答案',
              maxLines: question.type == QuestionType.essay ? 5 : 1,
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
            child: GlassPanel(
              radius: 16,
              sigma: 18,
              padding: const EdgeInsets.all(14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    correct
                        ? Icons.check_circle_rounded
                        : Icons.cancel_rounded,
                    size: 20,
                    color: correct
                        ? const Color(0xFF30A46C)
                        : AppTheme.destructive,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          correct ? '回答正确' : '回答错误',
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: correct
                                ? const Color(0xFF30A46C)
                                : AppTheme.destructive,
                          ),
                        ),
                        if (!correct && question.answers.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          mutedText(
                            context,
                            '正确答案 ${question.answers.join(' / ')}',
                          ),
                        ],
                        if (question.analysis.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          mutedText(context, question.analysis, maxLines: 3),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 22),
        Row(
          children: [
            Expanded(
              child: GlassButton(
                label: '上一题',
                icon: Icons.chevron_left_rounded,
                primary: false,
                onPressed: () => _move(-1),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: GlassButton(
                label: '下一题',
                icon: Icons.chevron_right_rounded,
                primary: false,
                onPressed: () => _move(1),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: GlassButton(label: '交卷', onPressed: _submit),
            ),
          ],
        ),
      ],
    );
  }

  Widget _optionTile({
    required String letter,
    required String text,
    required bool selected,
    required bool dark,
    required ThemeData theme,
  }) {
    return GlassTappable(
      onTap: () => _select(letter),
      child: AnimatedContainer(
        duration: Duration(milliseconds: reduceMotion(context) ? 0 : 170),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          color: selected
              ? AppTheme.accent.withValues(alpha: dark ? 0.22 : 0.12)
              : Colors.white.withValues(alpha: dark ? 0.07 : 0.42),
          border: Border.all(
            color: selected
                ? AppTheme.accent
                : Colors.white.withValues(alpha: dark ? 0.16 : 0.8),
            width: selected ? 1.4 : 0.9,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected
                    ? AppTheme.accent
                    : Colors.transparent,
                border: Border.all(
                  color: selected
                      ? AppTheme.accent
                      : (dark
                          ? Colors.white.withValues(alpha: 0.35)
                          : Colors.black.withValues(alpha: 0.22)),
                  width: 1.5,
                ),
              ),
              child: Text(
                letter,
                style: TextStyle(
                  fontSize: 11,
                  height: 1.2,
                  fontWeight: FontWeight.w700,
                  color: selected
                      ? Colors.white
                      : (dark ? Colors.white70 : const Color(0xFF3A3A3C)),
                ),
              ),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Text(
                text,
                style: theme.textTheme.bodyMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _resultView() {
    final theme = Theme.of(context);
    final result = _result!;
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 4, 18, 32),
      children: [
        GlassPanel(
          heavy: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${result.score.toStringAsFixed(0)} / ${result.total.toStringAsFixed(0)}',
                style: theme.textTheme.displaySmall,
              ),
              const SizedBox(height: 6),
              mutedText(
                context,
                '答对 ${result.correctCount} · 答错 ${result.wrongCount} · '
                '待批阅 ${result.pendingCount}',
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        sectionHeader(context, '本次错题 · ${result.wrongStems.length}'),
        if (result.wrongStems.isEmpty)
          const GlassPanel(child: Text('全部答对，太棒了'))
        else
          for (final stem in result.wrongStems)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: GlassPanel(
                radius: 18,
                sigma: 18,
                padding: const EdgeInsets.all(14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const GlassIconBadge(
                      icon: Icons.error_outline,
                      color: AppTheme.destructive,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        stem,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        const SizedBox(height: 22),
        GlassButton(
          label: '返回试卷列表',
          icon: Icons.chevron_left_rounded,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }
}
