import 'package:flutter/cupertino.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoApp(
      title: 'NotySafe',
      theme: CupertinoThemeData(
        brightness: Brightness.light,
        primaryColor: CupertinoColors.systemBlue,
        scaffoldBackgroundColor: CupertinoColors.systemBackground,
        textTheme: CupertinoTextThemeData(
          navTitleTextStyle: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: CupertinoColors.label,
          ),
          textStyle: TextStyle(
            fontSize: 17,
            color: CupertinoColors.label,
          ),
        ),
      ),
      home: const NotesPage(),
    );
  }
}

class NotesPage extends StatefulWidget {
  const NotesPage({super.key});

  @override
  State<NotesPage> createState() => _NotesPageState();
}

class _NotesPageState extends State<NotesPage> {
  // Simuler une liste de notes
  final List<NoteItem> _notes = [
    NoteItem(
      title: 'Courses à faire',
      content: 'Acheter du lait, des œufs et du pain',
      date: '22 mars 2025',
    ),
    NoteItem(
      title: 'Idées de projet',
      content: 'Application de suivi de tâches avec IA',
      date: '21 mars 2025',
    ),
    NoteItem(
      title: 'Rappels',
      content: 'Appeler le médecin pour prendre rendez-vous',
      date: '20 mars 2025',
    ),
    NoteItem(
      title: 'Citations',
      content: 'La simplicité est la sophistication suprême. "La simplicité est la sophistication suprême" est une citation attribuée à Leonardo da Vinci, qui exprime l\'idée que la vraie élégance et l\'excellence se trouvent souvent dans les solutions les plus simples et épurées. Cette philosophie suggère que le processus de simplification, qui requiert une compréhension profonde du problème, est une forme supérieure de sophistication intellectuelle et créative.',
      date: '19 mars 2025',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('Mes Notes'),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Icon(CupertinoIcons.search),
          onPressed: () {
            // Fonction de recherche (non implémentée)
          },
        ),
      ),
      child: Stack(
        children: [
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: MasonryGridView.count(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                itemCount: _notes.length,
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () {
                      // Ouvrir la note (non implémenté)
                    },
                    child: Container(
                      constraints: BoxConstraints(
                        minHeight: 120, // Hauteur minimale pour les petites notes
                      ),
                      decoration: BoxDecoration(
                        color: CupertinoColors.systemBackground,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: CupertinoColors.systemGrey.withOpacity(0.2),
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          ),
                        ],
                        border: Border.all(
                          color: CupertinoColors.systemGrey4,
                          width: 1,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _notes[index].title,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 17,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _notes[index].date,
                              style: TextStyle(
                                fontSize: 13,
                                color: CupertinoColors.systemGrey,
                              ),
                            ),
                            const SizedBox(height: 8),
                            // Conteneur de texte avec un effet de fondu
                            _buildTextWithFade(_notes[index].content),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          Positioned(
            right: 16.0,
            bottom: 16.0,
            child: CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: () {
                // Créer une nouvelle note (non implémenté)
              },
              child: Container(
                width: 56.0,
                height: 56.0,
                decoration: BoxDecoration(
                  color: CupertinoTheme.of(context).primaryColor,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  CupertinoIcons.add,
                  color: CupertinoColors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Méthode pour gérer l'effet de fondu sur le texte
  Widget _buildTextWithFade(String content) {
    final int maxLines = 5;
    final textStyle = const TextStyle(fontSize: 15);

    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculer si le texte est réellement tronqué
        final TextSpan textSpan = TextSpan(
          text: content,
          style: textStyle,
        );
        final TextPainter textPainter = TextPainter(
          text: textSpan,
          textDirection: TextDirection.ltr,
          maxLines: maxLines,
        );
        textPainter.layout(maxWidth: constraints.maxWidth);
        
        // Vérifier si le texte est réellement tronqué
        final bool isTextTruncated = textPainter.didExceedMaxLines;

        return Stack(
          children: [
            Text(
              content,
              style: textStyle,
              maxLines: maxLines,
              overflow: TextOverflow.ellipsis,
            ),
            if (isTextTruncated)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: 20,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        CupertinoColors.systemBackground.withOpacity(0.0),
                        CupertinoColors.systemBackground,
                      ],
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

// Classe simple pour représenter une note
class NoteItem {
  final String title;
  final String content;
  final String date;

  NoteItem({
    required this.title, 
    required this.content, 
    required this.date
  });
}
