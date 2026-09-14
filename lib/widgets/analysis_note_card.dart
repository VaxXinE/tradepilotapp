import 'package:flutter/material.dart';
import '../l10n/l10n.dart';

class AnalysisNoteCard extends StatefulWidget {
  const AnalysisNoteCard({
    super.key,
    required this.note,
    required this.isSaving,
    required this.onSave,
  });

  final String? note;
  final bool isSaving;
  final Future<bool> Function(String note) onSave;

  @override
  State<AnalysisNoteCard> createState() => _AnalysisNoteCardState();
}

class _AnalysisNoteCardState extends State<AnalysisNoteCard> {
  late final TextEditingController _controller;
  bool _editing = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.note ?? '');
  }

  @override
  void didUpdateWidget(covariant AnalysisNoteCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_editing && oldWidget.note != widget.note) {
      _controller.text = widget.note ?? '';
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save(String value) async {
    if (value.length > 5000 || widget.isSaving) return;
    final success = await widget.onSave(value);
    if (mounted && success) setState(() => _editing = false);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.menu_book_outlined),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    context.l10n.personalNote,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
                if (!_editing)
                  IconButton(
                    tooltip: widget.note == null
                        ? context.l10n.addNote
                        : context.l10n.edit,
                    onPressed: () => setState(() => _editing = true),
                    icon: const Icon(Icons.edit_outlined),
                  ),
              ],
            ),
            Text(
              context.l10n.notePrivateHint,
              style: const TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 12),
            if (_editing) ...[
              TextField(
                controller: _controller,
                enabled: !widget.isSaving,
                minLines: 3,
                maxLines: 7,
                maxLength: 5000,
                decoration: InputDecoration(
                  hintText: context.l10n.noteHint,
                  border: const OutlineInputBorder(),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: widget.isSaving
                        ? null
                        : () {
                            _controller.text = widget.note ?? '';
                            setState(() => _editing = false);
                          },
                    child: Text(context.l10n.cancel),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: widget.isSaving
                        ? null
                        : () => _save(_controller.text),
                    child: widget.isSaving
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(context.l10n.save),
                  ),
                ],
              ),
            ] else if (widget.note?.trim().isNotEmpty == true) ...[
              Text(widget.note!, style: const TextStyle(height: 1.5)),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: widget.isSaving ? null : () => _save(''),
                  icon: const Icon(Icons.delete_outline),
                  label: Text(context.l10n.deleteNote),
                ),
              ),
            ] else
              Text(context.l10n.noNoteYet),
          ],
        ),
      ),
    );
  }
}
