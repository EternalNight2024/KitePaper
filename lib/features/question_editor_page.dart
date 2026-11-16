import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../core/app_background.dart';
import '../core/layout.dart';
import '../core/models.dart';
import '../core/store.dart';
import '../theme/app_theme.dart';
import 'shared_widgets.dart';

/// 新增题目：尽量用按钮/点选替代键盘输入。
///
/// - 题型、答案、分值、知识点均以点击选择为主；
/// - 选项由「添加选项」按钮逐条增删，不再用 `|` 手工拼接；
/// - 只有题干、填空题答案、解析与自定义知识点仍需要输入文字。
class QuestionEditorPage extends StatefulWidget {
  const QuestionEditorPage({super.key});

  @override
  State<QuestionEditorPage> createState() => _QuestionEditorPageState();
}

class _QuestionEditorPageState extends State<QuestionEditorPage> {
  final _stem = TextEditingController();
  final List<TextEditingController> _options = [
    TextEditingController(),
    TextEditingController(),
    TextEditingController(),
    TextEditingController(),
  ];
  final _answerText = TextEditingController();
  final _knowledge = TextEditingController();
  final _analysis = TextEditingController();

  QuestionType _type = QuestionType.single;
  double _score = 2;
  final Set<String> _selectedLetters = <String>{};
  bool _customKnowledge = false;

  TextStyle? get _inputStyle => AppTheme.fontFamilyOverride == null
      ? null
      : TextStyle(fontFamily: AppTheme.fontFamilyOverride);

  @override
  void dispose() {
    _stem.dispose();
    for (final controller in _options) {
      controller.dispose();
    }
    _answerText.dispose();
    _knowledge.dispose();
    _analysis.dispose();
    super.dispose();
  }

  void _onTypeChanged(QuestionType type) {
    setState(() {
      _type = type;
      _selectedLetters.clear();
      if (type == QuestionType.trueFalse) {
        // 判断题的选项固定，无需用户填写。
        while (_options.length < 2) {
          _options.add(TextEditingController());
        }
        while (_options.length > 2) {
          _options.removeLast().dispose();
        }
        _options[0].text = '正确';
        _options[1].text = '错误';
      } else if (type.hasOptions) {
        while (_options.length < 2) {
          _options.add(TextEditingController());
        }
        if (_options.length == 2 &&
            _options[0].text == '正确' &&
            _options[1].text == '错误') {
          _options[0].clear();
          _options[1].clear();
        }
      }
    });
  }

  void _addOption() {
    if (_options.length >= optionLetters.length) return;
    setState(() => _options.add(TextEditingController()));
  }

  void _removeOption(int index) {
    if (_options.length <= 2) return;
    setState(() {
      final updated = <String>{};
      for (final letter in _selectedLetters) {
        final oldIndex = optionLetters.indexOf(letter);
        if (oldIndex < 0 || oldIndex == index) continue;
        updated.add(optionLetter(oldIndex > index ? oldIndex - 1 : oldIndex));
      }
      _selectedLetters
        ..clear()
        ..addAll(updated);
      _options.removeAt(index).dispose();
    });
  }

  void _toggleLetter(String letter) {
    setState(() {
      if (_type == QuestionType.multiple) {
        if (!_selectedLetters.remove(letter)) _selectedLetters.add(letter);
      } else {
        _selectedLetters
          ..clear()
          ..add(letter);
      }
    });
  }

  Future<void> _save() async {
    final stem = _stem.text.trim();
    if (!mounted) return;
    if (stem.isEmpty) {
      GlassToast.show(context, message: '题干不能为空', type: GlassToastType.error);
      return;
    }

    final options = <String>[];
    final sourceLetters = <String>[];
    if (_type.hasOptions) {
      for (var i = 0; i < _options.length; i++) {
        final text = _options[i].text.trim();
        if (text.isEmpty) continue;
        options.add(text);
        sourceLetters.add(optionLetter(i));
      }
      if (options.length < 2) {
        GlassToast.show(context,
            message: '请至少填写 2 个选项', type: GlassToastType.error);
        return;
      }
    }

    final answers = <String>[];
    if (_type == QuestionType.essay) {
      // 简答题离线标记为待批阅，不需要参考答案。
    } else if (_type == QuestionType.fillBlank) {
      answers.addAll(_answerText.text
          .split('|')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty));
      if (answers.isEmpty) {
        GlassToast.show(context, message: '请填写答案', type: GlassToastType.error);
        return;
      }
    } else {
      for (final letter in _selectedLetters) {
        final index = sourceLetters.indexOf(letter);
        if (index >= 0) answers.add(optionLetter(index));
      }
      if (answers.isEmpty) {
        GlassToast.show(context,
            message: '请点击选项右侧的字母选择答案', type: GlassToastType.error);
        return;
      }
    }

    await store.addQuestion(Question(
      id: newId(),
      stem: stem,
      type: _type,
      options: options,
      answers: answers,
      score: _score,
      knowledge: _knowledge.text.trim(),
      analysis: _analysis.text.trim(),
    ));
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final typeColor = AppTheme.typeColor(_type);
    return GlassScaffold(
      background: const AppBackground(),
      backgroundColor: appBackgroundColor(Theme.of(context).brightness),
      statusBarStyle: GlassStatusBarStyle.auto,
      appBar: GlassAppBar(
        centerTitle: false,
        title: Text('新增题目', style: theme.textTheme.titleMedium),
        actions: [
          SizedBox(
            width: 68,
            child: GlassButton.custom(
              onTap: _save,
              height: 32,
              shape: const LiquidRoundedSuperellipse(borderRadius: 11),
              child: Center(
                child: Text(
                  '保存',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: CupertinoTheme.of(context)
                        .textTheme
                        .textStyle
                        .color ?? CupertinoColors.label,
                    fontFamily: AppTheme.fontFamilyOverride,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(20, appBarSafeTop(context) + 8, 20, 40),
        children: [
          sectionHeader(context, '① 选择题型'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final type in QuestionType.values)
                GlassChip(
                  label: type.label,
                  selected: _type == type,
                  surfaceStyle: GlassSurfaceStyle.solid,
                  selectedColor: AppTheme.typeColor(type),
                  labelStyle: TextStyle(
                    fontSize: 13,
                    fontFamily: AppTheme.fontFamilyOverride,
                  ),
                  onTap: () => _onTypeChanged(type),
                ),
            ],
          ),
          const SizedBox(height: 22),
          sectionHeader(context, '② 输入题干'),
          GlassContainer.card(
            surfaceStyle: GlassSurfaceStyle.solid,
            padding: const EdgeInsets.all(14),
            child: GlassTextArea(
              controller: _stem,
              placeholder: '输入题目描述',
              minLines: 3,
              maxLines: 5,
              textStyle: _inputStyle,
              placeholderStyle: _inputStyle,
            ),
          ),
          if (_type.hasOptions) ...[
            const SizedBox(height: 22),
            sectionHeader(context,
                _type == QuestionType.trueFalse ? '③ 判断题选项（已预设）' : '③ 添加选项'),
            if (_type == QuestionType.trueFalse)
              _presetOptions()
            else
              _editableOptions(typeColor),
          ],
          const SizedBox(height: 22),
          sectionHeader(context, _type.hasOptions ? '④ 点击选择答案' : '④ 填写答案'),
          if (_type.hasOptions)
            _answerPicker(typeColor)
          else if (_type == QuestionType.fillBlank)
            GlassContainer.card(
              surfaceStyle: GlassSurfaceStyle.solid,
              padding: const EdgeInsets.all(14),
              child: GlassTextField(
                controller: _answerText,
                placeholder: '输入答案（多个用 | 分隔）',
                textStyle: _inputStyle,
                placeholderStyle: _inputStyle,
              ),
            )
          else
            GlassContainer.card(
              surfaceStyle: GlassSurfaceStyle.solid,
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Icon(CupertinoIcons.info, size: 17, color: AppTheme.typeEssay),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '简答题在离线版本中标记为「待批阅」，无需填写答案。',
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 22),
          sectionHeader(context, '⑤ 分值（点击调整）'),
          _scoreRow(),
          const SizedBox(height: 22),
          sectionHeader(context, '⑥ 知识点（点选或自定义）'),
          _knowledgePicker(theme),
          const SizedBox(height: 22),
          sectionHeader(context, '⑦ 解析（选填）'),
          GlassContainer.card(
            surfaceStyle: GlassSurfaceStyle.solid,
            padding: const EdgeInsets.all(14),
            child: GlassTextArea(
              controller: _analysis,
              placeholder: '输入解析',
              minLines: 2,
              maxLines: 4,
              textStyle: _inputStyle,
              placeholderStyle: _inputStyle,
            ),
          ),
          const SizedBox(height: 24),
          ActionGlassButton(
            label: '保存到本地题库',
            icon: CupertinoIcons.checkmark,
            prominent: true,
            accent: AppTheme.teacher,
            onTap: _save,
          ),
          const SizedBox(height: 10),
          Center(
            child: Text('数据仅保存于本机', style: theme.textTheme.labelSmall),
          ),
        ],
      ),
    );
  }

  /// 判断题的预设选项，纯展示不可编辑。
  Widget _presetOptions() => GlassContainer.card(
        surfaceStyle: GlassSurfaceStyle.solid,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        child: Column(
          children: [
            for (var i = 0; i < _options.length; i++)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    _letterBadge(optionLetter(i), AppTheme.typeTrueFalse),
                    const SizedBox(width: 12),
                    Text(_options[i].text,
                        style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ),
              ),
          ],
        ),
      );

  /// 可编辑的选项列表：每行一个输入框 + 删除按钮，底部「添加选项」。
  Widget _editableOptions(Color typeColor) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GlassContainer.card(
            surfaceStyle: GlassSurfaceStyle.solid,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            child: Column(
              children: [
                for (var i = 0; i < _options.length; i++)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    child: Row(
                      children: [
                        _letterBadge(optionLetter(i), typeColor),
                        const SizedBox(width: 10),
                        Expanded(
                          child: GlassTextField(
                            controller: _options[i],
                            placeholder: '选项 ${optionLetter(i)} 内容',
                            textStyle: _inputStyle,
                            placeholderStyle: _inputStyle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        GestureDetector(
                          onTap: () => _removeOption(i),
                          behavior: HitTestBehavior.opaque,
                          child: Padding(
                            padding: const EdgeInsets.all(6),
                            child: Icon(
                              CupertinoIcons.minus_circle,
                              size: 19,
                              color: _options.length <= 2
                                  ? CupertinoColors.quaternaryLabel
                                  : AppTheme.destructive,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerLeft,
            child: ActionGlassButton(
              label: '添加选项 · ${_options.length}/${optionLetters.length}',
              icon: CupertinoIcons.plus,
              compact: true,
              accent: AppTheme.typeColor(_type),
              onTap: _options.length >= optionLetters.length ? null : _addOption,
            ),
          ),
        ],
      );

  Widget _letterBadge(String letter, Color color) => Container(
        width: 28,
        height: 28,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(9),
        ),
        child: Text(
          letter,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: color,
            fontFamily: AppTheme.fontFamilyOverride,
          ),
        ),
      );

  /// 答案点选：单选/判断只能选一个，多选可切换多个。
  Widget _answerPicker(Color typeColor) {
    final letters = <String>[];
    final labels = <String>[];
    for (var i = 0; i < _options.length; i++) {
      final text = _options[i].text.trim();
      if (text.isEmpty) continue;
      letters.add(optionLetter(i));
      labels.add(text);
    }
    if (letters.isEmpty) {
      return GlassContainer.card(
        surfaceStyle: GlassSurfaceStyle.solid,
        padding: const EdgeInsets.all(14),
        child: Text('请先添加选项', style: Theme.of(context).textTheme.bodySmall),
      );
    }
    return GlassContainer.card(
      surfaceStyle: GlassSurfaceStyle.solid,
      padding: const EdgeInsets.all(14),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (var i = 0; i < letters.length; i++)
            GlassChip(
              label: '${letters[i]} · ${labels[i]}',
              selected: _selectedLetters.contains(letters[i]),
              surfaceStyle: GlassSurfaceStyle.solid,
              selectedColor: typeColor,
              labelStyle: TextStyle(
                fontSize: 13,
                fontFamily: AppTheme.fontFamilyOverride,
              ),
              onTap: () => _toggleLetter(letters[i]),
            ),
        ],
      ),
    );
  }

  /// 分值：原生 GlassStepper 点击调整，不再键盘输入。
  Widget _scoreRow() {
    final theme = Theme.of(context);
    return GlassContainer.card(
      surfaceStyle: GlassSurfaceStyle.solid,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          Text('分值', style: theme.textTheme.bodyMedium),
          const Spacer(),
          Text(
            _score == _score.roundToDouble()
                ? _score.toStringAsFixed(0)
                : _score.toStringAsFixed(1),
            style: theme.textTheme.headlineSmall?.copyWith(color: AppTheme.teacher),
          ),
          const SizedBox(width: 14),
          GlassStepper(
            value: _score,
            min: 1,
            max: 20,
            step: 1,
            onChanged: (value) => setState(() => _score = value),
          ),
        ],
      ),
    );
  }

  /// 知识点：从题库已有知识点中点选，或切换为自定义输入。
  Widget _knowledgePicker(ThemeData theme) {
    final suggestions = <String>{
      for (final q in store.questions)
        if (q.knowledge.trim().isNotEmpty) q.knowledge.trim(),
    }.toList()..sort();

    return GlassContainer.card(
      surfaceStyle: GlassSurfaceStyle.solid,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final item in suggestions)
                GlassChip(
                  label: item,
                  selected: _knowledge.text == item && !_customKnowledge,
                  surfaceStyle: GlassSurfaceStyle.solid,
                  selectedColor: AppTheme.teacher,
                  labelStyle: TextStyle(
                    fontSize: 13,
                    fontFamily: AppTheme.fontFamilyOverride,
                  ),
                  onTap: () => setState(() {
                    _customKnowledge = false;
                    _knowledge.text =
                        _knowledge.text == item ? '' : item;
                  }),
                ),
              GlassChip(
                label: '自定义',
                selected: _customKnowledge,
                surfaceStyle: GlassSurfaceStyle.solid,
                selectedColor: AppTheme.teacher,
                labelStyle: TextStyle(
                  fontSize: 13,
                  fontFamily: AppTheme.fontFamilyOverride,
                ),
                onTap: () => setState(() {
                  _customKnowledge = true;
                  _knowledge.clear();
                }),
              ),
            ],
          ),
          if (_customKnowledge) ...[
            const SizedBox(height: 12),
            GlassTextField(
              controller: _knowledge,
              placeholder: '输入知识点',
              textStyle: _inputStyle,
              placeholderStyle: _inputStyle,
            ),
          ],
        ],
      ),
    );
  }
}
