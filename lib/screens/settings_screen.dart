import 'package:flutter/material.dart';
import 'package:rabacik/data/notification_helper.dart';
import 'package:rabacik/data/orc_helper.dart';
import 'package:rabacik/data/rectangle_settings.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool showDetectedRectangles = RectangleSettings.showDetectedRectangles;
  bool pushNotificationsEnabled = NotificationHelper.notificationsEnabled;
  int notifyBeforeDays = NotificationHelper.notifyBeforeDays;
  int ocrMaxLength = OCRSettings.maxLength;
  double ocrMinFontHeight = OCRSettings.minFontHeight;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ustawienia'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SwitchListTile(
              title: const Text('Powiadomienia push'),
              value: pushNotificationsEnabled,
              onChanged: (value) {
                setState(() {
                  pushNotificationsEnabled = value;
                  NotificationHelper.notificationsEnabled = value;
                });
              },
            ),
            SwitchListTile(
              title: const Text('Otaczaj wykryte teksty prostokątami'),
              value: showDetectedRectangles,
              onChanged: (value) {
                setState(() {
                  showDetectedRectangles = value;
                  RectangleSettings.showDetectedRectangles = value;
                });
              },
            ),
            const SizedBox(height: 24),
            Text('Powiadom mnie przed końcem kuponu:', style: Theme.of(context).textTheme.titleMedium),
            Row(
              children: [
                Expanded(
                  child: Slider(
                    value: notifyBeforeDays.toDouble(),
                    min: 1,
                    max: 14,
                    divisions: 13,
                    label: '$notifyBeforeDays dni',
                    onChanged: (value) {
                      setState(() {
                        notifyBeforeDays = value.round();
                        NotificationHelper.notifyBeforeDays = notifyBeforeDays;
                      });
                    },
                  ),
                ),
                SizedBox(width: 8),
                Text('$notifyBeforeDays dni'),
              ],
            ),
            const SizedBox(height: 24),
            Text('Filtracja OCR:', style: Theme.of(context).textTheme.titleMedium),
            Row(
              children: [
                Expanded(
                  child: Slider(
                    value: ocrMaxLength.toDouble(),
                    min: 10,
                    max: 100,
                    divisions: 18,
                    label: '$ocrMaxLength znaków',
                    onChanged: (value) {
                      setState(() {
                        ocrMaxLength = value.round();
                        OCRSettings.maxLength = ocrMaxLength;
                      });
                    },
                  ),
                ),
                SizedBox(width: 8),
                Text('$ocrMaxLength znaków'),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: Slider(
                    value: ocrMinFontHeight,
                    min: 10.0,
                    max: 40.0,
                    divisions: 30,
                    label: '${ocrMinFontHeight.toStringAsFixed(1)} px',
                    onChanged: (value) {
                      setState(() {
                        ocrMinFontHeight = value;
                        OCRSettings.minFontHeight = ocrMinFontHeight;
                      });
                    },
                  ),
                ),
                SizedBox(width: 8),
                Text('${ocrMinFontHeight.toStringAsFixed(1)} px'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
