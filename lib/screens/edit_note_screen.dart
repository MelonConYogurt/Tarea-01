import 'package:flutter/material.dart';
import '../models/note.dart';

class EditNoteScreen extends StatefulWidget {
  final Note? note;
  const EditNoteScreen({Key? key, this.note}) : super(key: key);

  @override
  State<EditNoteScreen> createState() => _EditNoteScreenState();
}

class _EditNoteScreenState extends State<EditNoteScreen> {
  late TextEditingController _titleController;
  late TextEditingController _contentController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.note?.title ?? '');
    _contentController = TextEditingController(text: widget.note?.content ?? '');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userId = ModalRoute.of(context)?.settings.arguments as String? ?? '';
    return Scaffold(
      appBar: AppBar(title: Text(widget.note == null ? 'Nueva Nota' : 'Editar Nota')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Título'),
            ),
            TextField(
              controller: _contentController,
              decoration: const InputDecoration(labelText: 'Contenido'),
              maxLines: 8,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                final note = Note(
                  id: widget.note?.id,
                  userId: widget.note?.userId ?? userId,
                  title: _titleController.text,
                  content: _contentController.text,
                  createdAt: widget.note?.createdAt ?? DateTime.now(),
                  updatedAt: DateTime.now(),
                );
                Navigator.pop(context, note);
              },
              child: Text(widget.note == null ? 'Crear' : 'Guardar'),
            ),
          ],
        ),
      ),
    );
  }
}
