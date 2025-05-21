import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_quill/quill_delta.dart';

class Note {
  final int? id; // Nullable for new notes
  final String title;
  final String content; // Stored as JSON string for rich text
  final DateTime timestamp;
  final int isDeleted; // 0 for false, 1 for true
  final int isStarred; // 0 for false, 1 for true

  Note({
    this.id,
    required this.title,
    required this.content,
    required this.timestamp,
    this.isDeleted = 0,
    this.isStarred = 0,
  });

  // Getters for boolean conversion
  bool get isDeletedBool => isDeleted == 1;
  bool get isStarredBool => isStarred == 1;
  
  // Get plain text content from rich text JSON for preview
  String get plainTextContent {
    try {
      // Parse the JSON content to Delta
      final delta = Delta.fromJson(jsonDecode(content));
      // Convert Delta to plain text
      return Document.fromDelta(delta).toPlainText();
    } catch (e) {
      // If content is not valid JSON or conversion fails, return as is
      return content;
    }
  }

  // Convert from QuillController to JSON string for storage
  static String quillControllerToJson(QuillController controller) {
    return jsonEncode(controller.document.toDelta().toJson());
  }

  // Create a QuillController from the stored JSON string
  QuillController get quillController {
    try {
      final delta = Delta.fromJson(jsonDecode(content));
      return QuillController(
        document: Document.fromDelta(delta),
        selection: const TextSelection.collapsed(offset: 0),
      );
    } catch (e) {
      // If content is not valid JSON, create controller with plain text
      final doc = Document();
      doc.insert(0, content);
      return QuillController(
        document: doc,
        selection: const TextSelection.collapsed(offset: 0),
      );
    }
  }
  
  // Create a copy of the current note with updated fields
  Note copyWith({
    int? id,
    String? title,
    String? content,
    DateTime? timestamp,
    int? isDeleted,
    int? isStarred,
  }) {
    return Note(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      timestamp: timestamp ?? this.timestamp,
      isDeleted: isDeleted ?? this.isDeleted,
      isStarred: isStarred ?? this.isStarred,
    );
  }

  // Convert a Note object to a Map for database operations
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'timestamp': timestamp.millisecondsSinceEpoch, // Store as Unix timestamp
      'isDeleted': isDeleted,
      'isStarred': isStarred,
    };
  }

  // Create a Note object from a database map
  factory Note.fromMap(Map<String, dynamic> map) {
    return Note(
      id: map['id'],
      title: map['title'],
      content: map['content'],
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp']),
      isDeleted: map['isDeleted'],
      isStarred: map.containsKey('isStarred') ? map['isStarred'] : 0,
    );
  }

  // Create a new note with empty rich text content
  factory Note.empty({DateTime? timestamp}) {
    final emptyDelta = Delta()..insert('\n');
    return Note(
      title: '',
      content: jsonEncode(emptyDelta.toJson()),
      timestamp: timestamp ?? DateTime.now(),
    );
  }

  @override
  String toString() {
    return 'Note(id: $id, title: $title, timestamp: $timestamp, isDeleted: $isDeleted, isStarred: $isStarred)';
  }
} 