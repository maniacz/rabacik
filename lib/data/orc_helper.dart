import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

/// Filtruje linie tekstu: tylko krótkie i z większą czcionką
List<TextLine> filterRecognizedLines(
  List<TextLine> lines, {
  int maxLength = 30,
  double minFontHeight = 18.0,
}) {
  final dateRegExp = RegExp(r'(?<!\d)(?:20\d{2}[-.](?:0\d|1[0-2]|O\d)[-.](?:0\d|[12]\d|3[01])|(?:0?\d|[12]\d|3[01])[-.](?:0\d|1[0-2]|O\d)[-.]20\d{2}|(?:0?\d|[12]\d|3[01])[-.](?:0\d|1[0-2]|O\d))(?!\d)');
  return lines.where((line) {
    final text = line.text.trim();
    if (dateRegExp.hasMatch(text)) return true;
    if (text.length > maxLength) return false;
    if (line.boundingBox == null) return false;
    final height = line.boundingBox.height;
    if (height < minFontHeight) return false;
    return true;
  }).toList();
}
