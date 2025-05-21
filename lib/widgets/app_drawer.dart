import 'package:flutter/material.dart';
import '../screens/recycle_bin_screen.dart';
import '../screens/settings_screen.dart';
import '../models/tag.dart';
import '../models/folder.dart';
import '../services/database_service.dart';
import '../services/home_updater.dart';

class AppDrawer extends StatefulWidget {
  final Function(Tag)? onTagSelected;
  final Function(Folder?)? onFolderSelected;
  final Function()? onStarredSelected;
  final Function()? onAllNotesSelected;
  final String activeFilter;
  
  const AppDrawer({
    super.key, 
    this.onTagSelected, 
    this.onFolderSelected, 
    this.onStarredSelected,
    this.onAllNotesSelected,
    this.activeFilter = '',
  });

  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  List<Tag> _tags = [];
  List<Folder> _folders = [];
  bool _isLoadingTags = false;
  bool _isLoadingFolders = false;
  final TextEditingController _newFolderController = TextEditingController();
  
  @override
  void initState() {
    super.initState();
    _loadTags();
    _loadFolders();
  }
  
  @override
  void dispose() {
    _newFolderController.dispose();
    super.dispose();
  }
  
  // Load all tags from the database
  Future<void> _loadTags() async {
    setState(() {
      _isLoadingTags = true;
    });
    
    try {
      final tags = await DatabaseService().getAllTags();
      setState(() {
        _tags = tags;
        _isLoadingTags = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingTags = false;
      });
      print('Error loading tags: $e');
    }
  }
  
  // Load folders from the database
  Future<void> _loadFolders() async {
    setState(() {
      _isLoadingFolders = true;
    });
    
    try {
      final folders = await DatabaseService().getAllFolders();
      setState(() {
        _folders = folders;
        _isLoadingFolders = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingFolders = false;
      });
      print('Error loading folders: $e');
    }
  }
  
  // Create a new folder
  Future<void> _createFolder() async {
    final name = _newFolderController.text.trim();
    if (name.isEmpty) return;
    
    try {
      await DatabaseService().createFolder(name);
      _newFolderController.clear();
      await _loadFolders();
      
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
  
  // Show dialog to create a folder
  Future<void> _showCreateFolderDialog() async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create New Folder'),
        content: TextField(
          controller: _newFolderController,
          decoration: const InputDecoration(
            hintText: 'Folder name',
          ),
          autofocus: true,
          onSubmitted: (_) {
            Navigator.pop(context);
            _createFolder();
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _createFolder();
            },
            child: const Text('CREATE'),
          ),
        ],
      ),
    );
  }
  
  // Delete a folder
  Future<void> _deleteFolder(Folder folder) async {
    // Show confirmation dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Folder'),
        content: Text(
          'Are you sure you want to delete the folder "${folder.name}"? '
          'Notes in this folder will be moved to the root level.'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('DELETE'),
          ),
        ],
      ),
    );
    
    if (confirm != true) return;
    
    try {
      await DatabaseService().deleteFolder(folder.id!);
      await _loadFolders();
      
      // Notify HomeScreen to refresh
      final HomeUpdater? homeUpdater = HomeUpdater.instance;
      if (homeUpdater != null) {
        homeUpdater.notifyHomeToRefresh();
      }
    } catch (e) {
      print('Error deleting folder: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting folder: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  'Mindpad',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Your thoughts, organized.',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          
          // All Notes
          ListTile(
            leading: const Icon(Icons.note),
            title: const Text('All Notes'),
            selected: widget.activeFilter == 'all_notes',
            onTap: () {
              Navigator.pop(context); // Close drawer
              if (widget.onAllNotesSelected != null) {
                widget.onAllNotesSelected!();
              } else if (widget.onFolderSelected != null) {
                widget.onFolderSelected!(null); // Select root (no folder)
              }
            },
          ),
          
          // Starred Notes
          if (widget.onStarredSelected != null)
            ListTile(
              leading: const Icon(Icons.star, color: Colors.amber),
              title: const Text('Starred'),
              selected: widget.activeFilter == 'starred',
              onTap: () {
                Navigator.pop(context); // Close drawer
                widget.onStarredSelected!();
              },
            ),
          
          // Folders section
          const Divider(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'FOLDERS',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add, size: 20),
                  onPressed: _showCreateFolderDialog,
                  tooltip: 'Add Folder',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
          
          if (_isLoadingFolders)
            const Center(child: Padding(
              padding: EdgeInsets.all(8.0),
              child: CircularProgressIndicator(),
            ))
          else if (_folders.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'No folders yet',
                style: TextStyle(
                  color: Colors.grey,
                  fontStyle: FontStyle.italic,
                ),
              ),
            )
          else
            ..._buildFolderList(),
          
          // Tags section
          if (widget.onTagSelected != null) ...[
            const Divider(),
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Text(
                'TAGS',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
            ),
            if (_isLoadingTags)
              const Center(child: Padding(
                padding: EdgeInsets.all(8.0),
                child: CircularProgressIndicator(),
              ))
            else if (_tags.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'No tags yet',
                  style: TextStyle(
                    color: Colors.grey,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              )
            else
              ..._tags.map((tag) => ListTile(
                leading: const Icon(Icons.tag),
                title: Text(tag.name),
                dense: true,
                selected: widget.activeFilter == 'tag_${tag.id}',
                onTap: () {
                  Navigator.pop(context); // Close drawer
                  if (widget.onTagSelected != null) {
                    widget.onTagSelected!(tag);
                  }
                },
              )).toList(),
          ],
          
          const Divider(),
          
          // Recycle Bin
          ListTile(
            leading: const Icon(Icons.delete_outline),
            title: const Text('Recycle Bin'),
            onTap: () {
              // First close the drawer
              Navigator.pop(context);
              
              // Then navigate to RecycleBinScreen
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const RecycleBinScreen(),
                ),
              );
            },
          ),
          
          const Divider(),
          
          // Settings
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Settings'),
            onTap: () {
              // First close the drawer
              Navigator.pop(context);
              
              // Then navigate to Settings
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SettingsScreen(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
  
  // Build folder list items with hierarchy
  List<Widget> _buildFolderList() {
    // First, organize folders into a tree structure
    Map<int?, List<Folder>> foldersByParent = {};
    
    // Initialize with root folders
    foldersByParent[null] = [];
    
    // Group folders by parent ID
    for (var folder in _folders) {
      if (!foldersByParent.containsKey(folder.parentId)) {
        foldersByParent[folder.parentId] = [];
      }
      foldersByParent[folder.parentId]!.add(folder);
    }
    
    // Build folder tiles recursively
    List<Widget> result = [];
    
    // Build root-level folders
    if (foldersByParent.containsKey(null)) {
      for (var folder in foldersByParent[null]!) {
        result.add(_buildFolderTile(folder, foldersByParent, 0));
      }
    }
    
    return result;
  }
  
  // Build a single folder tile with its children
  Widget _buildFolderTile(Folder folder, Map<int?, List<Folder>> foldersByParent, int level) {
    bool hasChildren = foldersByParent.containsKey(folder.id) && 
                      foldersByParent[folder.id]!.isNotEmpty;
    
    List<Widget> children = [];
    
    // Add children recursively if they exist
    if (hasChildren) {
      for (var child in foldersByParent[folder.id]!) {
        children.add(_buildFolderTile(child, foldersByParent, level + 1));
      }
    }
    
    return Column(
      children: [
        ListTile(
          leading: const Icon(Icons.folder),
          title: Text(folder.name),
          dense: true,
          selected: widget.activeFilter == 'folder_${folder.id}',
          contentPadding: EdgeInsets.only(left: 16.0 + (level * 16.0), right: 16.0),
          onTap: () {
            Navigator.pop(context); // Close drawer
            if (widget.onFolderSelected != null) {
              widget.onFolderSelected!(folder);
            }
          },
          trailing: IconButton(
            icon: const Icon(Icons.delete, size: 18),
            onPressed: () => _deleteFolder(folder),
            tooltip: 'Delete folder',
          ),
        ),
        // Add children
        ...children,
      ],
    );
  }
} 