// test the KeyValueStore that it inserts and upserts data

import 'package:carer/sql/key_value_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Initialize sqflite for test.
void sqfliteTestInit() {
  // Initialize ffi implementation
  sqfliteFfiInit();
  // Set global factory
  databaseFactory = databaseFactoryFfi;
}

void main() {
  sqfliteTestInit();

  group('KeyValueStore', () {
    late KeyValueStore store;

    setUp(() async {
      store = await KeyValueStore.create();
    });

    tearDown(() async {
      await store.deleteAll();
      await store.close();
    });

    test("populate from clean cache", () async {
      expect(store.count(), 0);
      await store.setString("a", 'x');
      expect(store.get('a'), 'x');
      await store.reloadCache();
      expect(store.get('a'), 'x');
    });

    test('insert and upsert', () async {
      await store.setString('a', 'x');
      expect(store.get('a'), 'x');

      await store.setString('a', 'y');
      expect(store.get('a'), 'y');
    });

    test('delete', () async {
      await store.setString('a', 'x');
      expect(store.get('a'), 'x');

      await store.delete('a');
      expect(store.get('a'), null);
    });

    test('deleteAll', () async {
      await store.setString('a', 'x');
      await store.setString('b', 'y');
      expect(store.get('a'), 'x');
      expect(store.get('b'), 'y');

      await store.deleteAll();
      expect(store.get('a'), null);
      expect(store.get('b'), null);
    });

    test('getKeys', () async {
      await store.setString('a', 'x');
      await store.setString('b', 'y');
      expect(store.getKeys(), ['a', 'b']);
    });

    // Test all the types work
    test('storing bool', () async {
      await store.setBool('a', true);
      expect(store.getBool('a'), true);
      await store.reloadCache();
      expect(store.getBool('a'), true);
    });

    test('storing int', () async {
      await store.setInt('a', 1);
      expect(store.getInt('a'), 1);
      await store.reloadCache();
      expect(store.getInt('a'), 1);
    });

    test('storing double', () async {
      await store.setDouble('a', 1.1);
      expect(store.getDouble('a'), 1.1);
      await store.reloadCache();
      expect(store.getDouble('a'), 1.1);
    });

    test('storing String', () async {
      await store.setString('a', 'x');
      expect(store.getString('a'), 'x');
      await store.reloadCache();
      expect(store.getString('a'), 'x');
    });
  });
}
