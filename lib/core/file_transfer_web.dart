import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:web/web.dart' as web;

Future<Uint8List?> pickQtiFile() async {
  final file = await FilePicker.pickFile(
    type: FileType.custom,
    allowedExtensions: const ['xml', 'qti', 'ktp'],
  );
  if (file == null) return null;
  return file.readAsBytes();
}

Future<String> saveQtiFile(String fileName, Uint8List bytes) async {
  final anchor = web.HTMLAnchorElement()
    ..href = 'data:application/xml;base64,${base64Encode(bytes)}'
    ..download = fileName;
  web.document.body!.appendChild(anchor);
  anchor.click();
  anchor.remove();
  return fileName;
}
