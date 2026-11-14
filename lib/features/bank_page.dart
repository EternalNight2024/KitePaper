import 'dart:convert';

import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:material_ui/material_ui.dart';

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
  String _message = '';

  Future<void> _import() async {
    try {
      final bytes = await pickQtiFile();
      if (bytes == null) return;
      final paper = importQti(utf8.decode(bytes));
      await store.addQuestions(paper.questions);
      if (!mounted) return;
      setState(() => _message = '已从《${paper.title}》导入 ${paper.questions.length} 道题');
    } catch (error) {
      if (!mounted) return;
      setState(() => _message = '导入失败：$error');
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
        return ListView(
          padding: pagePadding,
          children: [
            GlassGroupedSection(
              surfaceStyle: GlassSurfaceStyle.solid,
              children: [
                GlassListTile(
                  leading: const Icon(Icons.library_books),
                  title: const Text('本地题库'),
                  subtitle: Text('${questions.length} 道题 · 纯离线保存在本机'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                GlassButton.custom(
                  width: 148,
                  height: 48,
                  onTap: _import,
                  child: const Text('导入 QTI'),
                ),
                const SizedBox(width: 12),
                GlassButton.custom(
                  width: 148,
                  height: 48,
                  onTap: _openEditor,
                  child: const Text('新增题目'),
                ),
              ],
            ),
            if (_message.isNotEmpty) statusMessage(_message),
            const SizedBox(height: 16),
            GlassGroupedSection(
              surfaceStyle: GlassSurfaceStyle.solid,
              header: const Text('全部题目'),
              children: questions.isEmpty
                  ? const [GlassListTile(title: Text('题库为空，先导入或新增题目'))]
                  : [
                      for (final question in questions)
                        GlassListTile(
                          leading: const Icon(Icons.quiz_outlined),
                          title: Text(
                            question.stem,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            '${question.type.label} · ${question.score} 分 · '
                            '${question.knowledge.isEmpty ? '未分类' : question.knowledge}',
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline),
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
