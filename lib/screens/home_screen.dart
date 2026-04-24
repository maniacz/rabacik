import 'package:flutter/material.dart';
import 'package:rabacik/widgets/action_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text("KuponMate"),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {},
          )
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: Colors.green,
        child: const Icon(Icons.add),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            _summaryCard(),
            const SizedBox(height: 12),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                children: const [
                  ActionCard(
                    icon: Icons.add,
                    title: "Dodaj kupon",
                    subtitle: "Dodaj ręcznie nowe rabaty",
                    buttonText: "Dodaj",
                  ),
                  ActionCard(
                    icon: Icons.folder,
                    title: "Moje kupony",
                    subtitle: "Przeglądaj i zarządzaj",
                    buttonText: "Otwórz",
                  ),
                  ActionCard(
                    icon: Icons.camera_alt,
                    title: "Skanuj kupon",
                    subtitle: "Użyj aparatu",
                    buttonText: "Skanuj",
                  ),
                  ActionCard(
                    icon: Icons.image,
                    title: "Z galerii",
                    subtitle: "Wybierz zdjęcie",
                    buttonText: "Wybierz",
                  ),
                ],
              ),
            ),
            _tipBox(),
          ],
        ),
      ),
    );
  }

  Widget _summaryCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            children: const [
              Text("Wszystkie kupony"),
              Text("34", style: TextStyle(fontSize: 22)),
            ],
          ),
          Column(
            children: const [
              Text("Wygasające"),
              CircleAvatar(
                radius: 12,
                backgroundColor: Colors.orange,
                child: Text("3", style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _tipBox() {
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Text(
        "Dotknij 'Dodaj kupon', aby szybko dodać pierwszy kupon.",
      ),
    );
  }
}