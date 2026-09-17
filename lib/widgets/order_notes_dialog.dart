import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/order.dart';
import '../providers/orders_provider.dart';

const _quickTags = [
  'Advance paid to driver',
  'Goods dispatched from mill',
  'Unloading in progress at mill',
  'Delivery completed & signed POD received',
  'Customer promised payment this week',
  'Detention charges applicable',
];

/// Ported from `src/components/orders/OrderNotesModal.tsx`.
///
/// Faithful quirk kept intentionally: like the original (whose `order` prop
/// is a snapshot captured when the modal was opened, not a live subscription
/// to the orders list), notes added during this dialog session are *not*
/// reflected in the "Notes History" list until the dialog is reopened — only
/// the request itself (`addOrderNote`) is live.
Future<void> showOrderNotesDialog(BuildContext context, WidgetRef ref, Order order) {
  return showDialog<void>(
    context: context,
    builder: (context) => _OrderNotesDialog(order: order, ref: ref),
  );
}

class _OrderNotesDialog extends StatefulWidget {
  const _OrderNotesDialog({required this.order, required this.ref});

  final Order order;
  final WidgetRef ref;

  @override
  State<_OrderNotesDialog> createState() => _OrderNotesDialogState();
}

class _OrderNotesDialogState extends State<_OrderNotesDialog> {
  final _newNoteController = TextEditingController();
  late final _fullNotesController = TextEditingController(text: widget.order.notes);
  bool _isEditingAllNotes = false;

  @override
  void dispose() {
    _newNoteController.dispose();
    _fullNotesController.dispose();
    super.dispose();
  }

  void _addQuickTag(String tag) {
    _newNoteController.text = _newNoteController.text.isEmpty ? tag : '${_newNoteController.text}, $tag';
    setState(() {});
  }

  void _saveNewNote() {
    final text = _newNoteController.text.trim();
    if (text.isEmpty) return;
    widget.ref.read(ordersProvider.notifier).addOrderNote(widget.order.id, text);
    _newNoteController.clear();
    setState(() {});
  }

  void _saveFullNotes() {
    final updated = widget.order.copyWith(notes: _fullNotesController.text);
    widget.ref.read(ordersProvider.notifier).updateOrder(widget.order.id, updated);
    setState(() => _isEditingAllNotes = false);
  }

  @override
  Widget build(BuildContext context) {
    final displayName = (widget.order.lrNumber?.isNotEmpty ?? false) ? widget.order.lrNumber! : widget.order.orderNumber;
    final noteLines = widget.order.notes.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty).toList();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480, maxHeight: 640),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0xFF0F172A),
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(color: const Color(0x330EA5E9), borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.sticky_note_2, size: 16, color: Color(0xFF7DD3FC)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Order Notes & Remarks', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14)),
                        Text('Order #$displayName', style: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 11, fontFamily: 'monospace')),
                      ],
                    ),
                  ),
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: const Icon(Icons.close, size: 18, color: Colors.white70),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        Text(
                          'Notes History (${noteLines.length})',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF334155)),
                        ),
                        TextButton.icon(
                          onPressed: () => setState(() => _isEditingAllNotes = !_isEditingAllNotes),
                          icon: const Icon(Icons.edit, size: 14),
                          label: Text(_isEditingAllNotes ? 'View Formatted' : 'Edit All Notes Directly', style: const TextStyle(fontSize: 11)),
                        ),
                      ],
                    ),
                    const Divider(height: 16),
                    if (_isEditingAllNotes) ...[
                      TextField(
                        controller: _fullNotesController,
                        maxLines: 6,
                        style: const TextStyle(fontSize: 12),
                        decoration: InputDecoration(
                          hintText: 'Enter or edit full order notes...',
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => setState(() {
                              _fullNotesController.text = widget.order.notes;
                              _isEditingAllNotes = false;
                            }),
                            child: const Text('Cancel'),
                          ),
                          const SizedBox(width: 8),
                          FilledButton.icon(
                            onPressed: _saveFullNotes,
                            icon: const Icon(Icons.save, size: 14),
                            label: const Text('Save Changes'),
                          ),
                        ],
                      ),
                    ] else if (noteLines.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(20),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE2E8F0), style: BorderStyle.solid),
                        ),
                        child: const Column(
                          children: [
                            Icon(Icons.description_outlined, size: 24, color: Color(0xFFCBD5E1)),
                            SizedBox(height: 4),
                            Text('No notes added to this order yet.', style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8), fontWeight: FontWeight.w600)),
                          ],
                        ),
                      )
                    else
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 180),
                        child: ListView.separated(
                          shrinkWrap: true,
                          itemCount: noteLines.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 6),
                          itemBuilder: (context, i) => _NoteLine(line: noteLines[i]),
                        ),
                      ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0F9FF),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFBAE6FD)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('+ Add a New Note / Trip Update', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Color(0xFF082F49))),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 4,
                            runSpacing: 4,
                            children: [
                              for (final tag in _quickTags)
                                InkWell(
                                  onTap: () => _addQuickTag(tag),
                                  borderRadius: BorderRadius.circular(8),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: const Color(0xFFBAE6FD)),
                                    ),
                                    child: Text('+ $tag', style: const TextStyle(fontSize: 10, color: Color(0xFF0C4A6E), fontWeight: FontWeight.w600)),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _newNoteController,
                                  onChanged: (_) => setState(() {}),
                                  onSubmitted: (_) => _saveNewNote(),
                                  style: const TextStyle(fontSize: 12),
                                  decoration: InputDecoration(
                                    hintText: 'Type note...',
                                    filled: true,
                                    fillColor: Colors.white,
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF7DD3FC))),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              FilledButton.icon(
                                onPressed: _newNoteController.text.trim().isEmpty ? null : _saveNewNote,
                                icon: const Icon(Icons.add, size: 14),
                                label: const Text('Add'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: Color(0xFFF8FAFC),
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Notes are saved to order record locally',
                      style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    style: FilledButton.styleFrom(backgroundColor: const Color(0xFF0F172A)),
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Done'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NoteLine extends StatelessWidget {
  const _NoteLine({required this.line});

  final String line;

  @override
  Widget build(BuildContext context) {
    final isTimestamped = line.startsWith('[');
    final closeBracket = line.indexOf(']');

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: isTimestamped && closeBracket != -1
          ? Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: line.substring(0, closeBracket + 1),
                    style: const TextStyle(
                      fontSize: 10,
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0369A1),
                      backgroundColor: Color(0xFFE0F2FE),
                    ),
                  ),
                  TextSpan(text: ' ${line.substring(closeBracket + 1)}'),
                ],
              ),
              style: const TextStyle(fontSize: 11, color: Color(0xFF1E293B), fontWeight: FontWeight.w500, height: 1.4),
            )
          : Text(line, style: const TextStyle(fontSize: 11, color: Color(0xFF1E293B), fontWeight: FontWeight.w500, height: 1.4)),
    );
  }
}
