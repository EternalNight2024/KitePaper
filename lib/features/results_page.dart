import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../core/layout.dart';
import '../core/store.dart';
import '../theme/app_theme.dart';
import 'shared_widgets.dart';

class ResultsPage extends StatelessWidget {
  const ResultsPage({super.key, this.controller});

  final GlassLargeTitleController? controller;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final results = store.results;
        final wrongStems = <String>{
          for (final result in results) ...result.wrongStems,
        };
        final theme = Theme.of(context);
        return GlassPageBody(
          controller: controller,
          title: '成绩',
          children: [
            sectionHeader(context, '练习记录 · ${results.length}'),
            if (results.isEmpty)
              GlassContainer.card(
                surfaceStyle: GlassSurfaceStyle.solid,
                child: const Text('还没有成绩，去「练习」开始刷题'),
              )
            else
              GlassGroupedSection(
                surfaceStyle: GlassSurfaceStyle.solid,
                margin: EdgeInsets.zero,
                children: [
                  for (final result in results)
                    GlassListTile(
                      leading: Icon(
                        CupertinoIcons.chart_bar_alt_fill,
                        color: result.total > 0 &&
                                result.score / result.total >= 0.6
                            ? AppTheme.success
                            : AppTheme.warning,
                      ),
                      title: Row(
                        children: [
                          Expanded(
                            child: Text(
                              result.paperTitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodyMedium,
                            ),
                          ),
                          Text(
                            '${result.score.toStringAsFixed(0)} / '
                            '${result.total.toStringAsFixed(0)}',
                            style: theme.textTheme.titleSmall,
                          ),
                        ],
                      ),
                      subtitle: Text(
                        '对 ${result.correctCount} · 错 ${result.wrongCount} · '
                        '待批阅 ${result.pendingCount} · '
                        '${result.finishedAt.toString().substring(0, 16)}',
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                ],
              ),
            if (results.isNotEmpty) ...[
              const SizedBox(height: 12),
              ActionGlassButton(
                label: '清空记录',
                icon: CupertinoIcons.trash,
                compact: true,
                destructive: true,
                onTap: store.clearResults,
              ),
            ],
            const SizedBox(height: 24),
            sectionHeader(context, '错题本 · ${wrongStems.length}'),
            if (wrongStems.isEmpty)
              GlassContainer.card(
                surfaceStyle: GlassSurfaceStyle.solid,
                child: const Text('暂无错题'),
              )
            else
              GlassGroupedSection(
                surfaceStyle: GlassSurfaceStyle.solid,
                margin: EdgeInsets.zero,
                children: [
                  for (final stem in wrongStems.take(30))
                    GlassListTile(
                      leading: Icon(CupertinoIcons.xmark_circle,
                          color: AppTheme.destructive),
                      title: Text(
                        stem,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium,
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
