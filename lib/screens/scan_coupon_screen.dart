import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import 'package:rabacik/data/models/coupon.dart';
import 'package:rabacik/screens/add_coupon_screen.dart'; // Import AddCouponScreen
import 'package:path_provider/path_provider.dart';
import 'package:image/image.dart' as img;

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
  int _rotationTurns = 0;
  DateTime? _recognizedExpiryDate;
  DateTime? _selectedValidFromDate;
  @override
  void initState() {
    super.initState();
    _image = widget.imageFile;
    _recognizedLines = [];
    _recognizeText(_image);
    _rotationTurns = 0;
    _recognizedExpiryDate = null;
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
        _rotationTurns = 0;
      });
      await _recognizeText(_image!);
    }
  }

  Future<void> _rotateImage() async {
    setState(() {
      _isLoading = true;
    });
    final bytes = await _image.readAsBytes();
    final original = img.decodeImage(bytes);
    if (original == null) {
      setState(() {
        _isLoading = false;
      });
      return;
    }
    final rotated = img.copyRotate(original, angle: 90);
    final rotatedBytes = img.encodeJpg(rotated);
    final tempDir = await getTemporaryDirectory();
    final rotatedFile = await File('${tempDir.path}/rotated_${DateTime.now().millisecondsSinceEpoch}.jpg').writeAsBytes(rotatedBytes);
    setState(() {
      _image = rotatedFile;
      _rotationTurns = (_rotationTurns + 1) % 4;
    });
    await _recognizeText(_image);
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
      return;
    }

    // --- WYKRYWANIE DAT ---
    final dateRegExp = RegExp(r'(\d{4}[-/.]\d{2}[-/.]\d{2}|\d{2}[-/.]\d{2}[-/.]\d{4})');
    final foundDates = <String>[];
    for (final line in lines) {
      final matches = dateRegExp.allMatches(line.text);
      for (final match in matches) {
        foundDates.add(match.group(0)!);
      }
    }
    if (foundDates.isNotEmpty && mounted) {
      if (foundDates.length == 1) {
        // Jedna data - zapytaj czy to data ważności
        final confirm = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Potwierdź datę ważności'),
            content: Text('Wykryto datę: ${foundDates.first}\nCzy to data ważności kuponu?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Nie'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Tak'),
              ),
            ],
          ),
        );
        if (confirm == true) {
          // Oznacz tę datę jako expiry
          final idx = lines.indexWhere((l) => l.text.contains(foundDates.first));
          if (idx != -1) {
            setState(() {
              _selectedTypes[idx] = 'expiry';
              _recognizedExpiryDate = _parseDate(foundDates.first);
            });
          }
        }
      } else if (foundDates.length == 2) {
        // Automatyczna sugestia: wcześniejsza data = validFrom, późniejsza = expiry
        List<String> sortedDates = List.from(foundDates);
        sortedDates.sort((a, b) {
          DateTime? da = _parseDate(a);
          DateTime? db = _parseDate(b);
          if (da == null || db == null) return 0;
          return da.compareTo(db);
        });
        final validFrom = sortedDates[0];
        final expiry = sortedDates[1];
        final confirm = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Wykryto dwie daty'),
            content: Text('Wykryto dwie daty:\n- $validFrom (ważny od)\n- $expiry (ważny do)\nCzy przypisać je automatycznie?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Nie'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Tak'),
              ),
            ],
          ),
        );
        if (confirm == true) {
          setState(() {
            final idxFrom = lines.indexWhere((l) => l.text.contains(validFrom));
            final idxTo = lines.indexWhere((l) => l.text.contains(expiry));
            if (idxFrom != -1) _selectedTypes[idxFrom] = 'validFrom';
            if (idxTo != -1) _selectedTypes[idxTo] = 'expiry';
            _selectedValidFromDate = _parseDate(validFrom);
            _recognizedExpiryDate = _parseDate(expiry);
          });
        } else {
          // Jeśli użytkownik nie potwierdzi, pokaż standardowy dialog wyboru ról
          Map<String, String> dateRoles = { for (var d in foundDates) d: '' };
          await showDialog<void>(
            context: context,
            builder: (context) {
              return AlertDialog(
                title: const Text('Przypisz rolę każdej dacie'),
                content: StatefulBuilder(
                  builder: (context, setStateDialog) {
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: foundDates.map((date) => Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(date),
                          Row(
                            children: [
                              Radio<String>(
                                value: 'validFrom',
                                groupValue: dateRoles[date],
                                onChanged: (val) {
                                  setStateDialog(() {
                                    if (!dateRoles.containsValue('validFrom') || dateRoles[date] == 'validFrom') {
                                      dateRoles[date] = val!;
                                    }
                                  });
                                },
                              ),
                              const Text('ważny od'),
                              Radio<String>(
                                value: 'expiry',
                                groupValue: dateRoles[date],
                                onChanged: (val) {
                                  setStateDialog(() {
                                    if (!dateRoles.containsValue('expiry') || dateRoles[date] == 'expiry') {
                                      dateRoles[date] = val!;
                                    }
                                  });
                                },
                              ),
                              const Text('ważny do'),
                            ],
                          ),
                        ],
                      )).toList(),
                    );
                  },
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Anuluj'),
                  ),
                  TextButton(
                    onPressed: () {
                      String? validFrom;
                      String? expiry;
                      dateRoles.forEach((date, role) {
                        if (role == 'validFrom') validFrom = date;
                        if (role == 'expiry') expiry = date;
                      });
                      setState(() {
                        if (validFrom != null) {
                          final idx = lines.indexWhere((l) => l.text.contains(validFrom!));
                          if (idx != -1) _selectedTypes[idx] = 'validFrom';
                          _selectedValidFromDate = _parseDate(validFrom!);
                        }
                        if (expiry != null) {
                          final idx = lines.indexWhere((l) => l.text.contains(expiry!));
                          if (idx != -1) _selectedTypes[idx] = 'expiry';
                          _recognizedExpiryDate = _parseDate(expiry!);
                        }
                      });
                      Navigator.of(context).pop();
                    },
                    child: const Text('Zatwierdź'),
                  ),
                ],
              );
            },
          );
        }
      } else if (foundDates.length > 2) {
        // Wiele dat - przypisz role (od/do) każdej dacie
        Map<String, String> dateRoles = { for (var d in foundDates) d: '' };
        await showDialog<void>(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text('Przypisz rolę każdej dacie'),
              content: StatefulBuilder(
                builder: (context, setStateDialog) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: foundDates.map((date) => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(date),
                        Row(
                          children: [
                            Radio<String>(
                              value: 'validFrom',
                              groupValue: dateRoles[date],
                              onChanged: (val) {
                                setStateDialog(() {
                                  // Zapobiegaj przypisaniu tej samej roli do wielu dat
                                  if (!dateRoles.containsValue('validFrom') || dateRoles[date] == 'validFrom') {
                                    dateRoles[date] = val!;
                                  }
                                });
                              },
                            ),
                            const Text('ważny od'),
                            Radio<String>(
                              value: 'expiry',
                              groupValue: dateRoles[date],
                              onChanged: (val) {
                                setStateDialog(() {
                                  if (!dateRoles.containsValue('expiry') || dateRoles[date] == 'expiry') {
                                    dateRoles[date] = val!;
                                  }
                                });
                              },
                            ),
                            const Text('ważny do'),
                          ],
                        ),
                      ],
                    )).toList(),
                  );
                },
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Anuluj'),
                ),
                TextButton(
                  onPressed: () {
                    // Przypisz daty do pól
                    String? validFrom;
                    String? expiry;
                    dateRoles.forEach((date, role) {
                      if (role == 'validFrom') validFrom = date;
                      if (role == 'expiry') expiry = date;
                    });
                    setState(() {
                      if (validFrom != null) {
                        final idx = lines.indexWhere((l) => l.text.contains(validFrom!));
                        if (idx != -1) _selectedTypes[idx] = 'validFrom';
                        _selectedValidFromDate = _parseDate(validFrom!);
                      }
                      if (expiry != null) {
                        final idx = lines.indexWhere((l) => l.text.contains(expiry!));
                        if (idx != -1) _selectedTypes[idx] = 'expiry';
                        _recognizedExpiryDate = _parseDate(expiry!);
                      }
                    });
                    Navigator.of(context).pop();
                  },
                  child: const Text('Zatwierdź'),
                ),
              ],
            );
          },
        );
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
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: _rotateImage,
                  icon: const Icon(Icons.rotate_right),
                  label: const Text('Obróć 90°'),
                ),
              ],
            ),
            const SizedBox(height: 8),
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
                onPressed: () async {
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
                      if (_recognizedExpiryDate == null) {
                        expiry = lineText;
                      }
                    }
                  });
                  int discountInt = int.tryParse(discount) ?? 0;
                  DateTime? expiryDate;
                  try {
                    if (_recognizedExpiryDate != null) {
                      expiryDate = _recognizedExpiryDate;
                    } else {
                      expiryDate = DateTime.tryParse(expiry);
                    }
                  } catch (_) {
                    expiryDate = null;
                  }

                  // Zapisz zdjęcie do katalogu images i przekaż ścieżkę
                  String? imagePath;
                  try {
                    final appDir = await getApplicationDocumentsDirectory();
                    final imagesDir = Directory('${appDir.path}/images');
                    if (!await imagesDir.exists()) {
                      await imagesDir.create(recursive: true);
                    }
                    final fileName = 'coupon_${DateTime.now().millisecondsSinceEpoch}.jpg';
                    final savedImage = await _image.copy('${imagesDir.path}/$fileName');
                    imagePath = savedImage.path;
                  } catch (e) {
                    imagePath = null;
                  }

                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => AddCouponScreen(
                        coupon: Coupon(
                          code: code,
                          issuer: issuer,
                          discount: discountInt,
                          expiryDate: expiryDate,
                          validFromDate: _selectedValidFromDate,
                          imagePath: imagePath,
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

  DateTime? _parseDate(String input) {
    // yyyy-MM-dd, yyyy/MM/dd, yyyy.MM.dd
    final isoMatch = RegExp(r'^(\d{4})[-/.](\d{2})[-/.](\d{2})$').firstMatch(input);
    if (isoMatch != null) {
      return DateTime.tryParse('${isoMatch.group(1)}-${isoMatch.group(2)}-${isoMatch.group(3)}');
    }
    // dd-MM-yyyy, dd/MM/yyyy, dd.MM.yyyy
    final euroMatch = RegExp(r'^(\d{2})[-/.](\d{2})[-/.](\d{4})$').firstMatch(input);
    if (euroMatch != null) {
      final day = int.tryParse(euroMatch.group(1)!);
      final month = int.tryParse(euroMatch.group(2)!);
      final year = int.tryParse(euroMatch.group(3)!);
      if (day != null && month != null && year != null) {
        return DateTime(year, month, day);
      }
    }
    return null;
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
