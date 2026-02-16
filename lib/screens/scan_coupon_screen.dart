import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import 'package:rabacik/data/models/coupon.dart';
import 'package:rabacik/screens/add_coupon_screen.dart'; // Import AddCouponScreen

class ScanCouponScreen extends StatefulWidget {
  final File imageFile;
  const ScanCouponScreen({super.key, required this.imageFile});

  @override
  State<ScanCouponScreen> createState() => _ScanCouponScreenState();
}

class _ScanCouponScreenState extends State<ScanCouponScreen> {
  late File _image;
  List<TextLine> _recognizedLines = [];
  bool _isLoading = false;
  Map<int, String> _selectedTypes = {};
  @override
  void initState() {
    super.initState();
    _image = widget.imageFile;
    _recognizedLines = [];
    _recognizeText(_image);
  }

  Future<void> _pickImage({bool fromGallery = false}) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: fromGallery ? ImageSource.gallery : ImageSource.camera,
    );
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
        _recognizedLines = [];
      });
      await _recognizeText(_image!);
    }
  }

  Future<void> _recognizeText(File image) async {
    setState(() { _isLoading = true; });
    final inputImage = InputImage.fromFile(image);
    final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
    final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);
    await textRecognizer.close();
    final lines = recognizedText.blocks.expand((b) => b.lines).toList();
    setState(() {
      _recognizedLines = lines;
      _isLoading = false;
    });
    if (lines.isEmpty) {
      // Show dialog if no text recognized
      if (mounted) {
        final result = await showDialog<String>(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Text('Nie rozpoznano tekstu'),
            content: const Text('Nie rozpoznałem żadnego tekstu na zdjęciu, spróbuj zrobić nowe zdjęcie albo wprowadź dane kuponu ręcznie'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop('photo');
                },
                child: const Text('Zrób zdjęcie'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop('manual');
                },
                child: const Text('Wprowadź ręcznie'),
              ),
            ],
          ),
        );
        if (result == 'photo') {
          _pickImage(fromGallery: false);
        } else if (result == 'manual') {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => AddCouponScreen(),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Skanuj kupon (OCR)'),),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const SizedBox(height: 16),
            if (_image != null)
              Expanded(
                child: FutureBuilder<Size>(
                  future: _getImageSize(_image!),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final imageSize = snapshot.data!;
                    return LayoutBuilder(
                      builder: (context, constraints) {
                        final displayWidth = constraints.maxWidth;
                        final displayHeight = constraints.maxHeight;
                        // Calculate scale and offset to fit image in the available space
                        final scale = _calculateScale(imageSize, Size(displayWidth, displayHeight));
                        final offset = _calculateOffset(imageSize, Size(displayWidth, displayHeight));
                        return Stack(
                          children: [
                            Image.file(_image!, width: displayWidth, height: displayHeight, fit: BoxFit.contain),
                            ..._recognizedLines.asMap().entries.map((entry) {
                              final index = entry.key;
                              final line = entry.value;
                              final rect = line.boundingBox;
                              if (rect == null) return SizedBox.shrink();
                              final left = rect.left * scale + offset.dx;
                              final top = rect.top * scale + offset.dy;
                              final width = rect.width * scale;
                              final height = rect.height * scale;
                              return Positioned(
                                left: left,
                                top: top,
                                width: width,
                                height: height,
                                child: GestureDetector(
                                  onTap: () async {
                                    final result = await showDialog<Map<String, dynamic>>(
                                      context: context,
                                      builder: (context) {
                                        return _SelectableTextDialog(line: line);
                                      },
                                    );
                                    if (result != null && result['type'] != null) {
                                      setState(() {
                                        _selectedTypes[index] = result['type'];
                                      });
                                    }
                                  },
                                  child: Container(
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: _selectedTypes[index] == 'code'
                                            ? Colors.green
                                            : _selectedTypes[index] == 'issuer'
                                                ? Colors.blue
                                                : _selectedTypes[index] == 'discount'
                                                    ? Colors.purple
                                                    : _selectedTypes[index] == 'expiry'
                                                        ? Colors.orange
                                                        : Colors.red,
                                        width: 2,
                                      ),
                                      color: Colors.white.withOpacity(0.1),
                                    ),
                                    child: Center(
                                      child: Text(
                                        line.text,
                                        style: const TextStyle(
                                          color: Colors.black,
                                          fontWeight: FontWeight.bold,
                                          backgroundColor: Colors.white70,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ],
                        );
                      },
                    );
                  },
                ),
              ),
            if (_recognizedLines.isNotEmpty) ...[
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  String code = '';
                  String issuer = '';
                  String discount = '';
                  String expiry = '';
                  _selectedTypes.forEach((index, type) {
                    final lineText = _recognizedLines[index].text;
                    if (type == 'code') {
                      code = lineText;
                    } else if (type == 'issuer') {
                      issuer = lineText;
                    } else if (type == 'discount') {
                      final cleaned = lineText.replaceAll(RegExp(r'[-%\\s]'), '');
                      discount = int.tryParse(cleaned)?.toString() ?? '';
                    } else if (type == 'expiry') {
                      expiry = lineText;
                    }
                  });
                  int discountInt = int.tryParse(discount) ?? 0;
                  DateTime? expiryDate;
                  try {
                    expiryDate = DateTime.tryParse(expiry);
                  } catch (_) {
                    expiryDate = null;
                  }
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => AddCouponScreen(
                        coupon: Coupon(
                          code: code,
                          issuer: issuer,
                          discount: discountInt,
                          expiryDate: expiryDate,
                        ),
                      ),
                    ),
                  );
                },
                child: const Text('Zapisz kupon'),
              ),
              const SizedBox(height: 24),
            ],
          ],
        ),
      ),
    );
  }

  // --- helpers for image scaling ---
  Future<Size> _getImageSize(File file) async {
    final completer = Completer<Size>();
    final image = Image.file(file);
    image.image.resolve(const ImageConfiguration()).addListener(
      ImageStreamListener((ImageInfo info, bool _) {
        completer.complete(Size(
          info.image.width.toDouble(),
          info.image.height.toDouble(),
        ));
      }),
    );
    return completer.future;
  }

  double _calculateScale(Size imageSize, Size displaySize) {
    final scaleX = displaySize.width / imageSize.width;
    final scaleY = displaySize.height / imageSize.height;
    return scaleX < scaleY ? scaleX : scaleY;
  }

  Offset _calculateOffset(Size imageSize, Size displaySize) {
    final scale = _calculateScale(imageSize, displaySize);
    final dx = (displaySize.width - imageSize.width * scale) / 2;
    final dy = (displaySize.height - imageSize.height * scale) / 2;
    return Offset(dx, dy);
  }
}

// --- helper widget for selectable text dialog ---
class _SelectableTextDialog extends StatefulWidget {
  final TextLine line;
  const _SelectableTextDialog({required this.line});
  @override
  State<_SelectableTextDialog> createState() => _SelectableTextDialogState();
}

class _SelectableTextDialogState extends State<_SelectableTextDialog> {
  bool showTextField = false;
  late TextEditingController textController;
  late FocusNode focusNode;

  @override
  void initState() {
    super.initState();
    textController = TextEditingController(text: widget.line.text);
    focusNode = FocusNode();
  }

  @override
  void dispose() {
    textController.dispose();
    focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SimpleDialog(
      title: const Text('Wybierz typ danych'),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: showTextField
              ? TextField(
                  controller: textController,
                  focusNode: focusNode,
                  maxLines: null,
                  autofocus: true,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Zaznacz fragment tekstu',
                  ),
                )
              : GestureDetector(
                  onTap: () {
                    setState(() {
                      showTextField = true;
                      // Ustaw focus na TextField po przełączeniu
                      Future.delayed(const Duration(milliseconds: 100), () {
                        focusNode.requestFocus();
                      });
                    });
                  },
                  child: Text(
                    widget.line.text,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
        ),
        const Divider(),
        SimpleDialogOption(
          onPressed: () => Navigator.pop(context, {'type': 'code', 'text': textController.selection.isValid && !textController.selection.isCollapsed ? textController.text.substring(textController.selection.start, textController.selection.end) : textController.text}),
          child: const Text('Kod kuponu'),
        ),
        SimpleDialogOption(
          onPressed: () => Navigator.pop(context, {'type': 'issuer', 'text': textController.selection.isValid && !textController.selection.isCollapsed ? textController.text.substring(textController.selection.start, textController.selection.end) : textController.text}),
          child: const Text('Wystawca kuponu'),
        ),
        SimpleDialogOption(
          onPressed: () => Navigator.pop(context, {'type': 'discount', 'text': textController.selection.isValid && !textController.selection.isCollapsed ? textController.text.substring(textController.selection.start, textController.selection.end) : textController.text}),
          child: const Text('Wartość zniżki'),
        ),
        SimpleDialogOption(
          onPressed: () => Navigator.pop(context, {'type': 'expiry', 'text': textController.selection.isValid && !textController.selection.isCollapsed ? textController.text.substring(textController.selection.start, textController.selection.end) : textController.text}),
          child: const Text('Data ważności'),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Anuluj'),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}
