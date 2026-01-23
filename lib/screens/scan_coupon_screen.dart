import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';

class ScanCouponScreen extends StatefulWidget {
  const ScanCouponScreen({super.key});

  @override
  State<ScanCouponScreen> createState() => _ScanCouponScreenState();
}

class _ScanCouponScreenState extends State<ScanCouponScreen> {
  File? _image;
  List<String> _recognizedLines = [];
  bool _isLoading = false;
  int? _selectedCodeIdx;
  int? _selectedIssuerIdx;
  int? _selectedDateIdx;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.camera);
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
    setState(() {
      _recognizedLines = recognizedText.blocks.expand((b) => b.lines.map((l) => l.text)).toList();
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Skanuj kupon (OCR)'),),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            if (_image != null)
              Image.file(_image!, height: 200),
            ElevatedButton(
              onPressed: _pickImage,
              child: const Text('Zrób zdjęcie kuponu'),
            ),
            if (_isLoading) const CircularProgressIndicator(),
            if (_recognizedLines.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text('Wskaż rozpoznane dane:', style: TextStyle(fontWeight: FontWeight.bold)),
              Expanded(
                child: ListView.builder(
                  itemCount: _recognizedLines.length,
                  itemBuilder: (context, index) => Card(
                    color: _selectedCodeIdx == index
                            ? Colors.green[100]
                            : _selectedIssuerIdx == index
                                ? Colors.blue[100]
                                : _selectedDateIdx == index
                                    ? Colors.orange[100]
                                    : null,
                    child: ListTile(
                      title: Text(_recognizedLines[index]),
                      subtitle: Row(
                        children: [
                          ChoiceChip(
                            label: const Text('Kod kuponu'),
                            selected: _selectedCodeIdx == index,
                            onSelected: (selected) {
                              setState(() {
                                _selectedCodeIdx = selected ? index : null;
                              });
                            },
                          ),
                          const SizedBox(width: 8),
                          ChoiceChip(
                            label: const Text('Gdzie działa'),
                            selected: _selectedIssuerIdx == index,
                            onSelected: (selected) {
                              setState(() {
                                _selectedIssuerIdx = selected ? index : null;
                              });
                            },
                          ),
                          const SizedBox(width: 8),
                          ChoiceChip(
                            label: const Text('Data ważności'),
                            selected: _selectedDateIdx == index,
                            onSelected: (selected) {
                              setState(() {
                                _selectedDateIdx = selected ? index : null;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: (_selectedCodeIdx != null && _selectedIssuerIdx != null && _selectedDateIdx != null)
                    ? () {
                        Navigator.of(context).pop({
                          'code': _recognizedLines[_selectedCodeIdx!],
                          'issuer': _recognizedLines[_selectedIssuerIdx!],
                          'expiry': _recognizedLines[_selectedDateIdx!],
                        });
                      }
                    : null,
                child: const Text('Zatwierdź wybór'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
