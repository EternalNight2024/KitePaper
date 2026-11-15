import 'package:flutter/material.dart';

import '../core/store.dart';
import '../core/ui.dart';

class ResultsPage extends StatelessWidget {
  const ResultsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final theme = Theme.of(context);
        final results = store.results;
        final wrongStems = <String>{
          for (final result in results) ...result.wrongStems,
        };

        return ListView(
          padding: pagePadding,
          children: [
            sectionHeader(context, '练习记录 · ${results.length}'),
            if (results.isEmpty)
              const GlassPanel(child: Text('还没有成绩，去「试卷」开始练习'))
            else
              for (final result in results)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: GlassPanel(
                    radius: 18,
                    sigma: 18,
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        GlassIconBadge(
                          icon: Icons.insights_outlined,
                          color: result.total > 0 &&
                                  result.score / result.total >= 0.6
                              ? const Color(0xFF30A46C)
                              : const Color(0xFFFF9F0A),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      result.paperTitle,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: theme.textTheme.titleSmall,
                                    ),
                                  ),
                                  Text(
                                    '${result.score.toStringAsFixed(0)} / ${result.total.toStringAsFixed(0)}',
                                    style: theme.textTheme.titleSmall,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              mutedText(
                                context,
                                '对 ${result.correctCount} · 错 ${result.wrongCount} · '
                                '待批阅 ${result.pendingCount} · '
                                '${result.finishedAt.toString().substring(0, 16)}',
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            if (results.isNotEmpty) ...[
              const SizedBox(height: 4),
              Align(
                alignment: Alignment.centerLeft,
                child: GlassButton(
                  label: '清空记录',
                  icon: Icons.delete_sweep_outlined,
                  primary: false,
                  compact: true,
                  onPressed: store.clearResults,
                ),
              ),
            ],
            const SizedBox(height: 22),
            sectionHeader(context, '错题本 · ${wrongStems.length}'),
            if (wrongStems.isEmpty)
              const GlassPanel(child: Text('暂无错题'))
            else
              for (final stem in wrongStems.take(30))
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: GlassPanel(
                    radius: 18,
                    sigma: 18,
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const GlassIconBadge(
                          icon: Icons.error_outline,
                          color: Color(0xFFFF453A),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            stem,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodyMedium,
                          ),
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
