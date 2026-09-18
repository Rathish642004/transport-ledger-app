import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/bank_account.dart';
import '../providers/banks_provider.dart';
import '../router/app_router.dart';
import '../widgets/confirmation_dialog.dart';

/// New screen — not in the React source. Lists the transporter's own bank
/// accounts (see `BankAccount`'s doc comment), each linking through to a
/// per-account transaction history.
class BanksListScreen extends ConsumerStatefulWidget {
  const BanksListScreen({super.key});

  @override
  ConsumerState<BanksListScreen> createState() => _BanksListScreenState();
}

class _BanksListScreenState extends ConsumerState<BanksListScreen> {
  final _searchController = TextEditingController();
  String _search = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _handleDelete(BankAccount bank) async {
    final confirmed = await showConfirmationDialog(
      context,
      title: 'Remove Bank Account?',
      message: 'Remove "${bank.bankName} • ${bank.accountNumber}"? Past transactions recorded against it are kept, but it will no longer be selectable for new ones.',
      confirmLabel: 'Remove',
      isDestructive: true,
    );
    if (confirmed) {
      ref.read(banksProvider.notifier).deleteBankAccount(bank.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final banks = ref.watch(banksProvider);
    final q = _search.toLowerCase();
    final filtered = banks.where((b) => b.bankName.toLowerCase().contains(q) || b.accountNumber.contains(q)).toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('CASH & BANK ACCOUNTS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF0369A1))),
                Text('Your Bank Accounts', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
              ],
            ),
            FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: const Color(0xFF0369A1)),
              onPressed: () => context.push(AppRoutes.banksEdit),
              icon: const Icon(Icons.add, size: 14),
              label: const Text('Add Bank', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _searchController,
          onChanged: (v) => setState(() => _search = v),
          style: const TextStyle(fontSize: 12),
          decoration: InputDecoration(
            hintText: 'Search bank name or account number...',
            prefixIcon: const Icon(Icons.search, size: 18),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
          ),
        ),
        const SizedBox(height: 10),
        if (banks.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 32),
            child: Column(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: const BoxDecoration(color: Color(0xFFF1F5F9), shape: BoxShape.circle),
                  child: const Icon(Icons.account_balance_outlined, color: Color(0xFF94A3B8), size: 28),
                ),
                const SizedBox(height: 12),
                const Text('No Bank Accounts Yet', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 4),
                const Text(
                  'Add a bank account to track which account payments are received into and paid out from.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                ),
              ],
            ),
          )
        else
          for (final bank in filtered) ...[
            _BankCard(bank: bank, onDelete: () => _handleDelete(bank)),
            const SizedBox(height: 10),
          ],
      ],
    );
  }
}

class _BankCard extends StatelessWidget {
  const _BankCard({required this.bank, required this.onDelete});

  final BankAccount bank;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () => context.push(AppRoutes.bankTransactionsPath(bank.id)),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFE2E8F0))),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(color: const Color(0xFFE0F2FE), borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.account_balance_outlined, size: 18, color: Color(0xFF0369A1)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(bank.bankName, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                      Text(bank.accountHolderName, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: Colors.grey.shade400),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.only(top: 8),
              decoration: const BoxDecoration(border: Border(top: BorderSide(color: Color(0xFFF1F5F9)))),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(bank.accountNumber, style: const TextStyle(fontSize: 12, fontFamily: 'monospace', fontWeight: FontWeight.bold)),
                        Text('${bank.ifscCode} • ${bank.branchName}', style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8)), overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: () => context.push('${AppRoutes.banksEdit}?id=${bank.id}'),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(8)),
                          child: const Icon(Icons.edit_outlined, size: 14, color: Color(0xFF334155)),
                        ),
                      ),
                      const SizedBox(width: 6),
                      InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: onDelete,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(8)),
                          child: const Icon(Icons.delete_outline, size: 14, color: Color(0xFFDC2626)),
                        ),
                      ),
                    ],
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
