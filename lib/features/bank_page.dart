import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../core/file_transfer.dart';
import '../core/layout.dart';
import '../core/models.dart';
import '../core/qti.dart';
import '../core/store.dart';
import '../theme/app_theme.dart';
import 'question_editor_page.dart';
import 'shared_widgets.dart';

class BankPage extends StatefulWidget {
  const BankPage({super.key, this.controller});

  final GlassLargeTitleController? controller;

  @override
  State<BankPage> createState() => _BankPageState();
}

class _BankPageState extends State<BankPage> {
  Future<void> _import() async {
    try {
      final bytes = await pickQtiFile();
      if (bytes == null || !mounted) return;
      final paper = importQti(utf8.decode(bytes));
      await store.addQuestions(paper.questions);
      if (!mounted) return;
      GlassToast.show(context,
          message: '已从《${paper.title}》导入 ${paper.questions.length} 道题',
          type: GlassToastType.success);
    } catch (error) {
      if (!mounted) return;
      GlassToast.show(context,
          message: '导入失败：$error', type: GlassToastType.error);
    }
  }

  Future<void> _openEditor() async {
    await Navigator.of(context).push(
      GlassPageRoute<void>(builder: (_) => const QuestionEditorPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final questions = store.questions;
        final theme = Theme.of(context);
        return GlassPageBody(
          controller: widget.controller,
          title: '题库',
          children: [
            InfoCard(
              icon: CupertinoIcons.book,
              title: '本地题库',
              detail: '${questions.length} 道题 · 含内置教程 · 纯离线保存在本机',
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                ActionGlassButton(
                  label: '导入 QTI',
                  icon: CupertinoIcons.arrow_down_doc,
                  prominent: true,
                  accent: AppTheme.teacher,
                  onTap: _import,
                ),
                ActionGlassButton(
                  label: '新增题目',
                  icon: CupertinoIcons.add,
                  onTap: _openEditor,
                ),
              ],
            ),
            const SizedBox(height: 22),
            sectionHeader(context, '全部题目 · ${questions.length}'),
            GlassGroupedSection(
              surfaceStyle: GlassSurfaceStyle.solid,
              margin: EdgeInsets.zero,
              children: [
                if (questions.isEmpty)
                  const GlassListTile(title: Text('题库为空，先导入或新增题目'))
                else
                  for (final question in questions)
                    GlassListTile(
                      leading: _TypeDot(type: question.type),
                      title: Text(
                        question.stem,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium,
                      ),
                      subtitle: Text(
                        '${question.type.label} · ${formatScore(question.score)} 分 · '
                        '${question.knowledge.isEmpty ? '未分类' : question.knowledge}',
                        style: theme.textTheme.bodySmall,
                      ),
                      trailing: GlassIconButton(
                        icon: const Icon(CupertinoIcons.trash),
                        size: 32,
                        semanticLabel: '删除题目',
                        glowColor: AppTheme.destructive,
                        onPressed: () => store.removeQuestion(question.id),
                      ),
                    ),
              ],
            ),
          ],
        );
      },
    );
  }
}

/// 题型色点：在灰白列表里用低饱和色区分五种题型。
class _TypeDot extends StatelessWidget {
  const _TypeDot({required this.type});

  final QuestionType type;

  @override
  Widget build(BuildContext context) {
    final color = AppTheme.typeColor(type);
    return Container(
      width: 26,
      height: 26,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Icon(
        type.hasOptions ? CupertinoIcons.list_bullet : CupertinoIcons.textformat,
        size: 14,
        color: color,
      ),
    );
  }
}
