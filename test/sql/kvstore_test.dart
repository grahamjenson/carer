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

    test('insert and upsert', () async {
      await store.setString('key', 'value');
      expect(store.get('key'), 'value');

      await store.setString('key', 'value2');
      expect(store.get('key'), 'value2');
    });

    test('delete', () async {
      await store.setString('key', 'value');
      expect(store.get('key'), 'value');

      await store.delete('key');
      expect(store.get('key'), null);
    });

    test('deleteAll', () async {
      await store.setString('key', 'value');
      await store.setString('key2', 'value2');
      expect(store.get('key'), 'value');
      expect(store.get('key2'), 'value2');

      await store.deleteAll();
      expect(store.get('key'), null);
      expect(store.get('key2'), null);
    });

    test('getKeys', () async {
      await store.setString('key', 'value');
      await store.setString('key2', 'value2');
      expect(store.getKeys(), ['key', 'key2']);
    });
  });
}
