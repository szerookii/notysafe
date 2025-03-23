import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:notysafe/components/about_app_dialog.dart';
import 'package:notysafe/components/note_card.dart';
import 'package:notysafe/components/note_searchbar.dart';
import 'package:notysafe/db/database.dart';
import 'package:notysafe/db/types.dart';
import 'package:notysafe/views/view_note.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:easy_localization/easy_localization.dart';

class NotesPage extends StatefulWidget {
  final Function toggleTheme;

  const NotesPage({super.key, required this.toggleTheme});

  @override
  State<NotesPage> createState() => _NotesPageState();
}

class _NotesPageState extends State<NotesPage> {
  PackageInfo _packageInfo = PackageInfo(
    appName: '',
    packageName: '',
    version: '',
    buildNumber: '',
  );

  List<Note> _notes = [];
  bool _isLoading = true;
  String _searchText = '';

  @override
  void initState() {
    super.initState();
    _initPackageInfo();
    _loadNotes();
  }

  Future<void> _initPackageInfo() async {
    final packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      _packageInfo = packageInfo;
    });
  }

  Future<void> _loadNotes() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final dbHelper = DatabaseHelper();
      final notes = await dbHelper.getNotes();

      setState(() {
        _notes = notes;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('error.cannot_load_notes'))),
      );
    }
  }

  List<Note> get _filteredNotes {
    final filtered =
        _notes
            .where(
              (note) =>
                  note.title.toLowerCase().contains(
                    _searchText.toLowerCase(),
                  ) ||
                  note.content.toLowerCase().contains(
                    _searchText.toLowerCase(),
                  ),
            )
            .toList();

    filtered.sort((a, b) => b.date.compareTo(a.date));

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        scrolledUnderElevation: 0,
        title: Text(context.tr('notes_view.appbar_title')),
        titleTextStyle: TextStyle(
          color: Theme.of(context).colorScheme.onSurface,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: Icon(
              Theme.of(context).brightness == Brightness.dark
                  ? Icons.light_mode
                  : Icons.dark_mode,
            ),
            onPressed: () {
              widget.toggleTheme();
            },
            tooltip: context.tr('tooltip.toggle_theme'),
          ),
          _buildPopupMenu(context),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.only(bottom: 12, left: 12, right: 12),
        child: Column(
          children: [
            CustomSearchBar(
              onChanged: (value) {
                setState(() {
                  _searchText = value;
                });
              },
            ),
            Expanded(
              child:
                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _filteredNotes.isEmpty
                      ? Center(
                        child: Text(context.tr('notes_view.no_notes')),
                      )
                      : MasonryGridView.count(
                        crossAxisCount: 2,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        itemCount: _filteredNotes.length,
                        itemBuilder: (context, index) {
                          return NoteCard(
                            note: _filteredNotes[index],
                            onNoteUpdated: (context) {
                              _loadNotes();
                            },
                          );
                        },
                      ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final dbHelper = DatabaseHelper();
          final nextId = await dbHelper.nextNoteId();
          final note = Note(
            id: nextId,
            content: "",
            date: DateTime.now().toString(),
            isEncrypted: false,
            title: "",
          );
          await dbHelper.insertNote(note);

          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) => ViewNotePage(
                    note: note,
                    onNoteUpdated: (context) {
                      _loadNotes();
                    },
                  ),
            ),
          );
        },
        shape: const CircleBorder(),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildPopupMenu(BuildContext context) {
    return PopupMenuButton<String>(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      icon: const Icon(Icons.more_vert),
      onSelected: (value) {
        switch (value) {
          case 'settings':
            break;
          case 'about':
            showDialog(
              context: context,
              builder: (context) => AboutAppDialog(packageInfo: _packageInfo),
            );
            break;
        }
      },
      itemBuilder:
          (context) => [
            PopupMenuItem<String>(
              value: 'settings',
              child: Row(
                children: [
                  Icon(Icons.settings),
                  SizedBox(width: 8),
                  Text(context.tr('notes_view.settings')),
                ],
              ),
            ),
            PopupMenuItem<String>(
              value: 'about',
              child: Row(
                children: [
                  Icon(Icons.info_outline),
                  SizedBox(width: 8),
                  Text(context.tr('notes_view.about')),
                ],
              ),
            ),
          ],
    );
  }

  @override
  void dispose() {
    DatabaseHelper().close();
    super.dispose();
  }
}
