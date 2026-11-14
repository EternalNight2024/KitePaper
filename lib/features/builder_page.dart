import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:material_ui/material_ui.dart';

import '../core/models.dart';
import '../core/store.dart';
import '../core/ui.dart';

class BuilderPage extends StatefulWidget {
  const BuilderPage({super.key, required this.onCreated});

  final VoidCallback onCreated;

  @override
  State<BuilderPage> createState() => _BuilderPageState();
}

class _BuilderPageState extends State<BuilderPage> {
  final _title = TextEditingController(text: '新建试卷');
  final Set<String> _selected = <String>{};
  String _message = '';

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  void _toggle(String id) {
    setState(() {
      if (_selected.contains(id)) {
        _selected.remove(id);
      } else {
        _selected.add(id);
      }
    });
  }

  Future<void> _create() async {
    final picked = store.questions
        .where((question) => _selected.contains(question.id))
        .toList();
    if (picked.isEmpty) {
      setState(() => _message = '请至少选择一道题');
      return;
    }

    final title = _title.text.trim().isEmpty ? '未命名试卷' : _title.text.trim();
    final paper = Paper(
      id: newId(),
      title: title,
      description: '由本地题库手动组卷生成',
      questions: picked,
      durationMinutes: 30,
      createdAt: DateTime.now(),
    );
    await store.addPaper(paper);
    if (!mounted) return;
    setState(() {
      _selected.clear();
      _message = '已生成《$title》，可在「试卷」下载或练习';
    });
    widget.onCreated();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final selected = store.questions
            .where((question) => _selected.contains(question.id))
            .toList();
        final total =
            selected.fold(0.0, (sum, question) => sum + question.score);

        return ListView(
          padding: pagePadding,
          children: [
            GlassGroupedSection(
              surfaceStyle: GlassSurfaceStyle.solid,
              children: [
                GlassListTile(
                  title: GlassTextField(
                    controller: _title,
                    placeholder: '试卷标题',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            GlassButton.custom(
              width: 220,
              height: 48,
              onTap: _create,
              child: Text('生成试卷 · ${selected.length} 题'),
            ),
            if (_message.isNotEmpty) statusMessage(_message),
            statusMessage('已选总分：$total 分 · 全部数据仅存本机'),
            GlassGroupedSection(
              surfaceStyle: GlassSurfaceStyle.solid,
              header: const Text('从题库选题'),
              children: store.questions.isEmpty
                  ? const [GlassListTile(title: Text('题库为空，请先添加题目'))]
                  : [
                      for (final question in store.questions)
                        GlassListTile(
                          leading: Checkbox(
                            value: _selected.contains(question.id),
                            onChanged: (_) => _toggle(question.id),
                          ),
                          title: Text(
                            question.stem,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                              '${question.type.label} · ${question.score} 分 · ${question.knowledge}'),
                          onTap: () => _toggle(question.id),
                        ),
                    ],
            ),
          ],
        );
      },
    );
  }
}
