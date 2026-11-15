import 'dart:convert';

import 'package:flutter/material.dart';

import '../core/file_transfer.dart';
import '../core/models.dart';
import '../core/qti.dart';
import '../core/store.dart';
import '../core/ui.dart';
import 'question_editor_page.dart';

class BankPage extends StatefulWidget {
  const BankPage({super.key});

  @override
  State<BankPage> createState() => _BankPageState();
}

class _BankPageState extends State<BankPage> {
  String? _message;
  bool _failed = false;

  Future<void> _import() async {
    try {
      final bytes = await pickQtiFile();
      if (bytes == null) return;
      final paper = importQti(utf8.decode(bytes));
      await store.addQuestions(paper.questions);
      if (!mounted) return;
      setState(() {
        _failed = false;
        _message = '已从《${paper.title}》导入 ${paper.questions.length} 道题';
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _failed = true;
        _message = '导入失败：$error';
      });
    }
  }

  Future<void> _openEditor() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const QuestionEditorPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final questions = store.questions;
        final theme = Theme.of(context);
        return ListView(
          padding: pagePadding,
          children: [
            GlassPanel(
              heavy: true,
              child: Row(
                children: [
                  const GlassIconBadge(icon: Icons.library_books_outlined),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('本地题库', style: theme.textTheme.titleMedium),
                        const SizedBox(height: 3),
                        mutedText(
                          context,
                          '${questions.length} 道题 · 纯离线保存在本机',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                GlassButton(
                  label: '导入 QTI',
                  icon: Icons.file_download_outlined,
                  onPressed: _import,
                ),
                GlassButton(
                  label: '新增题目',
                  icon: Icons.add_rounded,
                  primary: false,
                  onPressed: _openEditor,
                ),
              ],
            ),
            if (_message != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: GlassBanner(message: _message!, isError: _failed),
              ),
            const SizedBox(height: 20),
            sectionHeader(context, '全部题目 · ${questions.length}'),
            if (questions.isEmpty)
              const GlassPanel(child: Text('题库为空，先导入或新增题目'))
            else
              for (final question in questions)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: GlassPanel(
                    radius: 18,
                    sigma: 18,
                    padding: const EdgeInsets.fromLTRB(14, 14, 10, 14),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const GlassIconBadge(
                          icon: Icons.quiz_outlined,
                          color: Color(0xFF5E5CE6),
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
                        const SizedBox(width: 6),
                        GlassIconButton(
                          icon: Icons.delete_outline,
                          label: '删除题目',
                          onPressed: () => store.removeQuestion(question.id),
                        ),
                      ],
                    ),
                  ),
                ),
          ],
        );
      },
    );
  }
}
