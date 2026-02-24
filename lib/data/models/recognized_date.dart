class RecognizedDate {
  final String originalText; // Oryginalny tekst daty z OCR
  final DateTime dateTime;   // Sparsowana data jako DateTime
  final bool isShortFormat; // Czy data była w formacie bez roku (np. "12.05")

  RecognizedDate({required this.originalText, required this.dateTime, required this.isShortFormat});
}