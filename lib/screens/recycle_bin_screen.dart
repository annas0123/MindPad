import 'package:flutter/material.dart';
import '../models/note.dart';
import '../services/database_service.dart';
import '../widgets/note_list_item.dart';
import '../services/home_updater.dart';

class RecycleBinScreen extends StatefulWidget {
  const RecycleBinScreen({super.key});

  @override
  State<RecycleBinScreen> createState() => _RecycleBinScreenState();
}

class _RecycleBinScreenState extends State<RecycleBinScreen> {
  List<Note> _deletedNotes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDeletedNotes();
  }

  Future<void> _loadDeletedNotes() async {
    setState(() => _isLoading = true);

    try {
      final notes = await DatabaseService().getDeletedNotes();
      setState(() {
        _deletedNotes = notes;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading deleted notes: $e')),
        );
      }
    }
  }

  // Format timestamp for display
  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inDays == 0) {
      return 'Today, ${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return 'Yesterday, ${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays < 7) {
      final weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
      return '${weekdays[timestamp.weekday - 1]}, ${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }

  Future<void> _restoreNote(Note note) async {
    try {
      await DatabaseService().restoreNoteFromRecycleBin(note.id!);
      await _loadDeletedNotes(); // Refresh list
      
      if (mounted) {
        // Notify HomeScreen that data has changed
        final HomeUpdater? homeUpdater = HomeUpdater.instance;
        if (homeUpdater != null) {
          homeUpdater.notifyHomeToRefresh();
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Note restored')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error restoring note: $e')),
        );
      }
    }
  }

  Future<void> _permanentlyDeleteNote(Note note) async {
    // Show confirmation dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Permanently Delete Note'),
        content: const Text(
          'This action cannot be undone. Are you sure you want to permanently delete this note?'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('DELETE'),
          ),
        ],
      ),
    );
    
    if (confirm != true) return;
    
    try {
      await DatabaseService().deleteNotePermanently(note.id!);
      await _loadDeletedNotes(); // Refresh list
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Note permanently deleted')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting note: $e')),
        );
      }
    }
  }

  Future<void> _emptyRecycleBin() async {
    if (_deletedNotes.isEmpty) return;
    
    // Show confirmation dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Empty Recycle Bin'),
        content: const Text(
          'This will permanently delete all notes in the recycle bin. This action cannot be undone. Are you sure?'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('EMPTY'),
          ),
        ],
      ),
    );
    
    if (confirm != true) return;
    
    try {
      await DatabaseService().emptyRecycleBin();
      await _loadDeletedNotes(); // Refresh list
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Recycle bin emptied')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error emptying recycle bin: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recycle Bin'),
        actions: [
          if (_deletedNotes.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_forever),
              tooltip: 'Empty recycle bin',
              onPressed: _emptyRecycleBin,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _deletedNotes.isEmpty
              ? _buildEmptyState()
              : _buildNotesList(),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.delete_outline,
            size: 80,
            color: Colors.grey,
          ),
          SizedBox(height: 16),
          Text(
            'Recycle Bin is Empty',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            'Notes moved to the recycle bin will appear here',
            style: TextStyle(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildNotesList() {
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: _deletedNotes.length,
      itemBuilder: (context, index) {
        final note = _deletedNotes[index];
        return NoteListItem(
          note: note,
          onDelete: () => _permanentlyDeleteNote(note),
          onRestore: () => _restoreNote(note),
          onTap: () {}, // Tapping is disabled for deleted notes
          isInRecycleBin: true,
        );
      },
    );
  }
} 