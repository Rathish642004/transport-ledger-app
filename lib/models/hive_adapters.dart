import 'package:hive_ce/hive_ce.dart';

import 'backup_sync_state.dart';
import 'bank_account.dart';
import 'company.dart';
import 'customer.dart';
import 'enums.dart';
import 'expense_record.dart';
import 'order.dart';
import 'payment_allocation.dart';
import 'payment_receipt.dart';
import 'transporter_profile.dart';

// Type IDs and field indexes are pinned by name in hive_adapters.g.yaml, so
// removing an entry here does NOT renumber the survivors (verified against
// that file before making this change) — but still only ever APPEND newly
// added types, never reuse a retired id/index.
@GenerateAdapters([
  AdapterSpec<OrderStatus>(),
  AdapterSpec<PaymentStatus>(),
  AdapterSpec<PaymentMethod>(),
  AdapterSpec<PayerType>(),
  AdapterSpec<ExpenseCategory>(),
  AdapterSpec<BackupFrequency>(),
  AdapterSpec<SyncStatus>(),
  AdapterSpec<OrderNoteItem>(),
  AdapterSpec<OrderCharges>(),
  AdapterSpec<BillingDetails>(),
  AdapterSpec<FinancialSummary>(),
  AdapterSpec<Order>(),
  AdapterSpec<Company>(),
  AdapterSpec<Customer>(),
  AdapterSpec<PaymentReceipt>(),
  AdapterSpec<ExpenseRecord>(),
  AdapterSpec<TransporterProfile>(),
  AdapterSpec<BackupSyncState>(),
  AdapterSpec<BankAccount>(),
  AdapterSpec<OrderExpenses>(),
  AdapterSpec<PaymentAllocation>(),
])
part 'hive_adapters.g.dart';
