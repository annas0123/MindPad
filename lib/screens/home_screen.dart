import 'dart:async';
import 'package:flutter/material.dart';
import '../models/note.dart';
import '../models/tag.dart';
import '../models/folder.dart';
import '../services/database_service.dart';
import '../services/home_updater.dart';
import '../widgets/app_drawer.dart';
import '../widgets/note_list_item.dart';
import 'note_edit_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // List to hold the notes from the database
  List<Note> _notes = [];
  bool _isLoading = true;
  Tag? _activeTagFilter;
  Folder? _activeFolder;  // Currently viewed folder
  bool _isStarredFilter = false; // Added for starred notes
  late HomeUpdater _homeUpdater;
  late StreamSubscription<bool> _refreshSubscription;
  
  // Search state variables
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  
  @override
  void initState() {
    super.initState();
    // Initialize HomeUpdater
    _homeUpdater = HomeUpdater();
    
    // Listen for refresh notifications
    _refreshSubscription = _homeUpdater.stream.listen((_) {
      // When a notification is received, reload notes with current filter
      _loadNotes(tagId: _activeTagFilter?.id, folderId: _activeFolder?.id, isStarred: _isStarredFilter);
    });
    
    _loadNotes();
  }
  
  @override
  void dispose() {
    // Cancel subscription when the widget is disposed
    _refreshSubscription.cancel();
    _searchController.dispose();
    super.dispose();
  }
  
  // Load notes from the database
  Future<void> _loadNotes({int? tagId, int? folderId, bool isStarred = false}) async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      List<Note> notes;
      
      if (isStarred) {
        // Load starred notes
        notes = await DatabaseService().getStarredNotes();
        // Clear other filters
        _activeTagFilter = null;
        _activeFolder = null;
        _isStarredFilter = true;
      } else if (tagId != null) {
        // Load notes with specific tag
        notes = await DatabaseService().getNotesByTag(tagId);
        
        // Update active tag filter if needed
        if (_activeTagFilter == null || _activeTagFilter!.id != tagId) {
          final allTags = await DatabaseService().getAllTags();
          _activeTagFilter = allTags.firstWhere((tag) => tag.id == tagId);
        }
        
        // Clear folder filter and starred filter when tag filter is applied
        _activeFolder = null;
        _isStarredFilter = false;
      } else if (folderId != null) {
        // Load notes in specific folder
        notes = await DatabaseService().getNotesByFolder(folderId);
        
        // Clear tag filter and starred filter when folder filter is applied
        _activeTagFilter = null;
        _isStarredFilter = false;
      } else {
        // Load root notes (no folder)
        notes = await DatabaseService().getNotesByFolder(null);
        _activeTagFilter = null;
        _isStarredFilter = false;
      }
      
      setState(() {
        _notes = notes;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print('Error loading notes: $e');
      // Show error snackbar
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading notes: $e')),
        );
      }
    }
  }
  
  // Move a note to the recycle bin
  Future<void> _moveToRecycleBin(Note note) async {
    // Remove from UI immediately
    final index = _notes.indexOf(note);
    setState(() {
      _notes.removeAt(index);
    });
    
    // Move to recycle bin
    try {
      await DatabaseService().moveNoteToRecycleBin(note.id!);
      
      // Show snackbar with undo option
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Note moved to recycle bin'),
            action: SnackBarAction(
              label: 'UNDO',
              onPressed: () async {
                // Restore note
                await DatabaseService().restoreNoteFromRecycleBin(note.id!);
                _loadNotes(tagId: _activeTagFilter?.id, folderId: _activeFolder?.id, isStarred: _isStarredFilter); // Reload notes list with current filter
              },
            ),
          ),
        );
      }
    } catch (e) {
      print('Error moving note to recycle bin: $e');
      // Show error and add back to UI
      setState(() {
        if (index >= 0 && index <= _notes.length) {
          _notes.insert(index, note);
        } else {
          _notes.add(note);
        }
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error moving note to recycle bin: $e')),
        );
      }
    }
  }
  
  // Toggle star status for a note
  Future<void> _toggleStarred(Note note) async {
    if (note.id == null) return;
    
    // Optimistic update - update UI first
    final newStarredStatus = !note.isStarredBool;
    final noteIndex = _notes.indexOf(note);
    
    if (noteIndex != -1) {
      setState(() {
        // Create an updated copy of the note
        final updatedNote = note.copyWith(isStarred: newStarredStatus ? 1 : 0);
        
        // If we're in starred filter and un-starring, remove from list
        if (_isStarredFilter && !newStarredStatus) {
          _notes.removeAt(noteIndex);
        } else {
          // Otherwise just update the list
          _notes[noteIndex] = updatedNote;
        }
      });
    }
    
    try {
      // Update in database
      await DatabaseService().updateNoteStarredStatus(note.id!, newStarredStatus);
    } catch (e) {
      print('Error updating starred status: $e');
      
      // Revert the optimistic update if there was an error
      if (noteIndex != -1) {
        setState(() {
          if (_isStarredFilter && !note.isStarredBool) {
            // We removed it, so add it back
            _notes.insert(noteIndex, note);
          } else if (noteIndex < _notes.length) {
            // We changed it, so change it back
            _notes[noteIndex] = note;
          }
        });
      }
      
      // Show error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating starred status: $e')),
        );
      }
    }
  }
  
  // Load all notes (clear all filters)
  void _loadAllNotes() {
    setState(() {
      _activeTagFilter = null;
      _activeFolder = null;
      _isStarredFilter = false;
    });
    _loadNotes();
  }
  
  // Load starred notes
  void _loadStarredNotes() {
    setState(() {
      _activeTagFilter = null;
      _activeFolder = null;
      _isStarredFilter = true;
    });
    _loadNotes(isStarred: true);
  }
  
  // Clear the active tag filter
  void _clearTagFilter() {
    setState(() {
      _activeTagFilter = null;
    });
    _loadNotes(folderId: _activeFolder?.id);
  }
  
  // Set the active folder
  void _setActiveFolder(Folder? folder) {
    setState(() {
      _activeFolder = folder;
      _activeTagFilter = null; // Clear tag filter when changing folders
    });
    _loadNotes(folderId: folder?.id);
  }
  
  // Get the title for the app bar
  String _getAppBarTitle() {
    if (_isStarredFilter) {
      return 'Starred Notes';
    } else if (_activeTagFilter != null) {
      return 'Tagged: ${_activeTagFilter!.name}';
    } else if (_activeFolder != null) {
      return 'Folder: ${_activeFolder!.name}';
    } else {
      return 'All Notes';
    }
  }
  
  // Search for notes matching query
  Future<void> _searchNotes(String query) async {
    if (query.isEmpty) {
      // If search query is empty, load regular notes
      return _loadNotes(tagId: _activeTagFilter?.id, folderId: _activeFolder?.id, isStarred: _isStarredFilter);
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final notes = await DatabaseService().searchNotes(query);
      
      setState(() {
        _notes = notes;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print('Error searching notes: $e');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error searching notes: $e')),
        );
      }
    }
  }
  
  // Toggle search mode
  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
      if (!_isSearching) {
        // If exiting search, clear search and reload original notes
        _searchController.clear();
        _loadNotes(tagId: _activeTagFilter?.id, folderId: _activeFolder?.id, isStarred: _isStarredFilter);
      }
    });
  }
  
  // Get the current active filter for the drawer
  String _getActiveFilter() {
    if (_isStarredFilter) {
      return 'starred';
    } else if (_activeTagFilter != null) {
      return 'tag_${_activeTagFilter!.id}';
    } else if (_activeFolder != null) {
      return 'folder_${_activeFolder!.id}';
    } else {
      return 'all_notes';
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _isSearching 
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Search notes...',
                  border: InputBorder.none,
                ),
                style: const TextStyle(color: Colors.white),
                onChanged: (value) {
                  _searchNotes(value);
                },
              )
            : Text(_getAppBarTitle()),
        elevation: 0,
        actions: [
          // Search icon
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: _toggleSearch,
            tooltip: _isSearching ? 'Cancel search' : 'Search notes',
          ),
          // If we have a tag filter or folder active, show a clear button
          if (!_isSearching && (_activeTagFilter != null || _activeFolder != null || _isStarredFilter))
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                setState(() {
                  _activeTagFilter = null;
                  _activeFolder = null;
                  _isStarredFilter = false;
                });
                _loadNotes();
              },
              tooltip: 'Clear filter',
            ),
        ],
      ),
      drawer: AppDrawer(
        onTagSelected: (tag) {
          _loadNotes(tagId: tag.id);
        },
        onFolderSelected: (folder) {
          _setActiveFolder(folder);
        },
        onStarredSelected: _loadStarredNotes,
        onAllNotesSelected: _loadAllNotes,
        activeFilter: _getActiveFilter(),
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : _notes.isEmpty
              ? _buildEmptyState()
              : _buildNotesList(),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          // Navigate to add note screen
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => NoteEditScreen(
                // If there's an active tag filter, pass it to the editor
                tagFilterId: _activeTagFilter?.id,
                startInEditMode: true, // Start in edit mode for new notes
                initialFolderId: _activeFolder?.id, // Pass current folder ID if any
              ),
            ),
          );
          
          // Refresh the list if a note was added
          if (result == true) {
            _loadNotes(tagId: _activeTagFilter?.id, folderId: _activeFolder?.id, isStarred: _isStarredFilter);
          }
        },
        tooltip: 'Add Note',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEmptyState() {
    String message = 'No notes yet';
    String subMessage = 'Tap the + button to create a note';
    
    if (_isSearching) {
      message = 'No notes match your search';
      subMessage = 'Try a different search term';
    } else if (_isStarredFilter) {
      message = 'No starred notes';
      subMessage = 'Star notes to see them here';
    } else if (_activeTagFilter != null) {
      message = 'No notes with tag "${_activeTagFilter!.name}"';
      subMessage = 'Tap the + button to create a note with this tag';
    } else if (_activeFolder != null) {
      message = 'No notes in folder "${_activeFolder!.name}"';
      subMessage = 'Tap the + button to create a note in this folder';
    }
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _isSearching ? Icons.search_off : Icons.note_alt_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            subMessage,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _buildNotesList() {
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: _notes.length,
      itemBuilder: (context, index) {
        final note = _notes[index];
        return NoteListItem(
          note: note,
          onDelete: () => _moveToRecycleBin(note),
          onRestore: () {}, // Not used in HomeScreen
          onStarToggle: (isStarred) => _toggleStarred(note),
          onTap: () async {
            // Navigate to edit screen with this note
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => NoteEditScreen(
                  noteId: note.id,
                  tagFilterId: _activeTagFilter?.id,
                  startInEditMode: false, // Start in view mode
                ),
              ),
            );
            
            // Refresh list if note was updated
            if (result == true) {
              _loadNotes(tagId: _activeTagFilter?.id, folderId: _activeFolder?.id, isStarred: _isStarredFilter);
            }
          },
        );
      },
    );
  }
} 