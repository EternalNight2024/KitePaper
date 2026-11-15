import 'package:flutter/material.dart';

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
  String? _message;
  bool _failed = false;

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  void _toggle(String id) {
    setState(() {
      if (!_selected.remove(id)) {
        _selected.add(id);
      }
    });
  }

  Future<void> _create() async {
    final picked =
        store.questions.where((q) => _selected.contains(q.id)).toList();
    if (picked.isEmpty) {
      setState(() {
        _failed = true;
        _message = '请至少选择一道题';
      });
      return;
    }

    final title = _title.text.trim().isEmpty ? '未命名试卷' : _title.text.trim();
    await store.addPaper(Paper(
      id: newId(),
      title: title,
      description: '由本地题库手动组卷生成',
      questions: picked,
      durationMinutes: 30,
      createdAt: DateTime.now(),
    ));
    if (!mounted) return;
    setState(() {
      _selected.clear();
      _failed = false;
      _message = '已生成《$title》，可在「试卷」下载或练习';
    });
    widget.onCreated();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final theme = Theme.of(context);
        final questions = store.questions;
        final total = questions
            .where((q) => _selected.contains(q.id))
            .fold<double>(0, (sum, q) => sum + q.score);

        return ListView(
          padding: pagePadding,
          children: [
            GlassPanel(
              heavy: true,
              child: GlassField(
                controller: _title,
                label: '试卷标题',
                hint: '例如：Flutter 基础测验',
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                GlassButton(
                  label: '生成试卷 · ${_selected.length} 题',
                  icon: Icons.auto_awesome_rounded,
                  onPressed: _create,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: mutedText(context, '已选总分 ${total.toStringAsFixed(0)} 分'),
                ),
              ],
            ),
            if (_message != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: GlassBanner(message: _message!, isError: _failed),
              ),
            const SizedBox(height: 20),
            sectionHeader(context, '从题库选题 · ${questions.length}'),
            if (questions.isEmpty)
              const GlassPanel(child: Text('题库为空，请先添加题目'))
            else
              for (final question in questions)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: GlassTappable(
                    onTap: () => _toggle(question.id),
                    child: GlassPanel(
                      radius: 18,
                      sigma: 18,
                      padding: const EdgeInsets.fromLTRB(14, 14, 16, 14),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 1),
                            child: GlassCheck(
                              value: _selected.contains(question.id),
                              onChanged: (_) => _toggle(question.id),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  question.stem,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.bodyMedium,
                                ),
                                const SizedBox(height: 4),
                                mutedText(
                                  context,
                                  '${question.type.label} · ${question.score} 分 · '
                                  '${question.knowledge.isEmpty ? '未分类' : question.knowledge}',
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
          ],
        );
      },
    );
  }
}
