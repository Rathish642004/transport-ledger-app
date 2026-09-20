import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive_ce.dart';

import 'package:flutter_app/models/company.dart';
import 'package:flutter_app/models/hive_registrar.g.dart';
import 'package:flutter_app/storage/ordered_box.dart';

Company _c(String id) => Company(
      id: id, name: id, contactPerson: 'x', phone: '0', address: 'x', city: 'x',
    );

void main() {
  late Directory tempDir;
  late Box<Company> dataBox;
  late Box<List> orderBox;
  late OrderedBoxIndex<Company> index;
  // `Hive`'s adapter registry is a process-wide singleton; registering more
  // than once across tests in this isolate throws — register once.
  var adaptersRegistered = false;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('tl_ordered_box_test_');
    Hive.init(tempDir.path);
    if (!adaptersRegistered) {
      Hive.registerAdapters();
      adaptersRegistered = true;
    }
    dataBox = await Hive.openBox<Company>('data');
    orderBox = await Hive.openBox<List>('order');
    index = OrderedBoxIndex<Company>(dataBox: dataBox, orderBox: orderBox, orderKey: 'k', idOf: (c) => c.id);
  });

  tearDown(() async {
    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  test('write persists both records and their order; read reconstructs that exact order', () {
    index.write([_c('c-162'), _c('c-161'), _c('c-160'), _c('c-159'), _c('c-163')]);

    // Confirms the underlying box really would be key-sorted without the index.
    expect(dataBox.values.map((c) => c.id).toList(), ['c-159', 'c-160', 'c-161', 'c-162', 'c-163']);

    expect(index.read().map((c) => c.id).toList(), ['c-162', 'c-161', 'c-160', 'c-159', 'c-163']);
  });

  test('a newly-prepended item stays first after re-reading (simulates app restart)', () {
    index.write([_c('c-162'), _c('c-161'), _c('c-160'), _c('c-159'), _c('c-163')]);

    final reread = index.read();
    final withNew = [_c('c-NEW'), ...reread];
    index.write(withNew);

    // Simulate reopening the box fresh: a brand new OrderedBoxIndex instance
    // over the same underlying boxes should reconstruct the same order.
    final reopened = OrderedBoxIndex<Company>(dataBox: dataBox, orderBox: orderBox, orderKey: 'k', idOf: (c) => c.id);
    expect(reopened.read().map((c) => c.id).toList(), ['c-NEW', 'c-162', 'c-161', 'c-160', 'c-159', 'c-163']);
  });

  test('delete removes the record and drops it from the stored order', () {
    index.write([_c('c-162'), _c('c-161'), _c('c-160')]);
    index.delete('c-161');

    expect(index.read().map((c) => c.id).toList(), ['c-162', 'c-160']);
    expect(dataBox.containsKey('c-161'), isFalse);
  });

  test('records present in the data box but missing from the order index are appended', () {
    // Simulates data written directly to the box without going through the
    // index (e.g. first-launch seeding before the order box existed).
    dataBox.put('c-a', _c('c-a'));
    dataBox.put('c-b', _c('c-b'));
    orderBox.put('k', ['c-b']);

    // 'c-b' is in the stored order; 'c-a' isn't, so it's appended.
    expect(index.read().map((c) => c.id).toList(), ['c-b', 'c-a']);
  });

  test('clear empties both the records and the stored order', () async {
    index.write([_c('c-1'), _c('c-2')]);
    await index.clear();

    expect(index.read(), isEmpty);
    expect(dataBox.isEmpty, isTrue);
    expect(orderBox.get('k'), isNull);
  });
}
