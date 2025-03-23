import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:notysafe/db/database.dart';
import 'package:notysafe/db/types.dart';
import 'package:local_auth/local_auth.dart';
import 'package:notysafe/utils/encryption.dart';

class ViewNotePage extends StatefulWidget {
  final Note note;
  final Function(Note) onNoteUpdated;

  const ViewNotePage({
    super.key,
    required this.note,
    required this.onNoteUpdated,
  });

  @override
  State<ViewNotePage> createState() => _ViewNotePageState();
}

class _ViewNotePageState extends State<ViewNotePage> {
  final QuillController _contentController = () {
    return QuillController.basic();
  }();
  late TextEditingController _titleController;
  bool _isContentChanged = false;
  bool _isSaving = false;
  final LocalAuthentication _localAuth = LocalAuthentication();
  late bool _isNoteEncrypted;
  bool _isContentLoaded = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.note.title);
    _isNoteEncrypted = widget.note.isEncrypted;

    if (_isNoteEncrypted) {
      _authenticateAndLoadContent();
    } else {
      _loadContent();
    }

    _contentController.addListener(_onContentChanged);
    _titleController.addListener(_onContentChanged);
  }

  Future<void> _authenticateAndLoadContent() async {
    setState(() {
      _isLoading = true;
    });

    bool canAuthenticate =
        await _localAuth.canCheckBiometrics &&
        await _localAuth.isDeviceSupported();

    if (!canAuthenticate) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Biometric authentication not supported on this device',
            ),
          ),
        );
        Navigator.of(context).pop();
      }
      return;
    }

    try {
      bool didAuthenticate = await _localAuth.authenticate(
        localizedReason: 'Authenticate to view encrypted note',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
          sensitiveTransaction: true,
        ),
      );

      if (!didAuthenticate) {
        if (mounted) {
          Navigator.of(context).pop();
        }
        return;
      }

      if (mounted) {
        _loadContent();
      }
    } catch (e) {
      debugPrint('Error authenticating: $e');
      if (mounted) {
        Navigator.of(context).pop();
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _loadContent() async {
    String content = widget.note.content;

    if (widget.note.isEncrypted) {
      try {
        content = await EncryptionHelper.decrypt(
          content,
          'note_${widget.note.id}',
        );
      } catch (e) {
        debugPrint('Error decrypting note content: $e');
        content += '\n';
      }
    }

    try {
      _contentController.document = Document.fromJson(jsonDecode(content));
    } catch (e) {
      debugPrint('Error loading note content: $e');
      content += '\n';
      _contentController.document = Document.fromJson([
        {"insert": content},
      ]);
    }

    setState(() {
      _isContentLoaded = true;
    });
  }

  void _onContentChanged() {
    if (!mounted) return;

    if (!_isContentChanged) {
      setState(() {
        _isContentChanged = true;
      });
    }
  }

  Future<void> _toggleEncryption() async {
    bool canAuthenticate =
        await _localAuth.canCheckBiometrics &&
        await _localAuth.isDeviceSupported();

    if (!canAuthenticate) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Biometric authentication not supported on this device',
            ),
          ),
        );
      }
      return;
    }

    if (!_isNoteEncrypted) {
      var didAuthenticate = false;
      try {
        didAuthenticate = await _localAuth.authenticate(
          localizedReason: 'Authenticate to encrypt this note',
          options: const AuthenticationOptions(
            biometricOnly: true,
            stickyAuth: true,
            sensitiveTransaction: true,
          ),
        );
      } catch (e) {
        debugPrint('Error authenticating: $e');
      }

      if (!didAuthenticate) {
        // TODO: check if failed
        return;
      }
    }

    if (mounted) {
      setState(() {
        _isNoteEncrypted = !_isNoteEncrypted;
        _isContentChanged = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isNoteEncrypted
                ? 'Note encryption enabled'
                : 'Note encryption disabled',
          ),
        ),
      );
    }
  }

  Note _createUpdatedNote() {
    final plainText = _contentController.document.toDelta().toJson();
    return Note(
      id: widget.note.id,
      title: _titleController.text.isEmpty ? 'Untitled' : _titleController.text,
      content: jsonEncode(plainText),
      date: DateTime.now().toString(),
      isEncrypted: _isNoteEncrypted,
    );
  }

  Future<void> _saveNote() async {
    if (!_isContentChanged &&
        widget.note.title == _titleController.text &&
        _isNoteEncrypted == widget.note.isEncrypted) {
      return;
    }

    if (!mounted) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final updatedNote = _createUpdatedNote();
      final dbHelper = DatabaseHelper();
      await dbHelper.updateNote(updatedNote);

      if (mounted) {
        widget.onNoteUpdated(updatedNote);

        setState(() {
          _isContentChanged = false;
          _isSaving = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Note saved'),
            duration: Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error saving note: $e')));
      }
    }
  }

  void _saveNoteSynchronously() {
    try {
      final updatedNote = _createUpdatedNote();
      final dbHelper = DatabaseHelper();
      dbHelper.updateNoteSync(updatedNote);
      widget.onNoteUpdated(updatedNote);
    } catch (e) {
      debugPrint('Error saving note during cleanup: $e');
    }
  }

  Future<bool> _onWillPopWithResult(bool didPop, result) async {
    if (_isContentChanged && mounted) {
      await _saveNote();
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    const double toolbarHeight = 50.0;

    return PopScope(
      onPopInvokedWithResult: _onWillPopWithResult,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.surface,
          scrolledUnderElevation: 0,
          title: TextField(
            controller: _titleController,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            decoration: const InputDecoration(
              border: InputBorder.none,
              hintText: 'Note title',
            ),
          ),
          actions: [
            Tooltip(
              message:
                  _isNoteEncrypted ? 'Disable encryption' : 'Enable encryption',
              child: IconButton(
                icon: Icon(
                  _isNoteEncrypted ? Icons.lock : Icons.lock_open,
                  color:
                      _isNoteEncrypted
                          ? Theme.of(context).colorScheme.primary
                          : null,
                ),
                onPressed: _toggleEncryption,
              ),
            ),
          ],
        ),
        body:
            _isSaving || _isLoading
                ? const Center(child: CircularProgressIndicator())
                : !_isContentLoaded && _isNoteEncrypted
                ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.lock, size: 48),
                      const SizedBox(height: 16),
                      const Text('This note is encrypted'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _authenticateAndLoadContent,
                        child: const Text('Authenticate to view'),
                      ),
                    ],
                  ),
                )
                : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).colorScheme.surfaceVariant.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            children: [
                              Expanded(
                                child: QuillEditor.basic(
                                  controller: _contentController,
                                  config: QuillEditorConfig(
                                    padding: const EdgeInsets.all(16),
                                    scrollable: true,
                                    autoFocus: false,
                                    showCursor: true,
                                    expands: true,
                                    scrollBottomInset: toolbarHeight,
                                    scrollPhysics:
                                        const ClampingScrollPhysics(),
                                  ),
                                ),
                              ),
                              Container(
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.surface,
                                  borderRadius: const BorderRadius.only(
                                    bottomLeft: Radius.circular(8),
                                    bottomRight: Radius.circular(8),
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 4,
                                      offset: const Offset(0, -1),
                                    ),
                                  ],
                                ),
                                child: QuillSimpleToolbar(
                                  controller: _contentController,
                                  config: QuillSimpleToolbarConfig(
                                    axis: Axis.horizontal,
                                    showClearFormat: false,
                                    headerStyleType: HeaderStyleType.buttons,
                                    showClipboardCopy: false,
                                    showClipboardCut: false,
                                    showRedo: false,
                                    showUndo: false,
                                    showFontFamily: false,
                                    showClipboardPaste: false,
                                    showBackgroundColorButton: false,
                                    showHeaderStyle: false,
                                    showSearchButton: false,
                                    showCodeBlock: false,
                                    showInlineCode: false,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
      ),
    );
  }

  @override
  void deactivate() {
    if (_isContentChanged && mounted) {
      _saveNoteSynchronously();
      _isContentChanged = false;
    }
    super.deactivate();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }
}
