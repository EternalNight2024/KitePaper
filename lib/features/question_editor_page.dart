import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:material_ui/material_ui.dart';

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
  String _message = '';

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
    return GlassScaffold(
      background: glassBackground(Theme.of(context).brightness),
      appBar: GlassAppBar(
        title: const Text('新增题目'),
        actions: [
          GlassIconButton(icon: const Icon(Icons.save), onPressed: _save),
        ],
      ),
      body: ListView(
        padding: pagePadding,
        children: [
          GlassGroupedSection(
            surfaceStyle: GlassSurfaceStyle.solid,
            header: const Text('题型'),
            children: [
              GlassListTile(
                title: DropdownButton<QuestionType>(
                  value: _type,
                  isExpanded: true,
                  items: QuestionType.values
                      .map((type) => DropdownMenuItem(
                            value: type,
                            child: Text(type.label),
                          ))
                      .toList(),
                  onChanged: (value) =>
                      setState(() => _type = value ?? QuestionType.single),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          GlassGroupedSection(
            surfaceStyle: GlassSurfaceStyle.solid,
            header: const Text('题目内容'),
            children: [
              GlassListTile(
                title: GlassTextField(
                  controller: _stem,
                  placeholder: '题干',
                  maxLines: 3,
                ),
              ),
              if (_type.hasOptions)
                GlassListTile(
                  title: GlassTextField(
                    controller: _options,
                    placeholder: '选项，用 | 分隔',
                  ),
                ),
              GlassListTile(
                title: GlassTextField(
                  controller: _answers,
                  placeholder: '答案，选择题填 A 或 A|C',
                ),
              ),
              GlassListTile(
                title: GlassTextField(
                  controller: _score,
                  placeholder: '分值',
                  keyboardType: TextInputType.number,
                ),
              ),
              GlassListTile(
                title: GlassTextField(
                  controller: _knowledge,
                  placeholder: '知识点',
                ),
              ),
              GlassListTile(
                title: GlassTextField(
                  controller: _analysis,
                  placeholder: '解析',
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          GlassButton.custom(
            height: 50,
            onTap: _save,
            child: const Text('保存到本地题库'),
          ),
          if (_message.isNotEmpty) statusMessage(_message),
        ],
      ),
    );
  }
}
