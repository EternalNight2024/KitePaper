import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

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
  String? _message;
  bool _failed = false;

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
      setState(() {
        _failed = false;
        _message = '已导入《${paper.title}》，共 ${paper.questions.length} 题';
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _failed = true;
        _message = '导入失败：$error';
      });
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
      setState(() {
        _failed = false;
        _message = '已下载 QTI 文件：$path';
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _failed = true;
        _message = '下载失败：$error';
      });
    }
  }

  void _start(Paper paper) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => ExamPage(paper: paper)),
    );
  }

  Future<void> _confirmDelete(Paper paper) async {
    final theme = Theme.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.22),
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding: const EdgeInsets.symmetric(horizontal: 36),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 330),
          child: GlassPanel(
            heavy: true,
            hoverable: false,
            radius: 26,
            padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('删除试卷', style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                Text(
                  '《${paper.title}》将从本机移除，此操作不可撤销。',
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: GlassButton(
                        label: '取消',
                        primary: false,
                        compact: true,
                        onPressed: () => Navigator.of(ctx).pop(false),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: GlassButton(
                        label: '删除',
                        destructive: true,
                        compact: true,
                        onPressed: () => Navigator.of(ctx).pop(true),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (confirmed == true) {
      await store.removePaper(paper.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final theme = Theme.of(context);
        final papers = store.papers;
        return ListView(
          padding: pagePadding,
          children: [
            Wrap(
              spacing: 10,
              runSpacing: 10,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                GlassButton(
                  label: '导入试卷 QTI',
                  icon: Icons.file_download_outlined,
                  onPressed: _import,
                ),
                mutedText(context, '导出的 .qti 可直接分享给他人'),
              ],
            ),
            if (_message != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: GlassBanner(message: _message!, isError: _failed),
              ),
            const SizedBox(height: 20),
            sectionHeader(context, '我的试卷 · ${papers.length}'),
            if (papers.isEmpty)
              const GlassPanel(child: Text('暂无试卷，去「组卷」生成一张'))
            else
              for (final paper in papers)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: GlassPanel(
                    heavy: true,
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const GlassIconBadge(
                              icon: Icons.article_outlined,
                              color: Color(0xFF5E5CE6),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    paper.title,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.textTheme.titleMedium,
                                  ),
                                  const SizedBox(height: 4),
                                  mutedText(
                                    context,
                                    '${paper.questions.length} 题 · '
                                    '${paper.totalScore.toStringAsFixed(0)} 分 · '
                                    '${paper.durationMinutes} 分钟',
                                  ),
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
                            GlassButton(
                              label: '在线刷题',
                              icon: Icons.play_arrow_rounded,
                              compact: true,
                              onPressed: () => _start(paper),
                            ),
                            GlassButton(
                              label: '下载 QTI',
                              icon: Icons.ios_share_rounded,
                              primary: false,
                              compact: true,
                              onPressed: () => _download(paper),
                            ),
                            GlassButton(
                              label: '删除',
                              icon: Icons.delete_outline,
                              destructive: true,
                              compact: true,
                              onPressed: () => _confirmDelete(paper),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          '试卷保存在本机 · 导出后可分享给他人',
                          style: theme.textTheme.labelSmall,
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
