import 'dart:convert';
import 'dart:typed_data';

import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:material_ui/material_ui.dart';

import '../core/file_transfer.dart';
import '../core/models.dart';
import '../core/qti.dart';
import '../core/store.dart';
import '../core/ui.dart';
import 'exam_page.dart';

class PapersPage extends StatefulWidget {
  const PapersPage({super.key});

  @override
  State<PapersPage> createState() => _PapersPageState();
}

class _PapersPageState extends State<PapersPage> {
  String _message = '';

  Future<void> _import() async {
    try {
      final bytes = await pickQtiFile();
      if (bytes == null) return;
      final source = importQti(utf8.decode(bytes));
      final paper = Paper(
        id: newId(),
        title: source.title,
        description: source.description,
        questions: source.questions,
        durationMinutes: source.durationMinutes,
        createdAt: DateTime.now(),
      );
      await store.addPaper(paper);
      if (!mounted) return;
      setState(() => _message = '已导入《${paper.title}》，共 ${paper.questions.length} 题');
    } catch (error) {
      if (!mounted) return;
      setState(() => _message = '导入失败：$error');
    }
  }

  Future<void> _download(Paper paper) async {
    try {
      final xml = exportQti(paper);
      final fileName =
          '${paper.title.replaceAll(RegExp(r'[\\/:*?"<>|\s]+'), '_')}.qti';
      final path = await saveQtiFile(
        fileName,
        Uint8List.fromList(utf8.encode(xml)),
      );
      if (!mounted) return;
      setState(() => _message = '已下载 QTI 文件：$path');
    } catch (error) {
      if (!mounted) return;
      setState(() => _message = '下载失败：$error');
    }
  }

  void _start(Paper paper) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => ExamPage(paper: paper)),
    );
  }

  void _confirmDelete(Paper paper) {
    GlassDialog.show(
      context: context,
      title: '删除试卷',
      message: '《${paper.title}》将从本机移除',
      actions: [
        GlassDialogAction(
          label: '取消',
          onPressed: () => Navigator.of(context).pop(),
        ),
        GlassDialogAction(
          label: '删除',
          isDestructive: true,
          onPressed: () {
            Navigator.of(context).pop();
            store.removePaper(paper.id);
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final papers = store.papers;
        return ListView(
          padding: pagePadding,
          children: [
            GlassButton.custom(
              width: 220,
              height: 48,
              onTap: _import,
              child: const Text('导入试卷 QTI'),
            ),
            if (_message.isNotEmpty) statusMessage(_message),
            statusMessage('试卷保存在本机；导出的 .qti 文件可直接分享给他人'),
            if (papers.isEmpty)
              const GlassGroupedSection(
                surfaceStyle: GlassSurfaceStyle.solid,
                children: [
                  GlassListTile(title: Text('暂无试卷，去「组卷」生成一张')),
                ],
              ),
            for (final paper in papers)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: GlassGroupedSection(
                  surfaceStyle: GlassSurfaceStyle.solid,
                  header: Text(
                    '${paper.title} · ${paper.questions.length} 题 · ${paper.totalScore} 分',
                  ),
                  children: [
                    GlassListTile(
                      leading: const Icon(Icons.play_arrow),
                      title: const Text('在线刷题'),
                      subtitle: Text('${paper.durationMinutes} 分钟 · 离线即时判分'),
                      onTap: () => _start(paper),
                    ),
                    GlassListTile(
                      leading: const Icon(Icons.download),
                      title: const Text('下载 QTI 试卷'),
                      subtitle: const Text('导出后可发送给他人导入'),
                      onTap: () => _download(paper),
                    ),
                    GlassListTile(
                      leading: const Icon(Icons.delete_outline),
                      title: const Text('删除'),
                      onTap: () => _confirmDelete(paper),
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}
