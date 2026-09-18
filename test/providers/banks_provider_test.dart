import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_app/providers/banks_provider.dart';

import '../test_helpers/hive_test_env.dart';

void main() {
  late Directory tempDir;
  late ProviderContainer container;

  setUp(() async {
    tempDir = await openTestHive();
    container = ProviderContainer();
  });

  tearDown(() async {
    container.dispose();
    await closeTestHive(tempDir);
  });

  test('saveBankAccount with no id adds a new account', () {
    final account = container.read(banksProvider.notifier).saveBankAccount(
          bankName: 'HDFC Bank',
          accountHolderName: 'Kalavathi Selvaraj',
          accountNumber: '1234567890',
          ifscCode: 'HDFC0001234',
          branchName: 'Dindigul Branch',
        );

    expect(account.id, isNotEmpty);
    expect(container.read(banksProvider), contains(account));
  });

  test('saveBankAccount with an id edits the existing account in place', () {
    final notifier = container.read(banksProvider.notifier);
    final created = notifier.saveBankAccount(
      bankName: 'HDFC Bank',
      accountHolderName: 'Kalavathi Selvaraj',
      accountNumber: '1234567890',
      ifscCode: 'HDFC0001234',
      branchName: 'Dindigul Branch',
    );

    final updated = notifier.saveBankAccount(
      id: created.id,
      bankName: 'HDFC Bank Ltd',
      accountHolderName: 'Kalavathi Selvaraj',
      accountNumber: '1234567890',
      ifscCode: 'HDFC0001234',
      branchName: 'Dindigul Branch',
    );

    expect(container.read(banksProvider).length, 1);
    expect(updated.bankName, 'HDFC Bank Ltd');
    expect(updated.id, created.id);
  });

  test('deleteBankAccount removes it from state and the box', () {
    final notifier = container.read(banksProvider.notifier);
    final created = notifier.saveBankAccount(
      bankName: 'HDFC Bank',
      accountHolderName: 'Kalavathi Selvaraj',
      accountNumber: '1234567890',
      ifscCode: 'HDFC0001234',
      branchName: 'Dindigul Branch',
    );

    notifier.deleteBankAccount(created.id);

    expect(container.read(banksProvider), isEmpty);
  });
}
