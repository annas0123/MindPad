import 'package:flutter/material.dart';
import '../models/note.dart';
import '../services/database_service.dart';
import '../screens/note_edit_screen.dart';

class NoteListItem extends StatelessWidget {
  final Note note;
  final Function onDelete;
  final Function onRestore;
  final Function onTap;
  final Function(bool)? onStarToggle;
  final bool isInRecycleBin;

  const NoteListItem({
    super.key,
    required this.note,
    required this.onDelete,
    required this.onRestore,
    required this.onTap,
    this.onStarToggle,
    this.isInRecycleBin = false,
  });

  // Format timestamp for display
  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inDays == 0) {
      // Today
      return 'Today, ${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      // Yesterday
      return 'Yesterday, ${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays < 7) {
      // This week
      final weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
      return '${weekdays[timestamp.weekday - 1]}, ${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
    } else {
      // Older
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }

  @override
  Widget build(BuildContext context) {
    // For items in recycle bin
    if (isInRecycleBin) {
      return Card(
        elevation: 2,
        margin: const EdgeInsets.symmetric(vertical: 4),
        child: ListTile(
          title: Text(
            note.title.isEmpty ? 'Untitled Note' : note.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(decoration: TextDecoration.lineThrough),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                note.plainTextContent,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                'Deleted on ${_formatTimestamp(note.timestamp)}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.restore),
                tooltip: 'Restore',
                onPressed: () => onRestore(),
              ),
              IconButton(
                icon: const Icon(Icons.delete_forever),
                tooltip: 'Delete permanently',
                onPressed: () => onDelete(),
              ),
            ],
          ),
        ),
      );
    }
    
    // For regular notes
    return Dismissible(
      key: Key(note.id?.toString() ?? UniqueKey().toString()),
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        child: const Icon(
          Icons.delete,
          color: Colors.white,
        ),
      ),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) async {
        // Show confirmation dialog
        return await showDialog(
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
      },
      onDismissed: (direction) => onDelete(),
      child: Card(
        elevation: 2,
        margin: const EdgeInsets.symmetric(vertical: 4),
        child: ListTile(
          title: Text(
            note.title.isEmpty ? 'Untitled Note' : note.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                note.plainTextContent,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                _formatTimestamp(note.timestamp),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
          trailing: onStarToggle != null 
              ? IconButton(
                  icon: Icon(
                    note.isStarredBool ? Icons.star : Icons.star_border,
                    color: note.isStarredBool ? Colors.amber : null,
                  ),
                  onPressed: () => onStarToggle!(!note.isStarredBool),
                  tooltip: note.isStarredBool ? 'Remove from starred' : 'Add to starred',
                )
              : null,
          onTap: () => onTap(),
        ),
      ),
    );
  }
} 