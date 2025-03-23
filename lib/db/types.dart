class Note {
  final int id;
  final String title;
  final String content;
  final bool isEncrypted;
  final String date;

  Note({
    required this.id,
    required this.title,
    required this.content,
    required this.isEncrypted,
    required this.date,
  });
}