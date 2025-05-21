import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../models/note.dart';
import '../models/tag.dart';
import '../models/folder.dart';

class DatabaseService {
  // Singleton pattern
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  static Database? _database;

  // Database name and version
  static const String _databaseName = 'mindpad.db';
  static const int _databaseVersion = 5; // Increased version for isStarred support

  // Table and column names for notes
  static const String tableNotes = 'notes';
  static const String columnId = 'id';
  static const String columnTitle = 'title';
  static const String columnContent = 'content';
  static const String columnTimestamp = 'timestamp';
  static const String columnIsDeleted = 'isDeleted';
  static const String columnIsStarred = 'isStarred';
  static const String columnNoteFolderId = 'folder_id';

  // Table and column names for tags
  static const String tableTags = 'tags';
  static const String columnTagId = 'id';
  static const String columnTagName = 'tag_name';

  // Table and column names for note_tags relationship
  static const String tableNoteTags = 'note_tags';
  static const String columnNoteId = 'note_id';
  static const String columnTagId2 = 'tag_id';

  // Table and column names for folders
  static const String tableFolders = 'folders';
  static const String columnFolderId = 'id';
  static const String columnFolderName = 'folder_name';
  static const String columnParentId = 'parent_id';
  static const String columnOrder = 'sort_order';

  // Get the database, initializing it if necessary
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await initDatabase();
    return _database!;
  }

  // Initialize the database
  Future<Database> initDatabase() async {
    // Get the directory for Android/iOS to store the database
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, _databaseName);

    // Open/create the database
    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  // Create the database tables when the database is first created
  Future<void> _onCreate(Database db, int version) async {
    // Create folders table
    await db.execute('''
      CREATE TABLE $tableFolders (
        $columnFolderId INTEGER PRIMARY KEY AUTOINCREMENT,
        $columnFolderName TEXT NOT NULL,
        $columnParentId INTEGER NULL,
        $columnOrder INTEGER DEFAULT 0,
        FOREIGN KEY ($columnParentId) REFERENCES $tableFolders($columnFolderId) ON DELETE CASCADE
      )
    ''');

    // Create notes table
    await db.execute('''
      CREATE TABLE $tableNotes (
        $columnId INTEGER PRIMARY KEY AUTOINCREMENT,
        $columnTitle TEXT,
        $columnContent TEXT,
        $columnTimestamp INTEGER,
        $columnIsDeleted INTEGER DEFAULT 0,
        $columnIsStarred INTEGER DEFAULT 0,
        $columnNoteFolderId INTEGER NULL,
        FOREIGN KEY ($columnNoteFolderId) REFERENCES $tableFolders($columnFolderId) ON DELETE SET NULL
      )
    ''');

    // Try to create FTS virtual table for notes search
    try {
      // Use FTS4 instead of FTS5 for better compatibility
      await db.execute('''
        CREATE VIRTUAL TABLE notes_fts USING fts4(title, content);
      ''');

      // Create triggers to sync notes_fts with notes table
      // After insert trigger
      await db.execute('''
        CREATE TRIGGER notes_after_insert AFTER INSERT ON $tableNotes
        BEGIN
          INSERT INTO notes_fts(rowid, title, content)
          VALUES (new.$columnId, new.$columnTitle, new.$columnContent);
        END;
      ''');

      // After update trigger
      await db.execute('''
        CREATE TRIGGER notes_after_update AFTER UPDATE ON $tableNotes
        BEGIN
          UPDATE notes_fts
          SET title = new.$columnTitle, content = new.$columnContent
          WHERE rowid = new.$columnId;
        END;
      ''');

      // After delete trigger
      await db.execute('''
        CREATE TRIGGER notes_after_delete AFTER DELETE ON $tableNotes
        BEGIN
          DELETE FROM notes_fts WHERE rowid = old.$columnId;
        END;
      ''');
    } catch (e) {
      print('Warning: Could not create FTS table. Full-text search will be disabled: $e');
      // Continue without FTS support
    }

    // Create tags table
    await db.execute('''
      CREATE TABLE $tableTags (
        $columnTagId INTEGER PRIMARY KEY AUTOINCREMENT,
        $columnTagName TEXT UNIQUE NOT NULL
      )
    ''');

    // Create note_tags junction table
    await db.execute('''
      CREATE TABLE $tableNoteTags (
        $columnNoteId INTEGER,
        $columnTagId2 INTEGER,
        PRIMARY KEY ($columnNoteId, $columnTagId2),
        FOREIGN KEY ($columnNoteId) REFERENCES $tableNotes($columnId) ON DELETE CASCADE,
        FOREIGN KEY ($columnTagId2) REFERENCES $tableTags($columnTagId) ON DELETE CASCADE
      )
    ''');
  }

  // Handle database upgrades between versions
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Create tags table if upgrading from version 1
      await db.execute('''
        CREATE TABLE IF NOT EXISTS $tableTags (
          $columnTagId INTEGER PRIMARY KEY AUTOINCREMENT,
          $columnTagName TEXT UNIQUE NOT NULL
        )
      ''');

      // Create note_tags junction table if upgrading from version 1
      await db.execute('''
        CREATE TABLE IF NOT EXISTS $tableNoteTags (
          $columnNoteId INTEGER,
          $columnTagId2 INTEGER,
          PRIMARY KEY ($columnNoteId, $columnTagId2),
          FOREIGN KEY ($columnNoteId) REFERENCES $tableNotes($columnId) ON DELETE CASCADE,
          FOREIGN KEY ($columnTagId2) REFERENCES $tableTags($columnTagId) ON DELETE CASCADE
        )
      ''');
    }
    
    if (oldVersion < 3) {
      // Create folders table if upgrading to version 3
      await db.execute('''
        CREATE TABLE IF NOT EXISTS $tableFolders (
          $columnFolderId INTEGER PRIMARY KEY AUTOINCREMENT,
          $columnFolderName TEXT NOT NULL,
          $columnParentId INTEGER NULL,
          $columnOrder INTEGER DEFAULT 0,
          FOREIGN KEY ($columnParentId) REFERENCES $tableFolders($columnFolderId) ON DELETE CASCADE
        )
      ''');
      
      // Add folder_id column to notes table
      await db.execute('''
        ALTER TABLE $tableNotes ADD COLUMN $columnNoteFolderId INTEGER NULL
        REFERENCES $tableFolders($columnFolderId) ON DELETE SET NULL
      ''');
    }
    
    if (oldVersion < 4) {
      // Try to create FTS virtual table for notes search
      try {
        // Use FTS4 instead of FTS5 for better compatibility
        await db.execute('''
          CREATE VIRTUAL TABLE IF NOT EXISTS notes_fts USING fts4(title, content);
        ''');

        // Create triggers to sync notes_fts with notes table
        // After insert trigger
        await db.execute('''
          CREATE TRIGGER IF NOT EXISTS notes_after_insert AFTER INSERT ON $tableNotes
          BEGIN
            INSERT INTO notes_fts(rowid, title, content)
            VALUES (new.$columnId, new.$columnTitle, new.$columnContent);
          END;
        ''');

        // After update trigger
        await db.execute('''
          CREATE TRIGGER IF NOT EXISTS notes_after_update AFTER UPDATE ON $tableNotes
          BEGIN
            UPDATE notes_fts
            SET title = new.$columnTitle, content = new.$columnContent
            WHERE rowid = new.$columnId;
          END;
        ''');

        // After delete trigger
        await db.execute('''
          CREATE TRIGGER IF NOT EXISTS notes_after_delete AFTER DELETE ON $tableNotes
          BEGIN
            DELETE FROM notes_fts WHERE rowid = old.$columnId;
          END;
        ''');
        
        // Populate FTS table with existing notes
        await db.execute('''
          INSERT INTO notes_fts(rowid, title, content)
          SELECT $columnId, $columnTitle, $columnContent FROM $tableNotes;
        ''');
      } catch (e) {
        print('Warning: Could not create FTS table. Full-text search will be disabled: $e');
        // Continue without FTS support
      }
    }
    
    if (oldVersion < 5) {
      // Add isStarred column to notes table
      try {
        await db.execute('''
          ALTER TABLE $tableNotes ADD COLUMN $columnIsStarred INTEGER DEFAULT 0;
        ''');
      } catch (e) {
        print('Warning: Could not add isStarred column: $e');
        // Continue without the column
      }
    }
  }

  // CRUD Operations for Folders
  
  // Create a new folder
  Future<int> createFolder(String folderName, {int? parentId, int sortOrder = 0}) async {
    Database db = await database;
    
    final folder = Folder(
      name: folderName.trim(),
      parentId: parentId,
      order: sortOrder,
    );
    
    return await db.insert(tableFolders, folder.toMap());
  }
  
  // Get a folder by ID
  Future<Folder?> getFolderById(int id) async {
    Database db = await database;
    List<Map<String, dynamic>> maps = await db.query(
      tableFolders,
      where: '$columnFolderId = ?',
      whereArgs: [id],
    );
    
    if (maps.isNotEmpty) {
      return Folder.fromMap(maps.first);
    }
    return null;
  }
  
  // Get all folders, optionally filtered by parent ID
  Future<List<Folder>> getFolders({int? parentId}) async {
    Database db = await database;
    
    String whereClause;
    List<dynamic> whereArgs;
    
    if (parentId != null) {
      // Get children of specific parent
      whereClause = '$columnParentId = ?';
      whereArgs = [parentId];
    } else {
      // Get root folders (where parentId is null)
      whereClause = '$columnParentId IS NULL';
      whereArgs = [];
    }
    
    List<Map<String, dynamic>> maps = await db.query(
      tableFolders,
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: '$columnOrder ASC, $columnFolderName ASC',
    );
    
    return List.generate(maps.length, (i) => Folder.fromMap(maps[i]));
  }
  
  // Get all folders in a flat list (for dropdown menus, etc.)
  Future<List<Folder>> getAllFolders() async {
    Database db = await database;
    
    List<Map<String, dynamic>> maps = await db.query(
      tableFolders,
      orderBy: '$columnOrder ASC, $columnFolderName ASC',
    );
    
    return List.generate(maps.length, (i) => Folder.fromMap(maps[i]));
  }
  
  // Update an existing folder
  Future<int> updateFolder(Folder folder) async {
    Database db = await database;
    return await db.update(
      tableFolders,
      folder.toMap(),
      where: '$columnFolderId = ?',
      whereArgs: [folder.id],
    );
  }
  
  // Delete a folder and all its subfolders
  Future<void> deleteFolder(int id) async {
    Database db = await database;
    
    // Get subfolders recursively
    await _deleteFolderRecursive(db, id);
  }
  
  // Helper method to recursively delete folders
  Future<void> _deleteFolderRecursive(Database db, int folderId) async {
    // Find child folders
    List<Map<String, dynamic>> children = await db.query(
      tableFolders,
      columns: [columnFolderId],
      where: '$columnParentId = ?',
      whereArgs: [folderId],
    );
    
    // Recursively delete each child
    for (var child in children) {
      await _deleteFolderRecursive(db, child[columnFolderId]);
    }
    
    // Delete the folder itself
    await db.delete(
      tableFolders,
      where: '$columnFolderId = ?',
      whereArgs: [folderId],
    );
  }

  // CRUD Operations for Notes

  // Create: Insert a new note into the database
  Future<int> createNote(Note note, {int? folderId}) async {
    Database db = await database;
    
    // Add folder ID to the note data if provided
    final noteMap = note.toMap();
    if (folderId != null) {
      noteMap[columnNoteFolderId] = folderId;
    }
    
    return await db.insert(tableNotes, noteMap);
  }

  // Read: Get all notes that are not in the recycle bin
  Future<List<Note>> getNotes() async {
    Database db = await database;
    List<Map<String, dynamic>> maps = await db.query(
      tableNotes,
      where: '$columnIsDeleted = ?',
      whereArgs: [0],
      orderBy: '$columnTimestamp DESC',
    );
    return List.generate(maps.length, (i) => Note.fromMap(maps[i]));
  }
  
  // Read: Get notes in a specific folder
  Future<List<Note>> getNotesByFolder(int? folderId) async {
    Database db = await database;
    
    String whereClause;
    List<dynamic> whereArgs;
    
    if (folderId != null) {
      // Get notes in specific folder
      whereClause = '$columnIsDeleted = ? AND $columnNoteFolderId = ?';
      whereArgs = [0, folderId];
    } else {
      // Get root notes (where folderId is null)
      whereClause = '$columnIsDeleted = ? AND $columnNoteFolderId IS NULL';
      whereArgs = [0];
    }
    
    List<Map<String, dynamic>> maps = await db.query(
      tableNotes,
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: '$columnTimestamp DESC',
    );
    
    return List.generate(maps.length, (i) => Note.fromMap(maps[i]));
  }

  // Read: Get deleted notes (recycle bin)
  Future<List<Note>> getDeletedNotes() async {
    Database db = await database;
    List<Map<String, dynamic>> maps = await db.query(
      tableNotes,
      where: '$columnIsDeleted = ?',
      whereArgs: [1],
      orderBy: '$columnTimestamp DESC',
    );
    return List.generate(maps.length, (i) => Note.fromMap(maps[i]));
  }

  // Read: Get a note by ID
  Future<Note?> getNoteById(int id) async {
    Database db = await database;
    List<Map<String, dynamic>> maps = await db.query(
      tableNotes,
      where: '$columnId = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return Note.fromMap(maps.first);
    }
    return null;
  }
  
  // Get the folder ID for a note
  Future<int?> getNoteFolderId(int noteId) async {
    Database db = await database;
    List<Map<String, dynamic>> maps = await db.query(
      tableNotes,
      columns: [columnNoteFolderId],
      where: '$columnId = ?',
      whereArgs: [noteId],
    );
    
    if (maps.isNotEmpty && maps.first[columnNoteFolderId] != null) {
      return maps.first[columnNoteFolderId] as int;
    }
    return null;
  }

  // Update: Update an existing note
  Future<int> updateNote(Note note, {int? folderId}) async {
    Database db = await database;
    
    // Add folder ID to the note data if provided
    final noteMap = note.toMap();
    noteMap[columnNoteFolderId] = folderId; // Can be null to remove from folder
    
    return await db.update(
      tableNotes,
      noteMap,
      where: '$columnId = ?',
      whereArgs: [note.id],
    );
  }

  // Delete: Move a note to the recycle bin (set isDeleted to 1)
  Future<int> moveNoteToRecycleBin(int id) async {
    Database db = await database;
    // We don't need to manually handle tags, as the foreign key relationship 
    // will keep the tag-note associations in the junction table even when isDeleted=1
    return await db.update(
      tableNotes,
      {columnIsDeleted: 1},
      where: '$columnId = ?',
      whereArgs: [id],
    );
  }

  // Delete: Permanently delete a note
  Future<int> deleteNotePermanently(int id) async {
    Database db = await database;
    return await db.delete(
      tableNotes,
      where: '$columnId = ?',
      whereArgs: [id],
    );
  }

  // Delete: Empty the recycle bin (delete all notes with isDeleted = 1)
  Future<int> emptyRecycleBin() async {
    Database db = await database;
    return await db.delete(
      tableNotes,
      where: '$columnIsDeleted = ?',
      whereArgs: [1],
    );
  }

  // Restore: Move a note from recycle bin back to active notes
  Future<int> restoreNoteFromRecycleBin(int id) async {
    Database db = await database;
    // Tag associations in the junction table remain intact
    // so when we restore the note, all its tags will still be associated
    return await db.update(
      tableNotes,
      {columnIsDeleted: 0},
      where: '$columnId = ?',
      whereArgs: [id],
    );
  }

  // CRUD Operations for Tags

  // Create or get a tag
  Future<int> createTag(String tagName) async {
    Database db = await database;
    
    // Check if tag already exists
    List<Map<String, dynamic>> existingTags = await db.query(
      tableTags,
      where: '$columnTagName = ?',
      whereArgs: [tagName.trim()],
    );
    
    if (existingTags.isNotEmpty) {
      return existingTags.first[columnTagId];
    }
    
    // If not, create new tag
    return await db.insert(
      tableTags,
      {columnTagName: tagName.trim()},
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }
  
  // Get a tag by name
  Future<Tag?> getTagByName(String tagName) async {
    Database db = await database;
    List<Map<String, dynamic>> maps = await db.query(
      tableTags,
      where: '$columnTagName = ?',
      whereArgs: [tagName.trim()],
    );
    
    if (maps.isNotEmpty) {
      return Tag.fromMap(maps.first);
    }
    return null;
  }
  
  // Get all tags that are associated with non-deleted notes
  Future<List<Tag>> getAllTags() async {
    Database db = await database;
    
    // Only get tags that are associated with at least one non-deleted note
    const query = '''
      SELECT DISTINCT t.$columnTagId, t.$columnTagName
      FROM $tableTags t
      INNER JOIN $tableNoteTags nt ON t.$columnTagId = nt.$columnTagId2
      INNER JOIN $tableNotes n ON n.$columnId = nt.$columnNoteId
      WHERE n.$columnIsDeleted = 0
      ORDER BY t.$columnTagName
    ''';
    
    List<Map<String, dynamic>> maps = await db.rawQuery(query);
    return List.generate(maps.length, (i) => Tag.fromMap(maps[i]));
  }
  
  // Link a note to a tag
  Future<int> addTagToNote(int noteId, int tagId) async {
    Database db = await database;
    return await db.insert(
      tableNoteTags,
      {columnNoteId: noteId, columnTagId2: tagId},
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }
  
  // Remove a tag from a note
  Future<int> removeTagFromNote(int noteId, int tagId) async {
    Database db = await database;
    return await db.delete(
      tableNoteTags,
      where: '$columnNoteId = ? AND $columnTagId2 = ?',
      whereArgs: [noteId, tagId],
    );
  }
  
  // Remove all tags from a note
  Future<int> removeAllTagsFromNote(int noteId) async {
    Database db = await database;
    return await db.delete(
      tableNoteTags,
      where: '$columnNoteId = ?',
      whereArgs: [noteId],
    );
  }
  
  // Get all tags for a note
  Future<List<Tag>> getTagsForNote(int noteId) async {
    Database db = await database;
    const query = '''
      SELECT t.$columnTagId, t.$columnTagName
      FROM $tableTags t
      INNER JOIN $tableNoteTags nt ON t.$columnTagId = nt.$columnTagId2
      WHERE nt.$columnNoteId = ?
    ''';
    
    List<Map<String, dynamic>> maps = await db.rawQuery(query, [noteId]);
    return List.generate(maps.length, (i) => Tag.fromMap(maps[i]));
  }
  
  // Get all notes with a specific tag
  Future<List<Note>> getNotesByTag(int tagId) async {
    Database db = await database;
    const query = '''
      SELECT n.*
      FROM $tableNotes n
      INNER JOIN $tableNoteTags nt ON n.$columnId = nt.$columnNoteId
      WHERE nt.$columnTagId2 = ? AND n.$columnIsDeleted = 0
      ORDER BY n.$columnTimestamp DESC
    ''';
    
    List<Map<String, dynamic>> maps = await db.rawQuery(query, [tagId]);
    return List.generate(maps.length, (i) => Note.fromMap(maps[i]));
  }

  // Add searchNotes method to search using FTS with fallback for when FTS is not available
  Future<List<Note>> searchNotes(String query) async {
    Database db = await database;
    
    try {
      // First try to use FTS
      const searchQuery = '''
        SELECT n.*
        FROM $tableNotes n
        WHERE n.$columnId IN (
          SELECT rowid FROM notes_fts WHERE notes_fts MATCH ?
        )
        AND n.$columnIsDeleted = 0
        ORDER BY n.$columnTimestamp DESC
      ''';
      
      List<Map<String, dynamic>> maps = await db.rawQuery(searchQuery, [query]);
      return List.generate(maps.length, (i) => Note.fromMap(maps[i]));
    } catch (e) {
      print('FTS search failed, falling back to LIKE search: $e');
      // If FTS fails, fall back to basic LIKE search
      const fallbackQuery = '''
        SELECT *
        FROM $tableNotes
        WHERE ($columnTitle LIKE ? OR $columnContent LIKE ?)
        AND $columnIsDeleted = 0
        ORDER BY $columnTimestamp DESC
      ''';
      
      String likePattern = '%$query%';
      List<Map<String, dynamic>> maps = await db.rawQuery(
        fallbackQuery, 
        [likePattern, likePattern]
      );
      return List.generate(maps.length, (i) => Note.fromMap(maps[i]));
    }
  }

  // Update isStarred status of a note
  Future<int> updateNoteStarredStatus(int noteId, bool isStarred) async {
    Database db = await database;
    return await db.update(
      tableNotes,
      {columnIsStarred: isStarred ? 1 : 0},
      where: '$columnId = ?',
      whereArgs: [noteId],
    );
  }

  // Get starred notes
  Future<List<Note>> getStarredNotes() async {
    Database db = await database;
    List<Map<String, dynamic>> maps = await db.query(
      tableNotes,
      where: '$columnIsStarred = ? AND $columnIsDeleted = ?',
      whereArgs: [1, 0],
      orderBy: '$columnTimestamp DESC',
    );
    return List.generate(maps.length, (i) => Note.fromMap(maps[i]));
  }
} 