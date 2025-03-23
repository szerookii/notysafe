import 'dart:convert';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:notysafe/db/database.dart';
import 'package:notysafe/db/types.dart';
import 'package:notysafe/utils/biometrics.dart';
import 'package:notysafe/utils/time.dart';
import 'package:notysafe/views/view_note.dart';

class NoteCard extends StatelessWidget {
  final Note note;
  final Function(Note) onNoteUpdated;

  const NoteCard({super.key, required this.note, required this.onNoteUpdated});

  @override
  Widget build(BuildContext context) {
    Widget contentWidget;

    if (note.isEncrypted) {
      contentWidget = Container(
        height: 60,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(8)),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned.fill(
                child: ListView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  physics: const NeverScrollableScrollPhysics(),
                  children: List.generate(
                    5,
                    (index) => Container(
                      margin: const EdgeInsets.symmetric(vertical: 3),
                      height: 8,
                      decoration: BoxDecoration(
                        color: Colors.grey[400],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      width: double.infinity,
                    ),
                  ),
                ),
              ),

              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                  child: Container(
                    color: Colors.white.withOpacity(0.1),
                    width: double.infinity,
                    height: double.infinity,
                  ),
                ),
              ),
              const Icon(Icons.lock_rounded, size: 28, color: Colors.white),
            ],
          ),
        ),
      );
    } else {
      var content = note.content;
      try {
        content = Document.fromJson(jsonDecode(content)).toPlainText();
      } catch (e) {
        // Do nothing
      }

      contentWidget = Text(
        content,
        style: TextStyle(fontSize: 15, color: Colors.grey[500]),
        maxLines: 5,
        overflow: TextOverflow.ellipsis,
      );
    }

    return GestureDetector(
      onLongPress: () => {_showContextMenu(context)},
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) =>
                    ViewNotePage(note: note, onNoteUpdated: onNoteUpdated),
          ),
        );
      },
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Container(
          constraints: const BoxConstraints(minHeight: 80),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  note.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                contentWidget,
                const SizedBox(height: 4),
                Text(
                  formatDate(note.date),
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showContextMenu(BuildContext context) {
    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final position = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;

    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy,
        position.dx + size.width,
        position.dy + size.height,
      ),
      items: [
        PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete, color: Theme.of(context).colorScheme.error),
              const SizedBox(width: 8),
              Text(
                'Delete',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
          ),
        ),
      ],
    ).then((value) async {
      if (value == 'delete') {
        bool canProceed = true;

        if (note.isEncrypted) {
          canProceed = await BiometricsUtil.authenticate(
            context,
            'Authenticate to delete note',
          );

          if (!canProceed) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Authentication required to delete note'),
              ),
            );
            return;
          }
        }

        if (canProceed) {
          final confirm = await showDialog<bool>(
            context: context,
            builder:
                (context) => AlertDialog(
                  title: const Text('Confirm deletion'),
                  content: const Text(
                    'Are you sure you want to delete this note?',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: Text(
                        'Delete',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),
                  ],
                ),
          );

          if (confirm == true) {
            final dbHelper = DatabaseHelper();
            await dbHelper.deleteNote(note.id);
            onNoteUpdated(note);

            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('Note deleted')));
          }
        }
      }
    });
  }
}
