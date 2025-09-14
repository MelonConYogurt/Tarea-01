import 'package:flutter/material.dart';
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/note.dart';
import '../data/notes_database.dart';
import 'edit_note_screen.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../services/sync_service.dart';
import '../services/firestore_notes_service.dart';

class NotesScreen extends StatefulWidget {
  const NotesScreen({Key? key}) : super(key: key);

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  StreamSubscription<ConnectivityResult>? _connSub;
  ConnectivityResult? _lastConnectivity;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _connSub ??= Connectivity().onConnectivityChanged.listen((result) {
      final wasOffline = _lastConnectivity == null || _lastConnectivity == ConnectivityResult.none;
      _lastConnectivity = result;
      if (result != ConnectivityResult.none && wasOffline) {
        SyncService.syncNotes().whenComplete(() {
          if (mounted) {
            _loadNotes();
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _connSub?.cancel();
    super.dispose();
  }
  List<Note> _notes = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  Future<void> _loadNotes() async {
  setState(() { _loading = true; });
  final currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';
  _notes = await NotesDatabase.getNotesForUser(currentUid);
  if (mounted) {
    setState(() {}); 
  }
  try {
    final connectivity = await Connectivity().checkConnectivity();
    if (connectivity != ConnectivityResult.none) {
      final user = FirebaseAuth.instance.currentUser;
      final token = await user?.getIdToken();
      if (token != null) {
        final remoteNotes = await FirestoreNotesService.fetchNotes();
        for (final rn in remoteNotes) {
          await NotesDatabase.upsertFromFirestore(rn);
        }
        final refreshed = await NotesDatabase.getNotesForUser(user?.uid ?? '');
        setState(() { _notes = refreshed; });
      }
    }
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo cargar del servidor: $e')),
      );
    }
  }
  setState(() { _loading = false; });
  }

  Future<void> _addOrEditNote([Note? note]) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditNoteScreen(note: note),
        settings: RouteSettings(arguments: FirebaseAuth.instance.currentUser?.uid ?? ''),
      ),
    );
    if (result is! Note) return;

    final currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';
    Note localNote = Note(
      id: result.id,
      userId: currentUid,
      title: result.title,
      content: result.content,
      createdAt: result.createdAt,
      updatedAt: result.updatedAt,
    );

    if (note == null) {
      final insertedId = await NotesDatabase.insertNote(localNote);
      localNote = Note(
        id: insertedId,
        remoteKey: localNote.remoteKey,
        userId: localNote.userId,
        title: localNote.title,
        content: localNote.content,
        createdAt: localNote.createdAt,
        updatedAt: localNote.updatedAt,
      );
    } else {
      await NotesDatabase.updateNote(localNote);
    }

    try {
      final connectivity = await Connectivity().checkConnectivity();
      if (connectivity != ConnectivityResult.none) {
        final user = FirebaseAuth.instance.currentUser;
        final token = await user?.getIdToken();
        if (token != null) {
          if (note == null) {
            final created = await FirestoreNotesService.createNote(localNote);
            final createdLocal = Note(
              id: localNote.id,
              remoteKey: created.remoteKey,
                userId: user?.uid ?? localNote.userId,
              title: created.title,
              content: created.content,
              createdAt: created.createdAt,
              updatedAt: created.updatedAt,
            );
            await NotesDatabase.updateNote(createdLocal);
          } else {
            final updated = await FirestoreNotesService.updateNote(localNote);
            final updatedLocal = Note(
              id: localNote.id,
              remoteKey: updated.remoteKey,
                userId: user?.uid ?? localNote.userId,
              title: updated.title,
              content: updated.content,
              createdAt: updated.createdAt,
              updatedAt: updated.updatedAt,
            );
            await NotesDatabase.updateNote(updatedLocal);
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo sincronizar: $e')),
        );
      }
    }

    await _loadNotes();
  }

  Future<void> _deleteNote(int id) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      final token = await user?.getIdToken();
      if (token != null) {
        final note = _notes.firstWhere((n) => n.id == id);
        await FirestoreNotesService.deleteNote(note);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo eliminar en servidor: $e')),
        );
      }
    }
    await NotesDatabase.deleteNote(id);
    await _loadNotes();
  }

  @override
  Widget build(BuildContext context) {
  final user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Notas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _notes.isEmpty
              ? Center(child: Text('No tienes notas aún.'))
              : ListView.builder(
                  itemCount: _notes.length,
                  itemBuilder: (context, index) {
                    final note = _notes[index];
                    return ListTile(
                      title: Text(note.title),
                      subtitle: Text(note.content),
                      onTap: () => _addOrEditNote(note),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () => _deleteNote(note.id!),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addOrEditNote(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
