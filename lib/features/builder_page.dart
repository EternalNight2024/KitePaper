import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../core/layout.dart';
import '../core/models.dart';
import '../core/store.dart';
import '../theme/app_theme.dart';
import 'shared_widgets.dart';

class BuilderPage extends StatefulWidget {
  const BuilderPage({super.key, required this.onCreated, this.controller});

  final VoidCallback onCreated;
  final GlassLargeTitleController? controller;

  @override
  State<BuilderPage> createState() => _BuilderPageState();
}

class _BuilderPageState extends State<BuilderPage> {
  final _title = TextEditingController(text: '新建试卷');
  final Set<String> _selected = <String>{};

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  void _toggle(String id) => setState(() {
        if (!_selected.remove(id)) {
          _selected.add(id);
        }
      });

  Future<void> _create() async {
    final picked = store.questions.where((q) => _selected.contains(q.id)).toList();
    if (picked.isEmpty) {
      if (!mounted) return;
      GlassToast.show(context,
          message: '请至少选择一道题', type: GlassToastType.warning);
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
    setState(() => _selected.clear());
    GlassToast.show(context,
        message: '已生成《$title》，可在「试卷」下载或练习');
    widget.onCreated();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final questions = store.questions;
        final total = questions
            .where((q) => _selected.contains(q.id))
            .fold<double>(0, (sum, q) => sum + q.score);

        return GlassPageBody(
          controller: widget.controller,
          title: '组卷',
          children: [
            GlassContainer.card(
              surfaceStyle: GlassSurfaceStyle.solid,
              padding: const EdgeInsets.all(14),
              child: GlassTextField(
                controller: _title,
                placeholder: '试卷标题，例如：Flutter 基础测验',
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              ),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                ActionGlassButton(
                  label: '生成试卷 · ${_selected.length} 题',
                  icon: CupertinoIcons.sparkles,
                  prominent: true,
                  accent: AppTheme.teacher,
                  onTap: _create,
                ),
                Text('已选总分 ${total.toStringAsFixed(0)} 分',
                    style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
            const SizedBox(height: 22),
            sectionHeader(context, '从题库选题 · ${questions.length}'),
            GlassGroupedSection(
              surfaceStyle: GlassSurfaceStyle.solid,
              margin: EdgeInsets.zero,
              children: [
                if (questions.isEmpty)
                  const GlassListTile(title: Text('题库为空，请先添加题目'))
                else
                  for (final question in questions)
                    GlassListTile(
                      leading: _SelectDot(
                        selected: _selected.contains(question.id),
                        type: question.type,
                      ),
                      title: Text(
                        question.stem,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      subtitle: Text(
                        '${question.type.label} · ${formatScore(question.score)} 分 · '
                        '${question.knowledge.isEmpty ? '未分类' : question.knowledge}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
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

/// 组卷选题：勾选状态 + 题型色。
class _SelectDot extends StatelessWidget {
  const _SelectDot({required this.selected, required this.type});

  final bool selected;
  final QuestionType type;

  @override
  Widget build(BuildContext context) {
    final color = AppTheme.typeColor(type);
    return Container(
      width: 24,
      height: 24,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: selected ? color : color.withValues(alpha: 0.12),
        border: Border.all(color: color.withValues(alpha: 0.55), width: 1.4),
      ),
      child: selected
          ? const Icon(CupertinoIcons.check_mark, size: 13, color: Colors.white)
          : null,
    );
  }
}
