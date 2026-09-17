import 'package:hive_ce/hive_ce.dart';

import 'backup_sync_state.dart';
import 'company.dart';
import 'customer.dart';
import 'driver.dart';
import 'driver_payment_record.dart';
import 'enums.dart';
import 'expense_record.dart';
import 'order.dart';
import 'payment_receipt.dart';
import 'transporter_profile.dart';

// Type IDs are assigned in list order below. DO NOT reorder or remove
// entries once real data exists on-device — append new types at the end.
@GenerateAdapters([
  AdapterSpec<OrderStatus>(),
  AdapterSpec<PaymentStatus>(),
  AdapterSpec<DriverPaymentStatus>(),
  AdapterSpec<PaymentMethod>(),
  AdapterSpec<PayerType>(),
  AdapterSpec<ExpenseCategory>(),
  AdapterSpec<BackupFrequency>(),
  AdapterSpec<SyncStatus>(),
  AdapterSpec<OrderNoteItem>(),
  AdapterSpec<OrderCharges>(),
  AdapterSpec<DriverExpense>(),
  AdapterSpec<BillingDetails>(),
  AdapterSpec<FinancialSummary>(),
  AdapterSpec<Order>(),
  AdapterSpec<Company>(),
  AdapterSpec<Customer>(),
  AdapterSpec<Driver>(),
  AdapterSpec<PaymentReceipt>(),
  AdapterSpec<DriverPaymentRecord>(),
  AdapterSpec<ExpenseRecord>(),
  AdapterSpec<TransporterProfile>(),
  AdapterSpec<BackupSyncState>(),
])
part 'hive_adapters.g.dart';
