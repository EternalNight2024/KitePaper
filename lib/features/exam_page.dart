import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:material_ui/material_ui.dart';

import '../core/models.dart';
import '../core/store.dart';
import '../core/ui.dart';

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
        if (current.contains(letter)) {
          current.remove(letter);
        } else {
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
    return GlassScaffold(
      background: glassBackground(Theme.of(context).brightness),
      appBar: GlassAppBar(
        title: Text(
          widget.paper.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: _result == null
            ? [
                GlassIconButton(
                  icon: const Icon(Icons.check),
                  onPressed: _submit,
                ),
              ]
            : null,
      ),
      body: _result == null ? _questionView() : _resultView(),
    );
  }

  Widget _questionView() {
    final question = _current;
    final answered = _answer.isNotEmpty;
    final correct = question.type.isObjective && answered
        ? question.isCorrect(_answer)
        : null;

    return ListView(
      padding: pagePadding,
      children: [
        Text(
          '第 ${_index + 1} / ${widget.paper.questions.length} 题 · '
          '${question.type.label} · ${question.score} 分',
        ),
        const SizedBox(height: 12),
        GlassGroupedSection(
          surfaceStyle: GlassSurfaceStyle.solid,
          children: [
            GlassListTile(
              title: Text(question.stem),
              subtitle: Text(
                  question.knowledge.isEmpty ? '未分类' : question.knowledge),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (question.type.hasOptions)
          GlassGroupedSection(
            surfaceStyle: GlassSurfaceStyle.solid,
            header: const Text('请选择'),
            children: [
              for (var i = 0; i < question.options.length; i++)
                GlassListTile(
                  leading: Icon(
                    _answer.contains(optionLetter(i))
                        ? Icons.check_circle
                        : Icons.radio_button_unchecked,
                  ),
                  title: Text('${optionLetter(i)}. ${question.options[i]}'),
                  onTap: () => _select(optionLetter(i)),
                ),
            ],
          )
        else
          GlassGroupedSection(
            surfaceStyle: GlassSurfaceStyle.solid,
            header: Text(
              question.type == QuestionType.essay
                  ? '作答（交卷后标记为待批阅）'
                  : '填写答案',
            ),
            children: [
              GlassListTile(
                title: GlassTextField(
                  controller: _text,
                  placeholder: '输入答案',
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
            ],
          ),
        if (correct != null) ...[
          const SizedBox(height: 12),
          statusMessage(
            correct
                ? '回答正确 · ${question.analysis}'
                : '回答错误 · 正确答案 ${question.answers.join(' / ')} · ${question.analysis}',
          ),
        ],
        const SizedBox(height: 20),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            GlassButton.custom(
              width: 104,
              height: 46,
              onTap: () => _move(-1),
              child: const Text('上一题'),
            ),
            GlassButton.custom(
              width: 104,
              height: 46,
              onTap: () => _move(1),
              child: const Text('下一题'),
            ),
            GlassButton.custom(
              width: 104,
              height: 46,
              onTap: _submit,
              child: const Text('交卷'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _resultView() {
    final result = _result!;
    return ListView(
      padding: pagePadding,
      children: [
        GlassGroupedSection(
          surfaceStyle: GlassSurfaceStyle.solid,
          children: [
            GlassListTile(
              leading: const Icon(Icons.emoji_events),
              title: Text('${result.score} / ${result.total} 分'),
              subtitle: Text(
                '答对 ${result.correctCount} · 答错 ${result.wrongCount} · '
                '待批阅 ${result.pendingCount}',
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        GlassGroupedSection(
          surfaceStyle: GlassSurfaceStyle.solid,
          header: const Text('本次错题'),
          children: result.wrongStems.isEmpty
              ? const [GlassListTile(title: Text('全部答对，太棒了'))]
              : [
                  for (final stem in result.wrongStems)
                    GlassListTile(
                      leading: const Icon(Icons.error_outline),
                      title: Text(
                        stem,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
        ),
        const SizedBox(height: 20),
        GlassButton.custom(
          height: 48,
          onTap: () => Navigator.of(context).pop(),
          child: const Text('返回试卷列表'),
        ),
      ],
    );
  }
}
