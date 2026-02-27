import 'package:flutter/material.dart';
import 'package:rabacik/data/notification_helper.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool pushNotificationsEnabled = NotificationHelper.notificationsEnabled;
  int notifyBeforeDays = NotificationHelper.notifyBeforeDays;

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
          ],
        ),
      ),
    );
  }
}
