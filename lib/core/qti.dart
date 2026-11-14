import 'dart:convert';

import 'package:xml/xml.dart';

import 'models.dart';

const qtiProfile = 'kitepaper-qti12-1';

String exportQti(Paper paper) {
  final builder = XmlBuilder();
  builder.processing('xml', 'version="1.0" encoding="UTF-8"');
  builder.element('questestinterop', nest: () {
    builder.element('assessment', attributes: {
      'ident': paper.id,
      'title': paper.title,
      'kp_profile': qtiProfile,
      'kp_duration': paper.durationMinutes.toString(),
      'kp_description': paper.description,
      'kp_created': paper.createdAt.toIso8601String(),
    }, nest: () {
      builder.element('section', attributes: {'ident': 'main'}, nest: () {
        for (final question in paper.questions) {
          _writeItem(builder, question);
        }
      });
    });
  });
  return builder.buildDocument().toXmlString(pretty: true);
}

Paper importQti(String source) {
  try {
    final document = XmlDocument.parse(source);
    final assessment = _first(document.findAllElements('assessment'));
    if (assessment == null) {
      throw const FormatException('缺少 assessment 节点，不是有效的 QTI 试卷');
    }

    final questions = <Question>[];
    for (final item in document.findAllElements('item')) {
      final presentation = _first(item.findAllElements('presentation'));
      final stem = presentation == null
          ? ''
          : _text(_first(presentation.findAllElements('mattext')));
      final options = <String>[];
      final answers = <String>[];

      for (final label in item.findAllElements('response_label')) {
        options.add(_text(_first(label.findAllElements('mattext'))));
      }
      for (final equal in item.findAllElements('varequal')) {
        answers.add(equal.innerText.trim());
      }

      final encodedAnswers = _meta(item, 'kp_answers');
      final storedAnswers = encodedAnswers.isEmpty
          ? answers
          : (jsonDecode(encodedAnswers) as List<dynamic>)
              .map((e) => e.toString())
              .toList();

      questions.add(Question(
        id: item.getAttribute('ident') ?? newId(),
        stem: stem,
        type: questionTypeFromCode(_meta(item, 'kp_type')),
        options: options,
        answers: storedAnswers,
        score: double.tryParse(_meta(item, 'kp_score')) ?? 2,
        knowledge: _meta(item, 'kp_knowledge'),
        analysis: _meta(item, 'kp_analysis'),
      ));
    }

    if (questions.isEmpty) {
      throw const FormatException('试卷中没有可导入的 item');
    }

    return Paper(
      id: assessment.getAttribute('ident') ?? newId(),
      title: assessment.getAttribute('title') ?? '导入的试卷',
      description: assessment.getAttribute('kp_description') ?? '',
      questions: questions,
      durationMinutes:
          int.tryParse(assessment.getAttribute('kp_duration') ?? '') ?? 30,
      createdAt:
          DateTime.tryParse(assessment.getAttribute('kp_created') ?? '') ??
              DateTime.now(),
    );
  } on FormatException {
    rethrow;
  } catch (error) {
    throw FormatException('QTI 解析失败：$error');
  }
}

void _writeItem(XmlBuilder builder, Question question) {
  builder.element('item', attributes: {
    'ident': question.id,
    'title': question.stem,
  }, nest: () {
    builder.element('itemmetadata', nest: () {
      builder.element('qtimetadata', nest: () {
        _metaField(builder, 'kp_type', question.type.code);
        _metaField(builder, 'kp_score', question.score.toString());
        _metaField(builder, 'kp_knowledge', question.knowledge);
        _metaField(builder, 'kp_analysis', question.analysis);
        _metaField(builder, 'kp_answers', jsonEncode(question.answers));
      });
    });

    builder.element('presentation', nest: () {
      builder.element('flow', nest: () {
        builder.element('material', nest: () {
          builder.element('mattext', attributes: {'texttype': 'text/plain'},
              nest: () => builder.text(question.stem));
        });
        if (question.type.hasOptions) {
          builder.element('response_lid', attributes: {
            'ident': 'RESPONSE',
            'rcardinality':
                question.type == QuestionType.multiple ? 'Multiple' : 'Single',
          }, nest: () {
            builder.element('render_choice', nest: () {
              for (var i = 0; i < question.options.length; i++) {
                builder.element('response_label',
                    attributes: {'ident': optionLetter(i)}, nest: () {
                  builder.element('flow_mat', nest: () {
                    builder.element('material', nest: () {
                      builder.element('mattext', nest: () {
                        builder.text(question.options[i]);
                      });
                    });
                  });
                });
              }
            });
          });
        } else {
          builder.element('response_str', attributes: {'ident': 'RESPONSE'},
              nest: () {
            builder.element('render_fib', attributes: {
              'rows': question.type == QuestionType.essay ? '5' : '1',
              'columns': '40',
            });
          });
        }
      });
    });

    builder.element('resprocessing', nest: () {
      builder.element('outcomes', nest: () {
        builder.element('decvar', attributes: {
          'varname': 'SCORE',
          'vartype': 'Decimal',
          'minvalue': '0',
          'maxvalue': question.score.toString(),
        });
      });
      for (final answer in question.answers) {
        builder.element('respcondition', attributes: {'continue': 'No'},
            nest: () {
          builder.element('conditionvar', nest: () {
            builder.element('varequal',
                attributes: {'respident': 'RESPONSE', 'case': 'No'},
                nest: () => builder.text(answer));
          });
          builder.element('setvar', attributes: {
            'outcomevar': 'SCORE',
            'action': 'Set',
            'varname': 'SCORE',
          }, nest: () => builder.text(question.score.toString()));
        });
      }
    });

    builder.element('itemfeedback', attributes: {'ident': 'solution'},
        nest: () {
      builder.element('flow_mat', nest: () {
        builder.element('material', nest: () {
          builder.element('mattext', nest: () {
            builder.text(question.analysis);
          });
        });
      });
    });
  });
}

void _metaField(XmlBuilder builder, String label, String entry) {
  builder.element('qtimetadatafield', nest: () {
    builder.element('fieldlabel', nest: () => builder.text(label));
    builder.element('fieldentry', nest: () => builder.text(entry));
  });
}

String _meta(XmlElement item, String label) {
  for (final field in item.findAllElements('qtimetadatafield')) {
    if (_text(_first(field.findAllElements('fieldlabel'))) == label) {
      return _text(_first(field.findAllElements('fieldentry')));
    }
  }
  return '';
}

XmlElement? _first(Iterable<XmlElement> elements) =>
    elements.isEmpty ? null : elements.first;

String _text(XmlElement? element) => element?.innerText.trim() ?? '';
