import 'package:flutter/material.dart';

/// Ported from `src/components/common/FilterChips.tsx`.
class FilterOption<T> {
  const FilterOption({required this.id, required this.label, this.count});

  final T id;
  final String label;
  final int? count;
}

class FilterChips<T> extends StatelessWidget {
  const FilterChips({super.key, required this.options, required this.selectedId, required this.onSelect});

  final List<FilterOption<T>> options;
  final T selectedId;
  final ValueChanged<T> onSelect;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: options.length,
        separatorBuilder: (context, index) => const SizedBox(width: 6),
        itemBuilder: (context, index) {
          final opt = options[index];
          final isSelected = opt.id == selectedId;
          return InkWell(
            borderRadius: BorderRadius.circular(999),
            onTap: () => onSelect(opt.id),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF0369A1) : Colors.white,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: isSelected ? const Color(0xFF0369A1) : const Color(0xFFE2E8F0)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    opt.label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: isSelected ? Colors.white : const Color(0xFF334155),
                    ),
                  ),
                  if (opt.count != null) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFF075985) : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '${opt.count}',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? const Color(0xFFE0F2FE) : const Color(0xFF475569),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
