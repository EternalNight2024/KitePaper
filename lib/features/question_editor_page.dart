import 'package:flutter/material.dart';

import '../core/models.dart';
import '../core/store.dart';
import '../core/ui.dart';

class QuestionEditorPage extends StatefulWidget {
  const QuestionEditorPage({super.key});

  @override
  State<QuestionEditorPage> createState() => _QuestionEditorPageState();
}

class _QuestionEditorPageState extends State<QuestionEditorPage> {
  final _stem = TextEditingController();
  final _options = TextEditingController();
  final _answers = TextEditingController(text: 'A');
  final _score = TextEditingController(text: '2');
  final _knowledge = TextEditingController();
  final _analysis = TextEditingController();
  QuestionType _type = QuestionType.single;
  String? _message;

  @override
  void dispose() {
    _stem.dispose();
    _options.dispose();
    _answers.dispose();
    _score.dispose();
    _knowledge.dispose();
    _analysis.dispose();
    super.dispose();
  }

  List<String> _split(String value) => value
      .split('|')
      .map((item) => item.trim())
      .where((item) => item.isNotEmpty)
      .toList();

  Future<void> _save() async {
    final stem = _stem.text.trim();
    final options = _type.hasOptions ? _split(_options.text) : <String>[];
    final answers = _split(_answers.text);

    if (stem.isEmpty) {
      setState(() => _message = '题干不能为空');
      return;
    }
    if (_type.hasOptions && options.length < 2) {
      setState(() => _message = '选择题至少需要 2 个选项，用 | 分隔');
      return;
    }
    if (answers.isEmpty) {
      setState(() => _message = '请填写答案');
      return;
    }

    await store.addQuestion(Question(
      id: newId(),
      stem: stem,
      type: _type,
      options: options,
      answers: answers,
      score: double.tryParse(_score.text.trim()) ?? 2,
      knowledge: _knowledge.text.trim(),
      analysis: _analysis.text.trim(),
    ));
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GlassPageScaffold(
      title: '新增题目',
      action: GlassButton(
        label: '保存',
        compact: true,
        onPressed: _save,
      ),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 4, 18, 32),
        children: [
          sectionHeader(context, '题型'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final type in QuestionType.values)
                GlassChip(
                  label: type.label,
                  selected: _type == type,
                  onTap: () => setState(() => _type = type),
                ),
            ],
          ),
          const SizedBox(height: 20),
          sectionHeader(context, '题目内容'),
          GlassPanel(
            heavy: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GlassField(
                  controller: _stem,
                  label: '题干',
                  hint: '输入题目描述',
                  maxLines: 3,
                ),
                if (_type.hasOptions) ...[
                  const SizedBox(height: 14),
                  GlassField(
                    controller: _options,
                    label: '选项（用 | 分隔）',
                    hint: '例如：Widget|Activity|ViewController',
                  ),
                ],
                const SizedBox(height: 14),
                GlassField(
                  controller: _answers,
                  label: '答案（选择题填 A 或 A|C）',
                  hint: 'A',
                ),
                const SizedBox(height: 14),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: GlassField(
                        controller: _score,
                        label: '分值',
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GlassField(
                        controller: _knowledge,
                        label: '知识点',
                        hint: '选填',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                GlassField(
                  controller: _analysis,
                  label: '解析',
                  hint: '选填',
                  maxLines: 2,
                ),
              ],
            ),
          ),
          if (_message != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: GlassBanner(message: _message!, isError: true),
            ),
          const SizedBox(height: 24),
          GlassButton(
            label: '保存到本地题库',
            icon: Icons.check_rounded,
            onPressed: _save,
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              '数据仅保存于本机',
              style: theme.textTheme.labelSmall,
            ),
          ),
        ],
      ),
    );
  }
}
