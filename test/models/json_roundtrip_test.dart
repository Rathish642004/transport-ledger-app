import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/data/seed_data.dart';
import 'package:flutter_app/models/backup_sync_state.dart';
import 'package:flutter_app/models/company.dart';
import 'package:flutter_app/models/customer.dart';
import 'package:flutter_app/models/enums.dart';
import 'package:flutter_app/models/expense_record.dart';
import 'package:flutter_app/models/order.dart';
import 'package:flutter_app/models/payment_receipt.dart';
import 'package:flutter_app/models/transporter_profile.dart';

void main() {
  group('enums round-trip their exact React/TS string values', () {
    test('OrderStatus', () {
      for (final v in OrderStatus.values) {
        expect(OrderStatus.fromJson(v.toJson()), v);
      }
      expect(OrderStatus.inTransit.toJson(), 'In Transit');
    });

    test('PaymentStatus', () {
      for (final v in PaymentStatus.values) {
        expect(PaymentStatus.fromJson(v.toJson()), v);
      }
      expect(PaymentStatus.partiallyPaid.toJson(), 'Partially Paid');
    });

    test('PaymentMethod', () {
      for (final v in PaymentMethod.values) {
        expect(PaymentMethod.fromJson(v.toJson()), v);
      }
      expect(PaymentMethod.upi.toJson(), 'UPI');
    });

    test('PayerType', () {
      for (final v in PayerType.values) {
        expect(PayerType.fromJson(v.toJson()), v);
      }
    });

    test('ExpenseCategory', () {
      for (final v in ExpenseCategory.values) {
        expect(ExpenseCategory.fromJson(v.toJson()), v);
      }
      expect(ExpenseCategory.tollTax.toJson(), 'Toll / Tax');
      expect(ExpenseCategory.weighbridgeKaanta.toJson(), 'Weighbridge / Kaanta');
    });

    test('BackupFrequency', () {
      for (final v in BackupFrequency.values) {
        expect(BackupFrequency.fromJson(v.toJson()), v);
      }
    });

    test('SyncStatus', () {
      for (final v in SyncStatus.values) {
        expect(SyncStatus.fromJson(v.toJson()), v);
      }
    });
  });

  group('model toJson/fromJson round-trips against seed data', () {
    test('Order (including nested charges/expenses/billing/financialSummary)', () {
      for (final order in initialOrders) {
        final json = order.toJson();
        final restored = Order.fromJson(json);
        expect(restored.toJson(), json, reason: 'order ${order.id}');
      }
    });

    test('Company', () {
      for (final company in initialCompanies) {
        expect(Company.fromJson(company.toJson()).toJson(), company.toJson());
      }
    });

    test('Customer', () {
      for (final customer in initialCustomers) {
        expect(Customer.fromJson(customer.toJson()).toJson(), customer.toJson());
      }
    });

    test('PaymentReceipt', () {
      for (final receipt in initialPaymentReceipts) {
        expect(PaymentReceipt.fromJson(receipt.toJson()).toJson(), receipt.toJson());
      }
    });

    test('ExpenseRecord', () {
      for (final expense in initialExpenses) {
        expect(ExpenseRecord.fromJson(expense.toJson()).toJson(), expense.toJson());
      }
    });

    test('TransporterProfile', () {
      expect(TransporterProfile.fromJson(initialProfile.toJson()).toJson(), initialProfile.toJson());
    });

    test('BackupSyncState', () {
      expect(BackupSyncState.fromJson(initialBackupSettings.toJson()).toJson(), initialBackupSettings.toJson());
    });
  });

  group('copyWith', () {
    test('Order.copyWith overrides only the given fields', () {
      final order = initialOrders.first;
      final updated = order.copyWith(orderStatus: OrderStatus.cancelled, amountReceived: 999);
      expect(updated.orderStatus, OrderStatus.cancelled);
      expect(updated.amountReceived, 999);
      expect(updated.id, order.id);
      expect(updated.orderNumber, order.orderNumber);
      expect(updated.charges.toJson(), order.charges.toJson());
    });
  });
}
