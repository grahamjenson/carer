// test the KeyValueStore that it inserts and upserts data

import 'package:carer/sql/key_value_store.dart';
import 'package:flutter_test/flutter_test.dart';

import '../test_utils.dart';

/// Initialize sqflite for test.

void main() async {
  await sqfliteTestInit();

  group('KeyValueStore', () {
    late KeyValueStore store;

    setUp(() async {
      store = await KeyValueStore.instance;
    });

    tearDown(() async {
      await store.deleteAll();
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
      expect(store.getBool('a'), null);
      expect(store.getBool('a', defaultValue: true), true);
      expect(store.getBool('a', defaultValue: false), false);

      await store.setBool('a', true);
      expect(store.getBool('a'), true);
      await store.reloadCache();
      expect(store.getBool('a'), true);
    });

    test('storing int', () async {
      expect(store.getInt('a'), null);
      expect(store.getInt('a', defaultValue: 3), 3);

      await store.setInt('a', 1);
      expect(store.getInt('a'), 1);
      await store.reloadCache();
      expect(store.getInt('a'), 1);
    });

    test('storing double', () async {
      expect(store.getDouble('a'), null);
      expect(store.getDouble('a', defaultValue: 1.5), 1.5);

      await store.setDouble('a', 1.1);
      expect(store.getDouble('a'), 1.1);
      await store.reloadCache();
      expect(store.getDouble('a'), 1.1);
    });

    test('storing String', () async {
      expect(store.getString('a'), null);
      expect(store.getString('a', defaultValue: "z"), 'z');

      await store.setString('a', 'x');
      expect(store.getString('a'), 'x');
      await store.reloadCache();
      expect(store.getString('a'), 'x');
    });
  });
}
