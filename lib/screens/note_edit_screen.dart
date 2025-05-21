import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_quill_extensions/flutter_quill_extensions.dart';
import '../models/note.dart';
import '../models/tag.dart';
import '../models/folder.dart';
import '../services/database_service.dart';
import '../services/home_updater.dart';

class NoteEditScreen extends StatefulWidget {
  final int? noteId;
  final int? tagFilterId; // Optional tag filter to apply when saving
  final bool startInEditMode; // New parameter to control initial mode
  final int? initialFolderId; // Initial folder ID

  const NoteEditScreen({
    super.key, 
    this.noteId, 
    this.tagFilterId,
    this.startInEditMode = false, // Default to view mode for existing notes
    this.initialFolderId,
  });

  @override
  State<NoteEditScreen> createState() => _NoteEditScreenState();
}

class _NoteEditScreenState extends State<NoteEditScreen> {
  late TextEditingController _titleController;
  late QuillController _quillController;
  
  bool _isLoading = false;
  bool _isEditing = false;
  bool _isInEditMode = false; // Track if we're in edit mode or view mode
  Note? _originalNote;
  FocusNode _editorFocusNode = FocusNode();
  bool _editorInitialized = false;

  // Folder related state
  int? _selectedFolderId;
  Folder? _selectedFolder;
  List<Folder> _availableFolders = [];

  // Tags related state
  List<Tag> _noteTags = [];
  final TextEditingController _tagController = TextEditingController();
  final FocusNode _tagFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    
    // Create a default empty document for new notes
    _quillController = QuillController.basic();
    _quillController.readOnly = false; // Make sure editor is editable
    _editorInitialized = true;
    
    _isEditing = widget.noteId != null;
    _isInEditMode = !_isEditing || widget.startInEditMode; // New notes always start in edit mode
    
    // Set initial folder ID if provided
    _selectedFolderId = widget.initialFolderId;
    
    // Load folders
    _loadFolders();
    
    if (_isEditing) {
      _loadNote();
    }
  }

  // Load all available folders
  Future<void> _loadFolders() async {
    try {
      final folders = await DatabaseService().getAllFolders();
      setState(() {
        _availableFolders = folders;
        
        // Update selected folder name if we have a folder ID
        if (_selectedFolderId != null) {
          _selectedFolder = folders.firstWhere(
            (folder) => folder.id == _selectedFolderId,
            orElse: () => Folder(name: 'Unknown Folder')
          );
        }
      });
    } catch (e) {
      print('Error loading folders: $e');
    }
  }

  // Load an existing note
  Future<void> _loadNote() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final note = await DatabaseService().getNoteById(widget.noteId!);
      if (note != null) {
        setState(() {
          _originalNote = note;
          _titleController.text = note.title;
          
          // Initialize the editor with the note's content
          if (_editorInitialized) {
            _quillController.dispose();
          }
          
          // Convert stored content to Quill document
          _quillController = note.quillController;
          _quillController.readOnly = !_isInEditMode; // Read-only in view mode
          _editorInitialized = true;
        });

        // Load folder ID for the note
        final folderId = await DatabaseService().getNoteFolderId(widget.noteId!);
        if (folderId != null) {
          final folder = await DatabaseService().getFolderById(folderId);
          setState(() {
            _selectedFolderId = folderId;
            _selectedFolder = folder;
          });
        }

        // Load tags for the note
        await _loadTags();
        
        setState(() {
          _isLoading = false;
        });
      } else {
        // Note not found
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Note not found')),
          );
          Navigator.pop(context);
        }
      }
    } catch (e) {
      print('Error loading note: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading note: $e')),
        );
        Navigator.pop(context);
      }
    }
  }

  // Load tags for the current note
  Future<void> _loadTags() async {
    if (!_isEditing || _originalNote == null || _originalNote?.id == null) return;
    
    try {
      final tags = await DatabaseService().getTagsForNote(_originalNote!.id!);
      setState(() {
        _noteTags = tags;
      });
    } catch (e) {
      print('Error loading tags: $e');
    }
  }

  // Toggle between view and edit modes
  void _toggleEditMode() {
    setState(() {
      _isInEditMode = !_isInEditMode;
      _quillController.readOnly = !_isInEditMode;
    });
  }

  // Add a tag to the current note
  Future<void> _addTag(String tagName) async {
    if (tagName.trim().isEmpty) return;
    
    try {
      // First check if this tag already exists for this note
      if (_noteTags.any((tag) => tag.name.toLowerCase() == tagName.trim().toLowerCase())) {
        _tagController.clear();
        return; // Tag already exists for this note
      }
      
      // Create or get tag
      final tagId = await DatabaseService().createTag(tagName.trim());
      
      // Get the tag details
      final tag = await DatabaseService().getTagByName(tagName.trim());
      
      if (tag != null) {
        // If we're editing an existing note
        if (_isEditing && _originalNote != null && _originalNote?.id != null) {
          // Add tag to note in database
          await DatabaseService().addTagToNote(_originalNote!.id!, tag.id!);
        }
        
        // Add tag to local list
        setState(() {
          _noteTags.add(tag);
          _tagController.clear();
        });
      }
    } catch (e) {
      print('Error adding tag: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding tag: $e')),
        );
      }
    }
  }

  // Remove a tag from the current note
  Future<void> _removeTag(Tag tag) async {
    try {
      // If we're editing an existing note
      if (_isEditing && _originalNote != null && _originalNote?.id != null && tag.id != null) {
        // Remove tag from note in database
        await DatabaseService().removeTagFromNote(_originalNote!.id!, tag.id!);
      }
      
      // Remove tag from local list
      setState(() {
        _noteTags.removeWhere((t) => t.id == tag.id);
      });
    } catch (e) {
      print('Error removing tag: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error removing tag: $e')),
        );
      }
    }
  }

  // Save the current note
  Future<void> _saveNote() async {
    // Don't save if both title and content are empty
    final contentText = _quillController.document.toPlainText().trim();
    if (_titleController.text.trim().isEmpty && contentText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot save empty note')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final now = DateTime.now();
      // Convert quill content to JSON string for storage
      final contentJson = Note.quillControllerToJson(_quillController);
      
      int? noteId;
      
      if (_isEditing && _originalNote != null) {
        // Update existing note
        final updatedNote = Note(
          id: _originalNote!.id,
          title: _titleController.text.trim(),
          content: contentJson,
          timestamp: now,
          isDeleted: 0,
          isStarred: _originalNote!.isStarred, // Preserve star status
        );
        
        await DatabaseService().updateNote(updatedNote, folderId: _selectedFolderId);
        noteId = _originalNote!.id;
      } else {
        // Create new note
        final newNote = Note(
          title: _titleController.text.trim(),
          content: contentJson,
          timestamp: now,
          isDeleted: 0,
          isStarred: 0, // New notes are not starred by default
        );
        
        noteId = await DatabaseService().createNote(newNote, folderId: _selectedFolderId);
      }
      
      // Save tags for the note
      if (noteId != null) {
        if (_isEditing) {
          // For existing notes, we first remove all tags then add the current ones
          await DatabaseService().removeAllTagsFromNote(noteId);
        }
        
        // Add all current tags
        for (var tag in _noteTags) {
          if (tag.id != null) {
            await DatabaseService().addTagToNote(noteId, tag.id!);
          }
        }

        // If there was a tag filter applied, make sure that tag is associated with this note
        if (widget.tagFilterId != null) {
          await DatabaseService().addTagToNote(noteId, widget.tagFilterId!);
        }
      }
      
      // Notify HomeScreen to refresh
      final HomeUpdater? homeUpdater = HomeUpdater.instance;
      if (homeUpdater != null) {
        homeUpdater.notifyHomeToRefresh();
      }
      
      // Return to the previous screen
      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print('Error saving note: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving note: $e')),
        );
      }
    }
  }

  // Show folder selection dialog
  Future<void> _showFolderSelectionDialog() async {
    final selectedFolder = await showDialog<Folder?>(
      context: context,
      builder: (context) => FolderSelectionDialog(
        folders: _availableFolders,
        selectedFolderId: _selectedFolderId,
      ),
    );
    
    if (selectedFolder != null) {
      setState(() {
        _selectedFolderId = selectedFolder.id;
        _selectedFolder = selectedFolder;
      });
    }
  }

  // Move the current note to recycle bin
  Future<void> _moveToRecycleBin() async {
    if (!_isEditing || _originalNote == null) return;
    
    // Show confirmation dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Move to Recycle Bin'),
        content: const Text('Are you sure you want to move this note to the recycle bin?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('MOVE'),
          ),
        ],
      ),
    );
    
    if (confirm != true) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      await DatabaseService().moveNoteToRecycleBin(_originalNote!.id!);
      
      // Notify HomeScreen that data has changed
      final HomeUpdater? homeUpdater = HomeUpdater.instance;
      if (homeUpdater != null) {
        homeUpdater.notifyHomeToRefresh();
      }
      
      // Return to the previous screen
      if (mounted) {
        Navigator.pop(context, true);
        
        // Show snackbar on the home screen
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Note moved to recycle bin'),
            action: SnackBarAction(
              label: 'UNDO',
              onPressed: () async {
                // Restore note
                await DatabaseService().restoreNoteFromRecycleBin(_originalNote!.id!);
                
                // Notify HomeScreen to refresh its data
                final updater = HomeUpdater.instance;
                if (updater != null) {
                  updater.notifyHomeToRefresh();
                }
              },
            ),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print('Error moving note to recycle bin: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error moving note to recycle bin: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _quillController.dispose();
    _editorFocusNode.dispose();
    _tagController.dispose();
    _tagFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: SingleChildScrollView(
            child: Text(_isEditing ? (_isInEditMode ? 'Edit Note' : 'View Note') : 'New Note')),
        actions: [
          // Star/Favorite button (always visible when viewing or editing an existing note)
          if (_isEditing && !_isLoading)
            IconButton(
              icon: Icon(
                _originalNote?.isStarredBool == true ? Icons.star : Icons.star_border,
                color: _originalNote?.isStarredBool == true ? Colors.amber : null,
              ),
              onPressed: () {
                if (_originalNote != null && _originalNote!.id != null) {
                  setState(() {
                    // Toggle starred status
                    _originalNote = _originalNote!.copyWith(
                      isStarred: _originalNote!.isStarredBool ? 0 : 1
                    );
                  });
                  
                  // Update in database
                  DatabaseService().updateNoteStarredStatus(
                    _originalNote!.id!, 
                    _originalNote!.isStarredBool
                  ).then((_) {
                    // Notify home screen to refresh if needed
                    final homeUpdater = HomeUpdater.instance;
                    if (homeUpdater != null) {
                      homeUpdater.notifyHomeToRefresh();
                    }
                  }).catchError((e) {
                    print('Error updating starred status: $e');
                    // Revert the UI update in case of error
                    setState(() {
                      _originalNote = _originalNote!.copyWith(
                        isStarred: _originalNote!.isStarredBool ? 0 : 1
                      );
                    });
                    
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error updating starred status: $e')),
                    );
                  });
                }
              },
              tooltip: _originalNote?.isStarredBool == true ? 'Remove from starred' : 'Add to starred',
            ),
            
          // Copy text button (always visible when viewing)
          if (!_isLoading && !_isInEditMode)
            IconButton(
              icon: const Icon(Icons.copy),
              onPressed: () {
                // Copy note content to clipboard
                final text = _quillController.document.toPlainText();
                final title = _titleController.text;
                final contentToCopy = '$title\n\n$text';
                
                Clipboard.setData(ClipboardData(text: contentToCopy))
                  .then((_) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Note copied to clipboard')),
                    );
                  });
              },
              tooltip: 'Copy text',
            ),
          // Folder button (always visible)
          if (_isInEditMode)
            IconButton(
              icon: const Icon(Icons.folder),
              onPressed: _showFolderSelectionDialog,
              tooltip: 'Choose folder',
            ),
          // If in view mode, show edit button
          if (_isEditing && !_isInEditMode)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: _toggleEditMode,
              tooltip: 'Edit',
            ),
          // Only show delete button when editing an existing note
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: _isLoading ? null : _moveToRecycleBin,
              tooltip: 'Move to recycle bin',
            ),
          // In edit mode, show save button
          if (_isInEditMode)
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _isLoading ? null : _saveNote,
              tooltip: 'Save',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // Title input
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: TextField(
                        controller: _titleController,
                        style: Theme.of(context).textTheme.titleLarge,
                        decoration: const InputDecoration(
                          hintText: 'Title',
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 8),
                        ),
                        maxLines: 1,
                        textCapitalization: TextCapitalization.sentences,
                        readOnly: !_isInEditMode, // Make title read-only in view mode
                      ),
                    ),
                    
                    // Folder indicator
                    if (_selectedFolder != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Row(
                          children: [
                            Icon(Icons.folder, 
                              size: 18, 
                              color: Theme.of(context).colorScheme.primary
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _selectedFolder!.name,
                              style: TextStyle(
                                fontSize: 14,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                            if (_isInEditMode)
                              IconButton(
                                icon: const Icon(Icons.close, size: 16),
                                onPressed: () {
                                  setState(() {
                                    _selectedFolderId = null;
                                    _selectedFolder = null;
                                  });
                                },
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                          ],
                        ),
                      ),
                    
                    // Tags section - only visible in edit mode or if there are tags to display
                    if (_isInEditMode || _noteTags.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Tag input field - only in edit mode
                            if (_isInEditMode)
                              Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: _tagController,
                                      focusNode: _tagFocusNode,
                                      decoration: const InputDecoration(
                                        hintText: 'Add a tag...',
                                        border: InputBorder.none,
                                        contentPadding: EdgeInsets.symmetric(vertical: 8),
                                        prefixIcon: Icon(Icons.tag, size: 20),
                                      ),
                                      maxLines: 1,
                                      textCapitalization: TextCapitalization.words,
                                      onSubmitted: (value) {
                                        if (value.trim().isNotEmpty) {
                                          _addTag(value);
                                        }
                                      },
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.add),
                                    onPressed: () {
                                      if (_tagController.text.trim().isNotEmpty) {
                                        _addTag(_tagController.text);
                                      }
                                    },
                                  ),
                                ],
                              ),
                            
                            // Tags list
                            if (_noteTags.isNotEmpty)
                              Wrap(
                                spacing: 8,
                                runSpacing: 4,
                                children: _noteTags.map((tag) => Chip(
                                  label: Text(tag.name),
                                  deleteIcon: _isInEditMode ? const Icon(Icons.close, size: 18) : null,
                                  onDeleted: _isInEditMode ? () => _removeTag(tag) : null,
                                )).toList(),
                              ),
                          ],
                        ),
                      ),
                    
                    const Divider(),
                    
                    // Quill toolbar - only visible in edit mode
                    if (_isInEditMode)
                      QuillToolbar.simple(
                        configurations: QuillSimpleToolbarConfigurations(
                          controller: _quillController,
                          sharedConfigurations: const QuillSharedConfigurations(
                            locale: Locale('en'),
                          ),
                        ),
                      ),
                    
                    // Quill editor
                    SizedBox(
                      height: MediaQuery.of(context).size.height * 0.6, // Fixed height to prevent layout issues
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: QuillEditor.basic(
                          configurations: QuillEditorConfigurations(
                            controller: _quillController,
                            sharedConfigurations: const QuillSharedConfigurations(
                              locale: Locale('en'),
                            ),
                            padding: const EdgeInsets.all(8),
                            autoFocus: false,
                            placeholder: 'Type your note here...',
                            scrollable: true,
                            expands: false, // Changed to false for better scrolling
                            // Provide embedding builders for images, videos, etc.
                            embedBuilders: FlutterQuillEmbeds.defaultEditorBuilders(),
                            keyboardAppearance: Brightness.light,
                          ),
                          focusNode: _editorFocusNode,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

// Dialog for selecting a folder
class FolderSelectionDialog extends StatefulWidget {
  final List<Folder> folders;
  final int? selectedFolderId;

  const FolderSelectionDialog({
    super.key, 
    required this.folders, 
    this.selectedFolderId,
  });

  @override
  State<FolderSelectionDialog> createState() => _FolderSelectionDialogState();
}

class _FolderSelectionDialogState extends State<FolderSelectionDialog> {
  late TextEditingController _newFolderController;
  List<Folder> _foldersWithRoot = [];
  int? _selectedFolderId;
  
  @override
  void initState() {
    super.initState();
    _newFolderController = TextEditingController();
    _selectedFolderId = widget.selectedFolderId;
    
    // Add a "No Folder" option at the beginning
    _foldersWithRoot = [
      Folder(id: null, name: "No Folder (Root)"),
      ...widget.folders,
    ];
  }
  
  @override
  void dispose() {
    _newFolderController.dispose();
    super.dispose();
  }

  // Create a new folder
  Future<void> _createNewFolder() async {
    final name = _newFolderController.text.trim();
    if (name.isEmpty) return;
    
    try {
      final id = await DatabaseService().createFolder(name);
      final newFolder = Folder(id: id, name: name);
      
      setState(() {
        _foldersWithRoot.add(newFolder);
        _selectedFolderId = id;
        _newFolderController.clear();
      });
      
      // Notify HomeScreen to refresh
      final HomeUpdater? homeUpdater = HomeUpdater.instance;
      if (homeUpdater != null) {
        homeUpdater.notifyHomeToRefresh();
      }
      
    } catch (e) {
      print('Error creating folder: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error creating folder: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Select Folder'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // New folder input
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _newFolderController,
                    decoration: const InputDecoration(
                      hintText: 'New folder name',
                      isDense: true,
                    ),
                    onSubmitted: (_) => _createNewFolder(),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: _createNewFolder,
                  tooltip: 'Create folder',
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Folder list
            Expanded(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _foldersWithRoot.length,
                itemBuilder: (context, index) {
                  final folder = _foldersWithRoot[index];
                  return RadioListTile<int?>(
                    title: Text(folder.name),
                    value: folder.id,
                    groupValue: _selectedFolderId,
                    onChanged: (value) {
                      setState(() {
                        _selectedFolderId = value;
                      });
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('CANCEL'),
        ),
        TextButton(
          onPressed: () {
            final selectedFolder = _foldersWithRoot.firstWhere(
              (folder) => folder.id == _selectedFolderId,
              orElse: () => _foldersWithRoot.first, // Return "No Folder" option if not found
            );
            Navigator.of(context).pop(selectedFolder);
          },
          child: const Text('SELECT'),
        ),
      ],
    );
  }
} 