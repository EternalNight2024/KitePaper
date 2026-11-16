import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../core/file_transfer.dart';
import '../core/layout.dart';
import '../core/models.dart';
import '../core/qti.dart';
import '../core/store.dart';
import '../theme/app_theme.dart';
import 'exam_page.dart';
import 'shared_widgets.dart';

class PapersPage extends StatefulWidget {
  const PapersPage({
    super.key,
    this.mode = AppMode.teacher,
    this.controller,
  });

  final AppMode mode;
  final GlassLargeTitleController? controller;

  @override
  State<PapersPage> createState() => _PapersPageState();
}

class _PapersPageState extends State<PapersPage> {
  Future<void> _import() async {
    try {
      final bytes = await pickQtiFile();
      if (bytes == null || !mounted) return;
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
      GlassToast.show(context,
          message: '已导入《${paper.title}》，共 ${paper.questions.length} 题');
    } catch (error) {
      if (!mounted) return;
      GlassToast.show(context,
          message: '导入失败：$error', type: GlassToastType.error);
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
      GlassToast.show(context, message: '已保存 QTI 文件：$path');
    } catch (error) {
      if (!mounted) return;
      GlassToast.show(context,
          message: '下载失败：$error', type: GlassToastType.error);
    }
  }

  void _start(Paper paper) {
    Navigator.of(context).push(
      GlassPageRoute<void>(builder: (_) => ExamPage(paper: paper)),
    );
  }

  Future<void> _confirmDelete(Paper paper) async {
    final confirmed = await GlassDialog.show<bool>(
      context: context,
      title: '删除试卷',
      message: '《${paper.title}》将从本机移除，此操作不可撤销。',
      actions: [
        GlassDialogAction(
            label: '取消', onPressed: () => Navigator.of(context).pop(false)),
        GlassDialogAction(
          label: '删除',
          isDestructive: true,
          onPressed: () => Navigator.of(context).pop(true),
        ),
      ],
    );
    if (confirmed == true) await store.removePaper(paper.id);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final papers = store.papers;
        final student = widget.mode == AppMode.student;
        final theme = Theme.of(context);
        return GlassPageBody(
          controller: widget.controller,
          title: student ? '练习' : '试卷',
          children: [
            Wrap(
              spacing: 10,
              runSpacing: 10,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                ActionGlassButton(
                  label: student ? '导入他人试卷 QTI' : '导入试卷 QTI',
                  icon: CupertinoIcons.arrow_down_doc,
                  prominent: true,
                  accent: AppTheme.modeColor(widget.mode),
                  onTap: _import,
                ),
                Text(
                  student ? '导入后即可逐题练习，客观题即时判分' : '组卷后可导出 .qti 分享给他人',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: 22),
            sectionHeader(context, '我的试卷 · ${papers.length}'),
            if (papers.isEmpty)
              GlassContainer.card(
                surfaceStyle: GlassSurfaceStyle.solid,
                child: const Text('暂无试卷，去「组卷」生成一张'),
              )
            else
              for (final paper in papers)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: GlassContainer.card(
                    surfaceStyle: GlassSurfaceStyle.solid,
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(11),
                                color: theme.colorScheme.primary
                                    .withValues(alpha: 0.12),
                              ),
                              child: Icon(CupertinoIcons.doc_text,
                                  size: 18, color: theme.colorScheme.primary),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(paper.title,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: theme.textTheme.titleSmall),
                                  const SizedBox(height: 4),
                                  Text(
                                      '${paper.questions.length} 题 · '
                                      '${formatScore(paper.totalScore)} 分 · '
                                      '${paper.durationMinutes} 分钟',
                                      style: theme.textTheme.bodySmall),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            ActionGlassButton(
                              label: student ? '开始刷题' : '预览练习',
                              icon: CupertinoIcons.play_fill,
                              compact: true,
                              prominent: true,
                              accent: AppTheme.modeColor(widget.mode),
                              onTap: () => _start(paper),
                            ),
                            ActionGlassButton(
                              label: student ? '下载试卷文件' : '导出 QTI',
                              icon: CupertinoIcons.square_arrow_up,
                              compact: true,
                              onTap: () => _download(paper),
                            ),
                            if (!student)
                              ActionGlassButton(
                                label: '删除',
                                icon: CupertinoIcons.trash,
                                compact: true,
                                destructive: true,
                                onTap: () => _confirmDelete(paper),
                              ),
                          ],
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
