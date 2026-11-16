import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../core/layout.dart';
import '../core/models.dart';
import '../core/store.dart';

import 'shared_widgets.dart';

class GuidePage extends StatelessWidget {
  const GuidePage({super.key, required this.mode, this.controller});

  final AppMode mode;
  final GlassLargeTitleController? controller;

  static const _onlineSlots = [
    (
      icon: CupertinoIcons.cloud,
      title: '云端同步',
      detail: '账号登录、题库与成绩跨设备同步（待接入服务端）',
    ),
    (
      icon: CupertinoIcons.chat_bubble_2,
      title: '在线批阅',
      detail: '简答题由教师或服务端批阅后回写得分（当前标记为待批阅）',
    ),
    (
      icon: CupertinoIcons.person_3,
      title: '班级与分发',
      detail: '按班级分发试卷、收集答卷与统计学情',
    ),
    (
      icon: CupertinoIcons.sparkles,
      title: '智能组卷',
      detail: '按知识点、难度与分值自动生成试卷',
    ),
  ];

  Future<void> _restore(BuildContext context) async {
    await store.restoreTutorial();
    if (!context.mounted) return;
    GlassToast.show(context, message: '已恢复内置教程数据');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GlassPageBody(
      controller: controller,
      title: '指引',
      children: [
        InfoCard(
          icon: mode == AppMode.teacher
              ? CupertinoIcons.person_crop_square
              : CupertinoIcons.book,
          title: '${mode.label} · 使用指引',
          detail: mode.description,
        ),
        const SizedBox(height: 22),
        sectionHeader(context, '离线流程'),
        GlassContainer.card(
          surfaceStyle: GlassSurfaceStyle.solid,
          padding: const EdgeInsets.all(15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _step(context, '1', '教师：出题与组卷',
                  '在「题库」新增或导入题目，再到「组卷」勾选题目生成试卷。'),
              _step(context, '2', '教师：导出分享',
                  '在「试卷」点击「导出 QTI」，把 .qti 文件发送给他人。'),
              _step(context, '3', '学生：导入与练习',
                  '学生模式导入 QTI 试卷，逐题作答，客观题即时判分。'),
              _step(context, '4', '学生：交卷与复盘',
                  '交卷后查看总分、错题本；简答题进入待批阅列表。',
                  last: true),
            ],
          ),
        ),
        const SizedBox(height: 14),
        ActionGlassButton(
          label: '恢复教程数据',
          icon: CupertinoIcons.arrow_counterclockwise,
          compact: true,
          onTap: () => _restore(context),
        ),
        const SizedBox(height: 26),
        sectionHeader(context, '在线功能 · 即将上线'),
        GlassGroupedSection(
          surfaceStyle: GlassSurfaceStyle.solid,
          margin: EdgeInsets.zero,
          children: [
            for (final slot in _onlineSlots)
              GlassListTile(
                leading: Icon(slot.icon),
                title: Row(
                  children: [
                    Expanded(
                      child: Text(slot.title,
                          style: theme.textTheme.bodyMedium),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(999),
                        color: theme.colorScheme.primary
                            .withValues(alpha: 0.10),
                      ),
                      child: Text('预留', style: theme.textTheme.labelSmall),
                    ),
                  ],
                ),
                subtitle: Text(slot.detail,
                    maxLines: 3, style: theme.textTheme.bodySmall),
              ),
          ],
        ),
        const SizedBox(height: 10),
        Center(
          child: Text('全部数据仅保存在本机，在线功能为后续预留',
              style: theme.textTheme.labelSmall),
        ),
      ],
    );
  }

  Widget _step(BuildContext context, String number, String title, String detail,
      {bool last = false}) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: last ? 0 : 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 26,
            height: 26,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(9),
              color: theme.colorScheme.primary.withValues(alpha: 0.12),
            ),
            child: Text(number, style: theme.textTheme.labelSmall),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.titleSmall),
                const SizedBox(height: 3),
                Text(detail, maxLines: 4, style: theme.textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
