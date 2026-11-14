import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:material_ui/material_ui.dart';

import '../core/store.dart';
import '../core/ui.dart';

class ResultsPage extends StatelessWidget {
  const ResultsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final results = store.results;
        final wrongStems = <String>{
          for (final result in results) ...result.wrongStems,
        };

        return ListView(
          padding: pagePadding,
          children: [
            GlassGroupedSection(
              surfaceStyle: GlassSurfaceStyle.solid,
              header: Text('练习记录 · ${results.length}'),
              children: results.isEmpty
                  ? const [
                      GlassListTile(
                        title: Text('还没有成绩，去「试卷」开始练习'),
                      ),
                    ]
                  : [
                      for (final result in results)
                        GlassListTile(
                          leading: const Icon(Icons.assessment),
                          title: Text(result.paperTitle),
                          subtitle: Text(
                            '${result.score} / ${result.total} 分 · '
                            '对 ${result.correctCount} 错 ${result.wrongCount} '
                            '待批阅 ${result.pendingCount} · '
                            '${result.finishedAt.toString().substring(0, 16)}',
                          ),
                        ),
                    ],
            ),
            if (results.isNotEmpty) ...[
              const SizedBox(height: 12),
              GlassButton.custom(
                width: 160,
                height: 46,
                onTap: () => store.clearResults(),
                child: const Text('清空记录'),
              ),
            ],
            const SizedBox(height: 20),
            GlassGroupedSection(
              surfaceStyle: GlassSurfaceStyle.solid,
              header: Text('错题本 · ${wrongStems.length}'),
              children: wrongStems.isEmpty
                  ? const [GlassListTile(title: Text('暂无错题'))]
                  : [
                      for (final stem in wrongStems.take(30))
                        GlassListTile(
                          leading: const Icon(Icons.error_outline),
                          title: Text(
                            stem,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
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
