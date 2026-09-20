import 'package:flutter/material.dart';

/// New — not in the source. `BillPreviewScreen`'s "Share" action used to
/// always send a plain WhatsApp-formatted text message. Now it can also hand
/// over the actual bill PDF, so this asks which one the user wants first.
enum ShareFormat { text, pdf }

Future<ShareFormat?> showShareFormatDialog(BuildContext context) {
  return showDialog<ShareFormat>(
    context: context,
    builder: (context) {
      return Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0xFFECFDF5),
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(color: const Color(0xFFD1FAE5), borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.share_outlined, color: Color(0xFF059669), size: 18),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Share Bill', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF064E3B))),
                        Text('Choose what to send', style: TextStyle(fontSize: 11, color: Color(0xFF047857))),
                      ],
                    ),
                  ),
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: const Icon(Icons.close, size: 18, color: Color(0xFF6EE7B7)),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _FormatOption(
                    icon: Icons.picture_as_pdf_outlined,
                    iconColor: const Color(0xFFDC2626),
                    iconBg: const Color(0xFFFEE2E2),
                    title: 'Share as PDF',
                    subtitle: 'Sends the formatted bill document',
                    onTap: () => Navigator.of(context).pop(ShareFormat.pdf),
                  ),
                  const SizedBox(height: 10),
                  _FormatOption(
                    icon: Icons.chat_outlined,
                    iconColor: const Color(0xFF0369A1),
                    iconBg: const Color(0xFFE0F2FE),
                    title: 'Share as Text',
                    subtitle: 'Sends a WhatsApp-formatted message',
                    onTap: () => Navigator.of(context).pop(ShareFormat.text),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    },
  );
}

class _FormatOption extends StatelessWidget {
  const _FormatOption({required this.icon, required this.iconColor, required this.iconBg, required this.title, required this.subtitle, required this.onTap});

  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, size: 20, color: iconColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Color(0xFF0F172A))),
                  Text(subtitle, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, size: 18, color: Color(0xFF94A3B8)),
          ],
        ),
      ),
    );
  }
}
