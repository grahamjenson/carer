class KVTables {
  static const kvTableName = 'kv';

  static const String kvTable = '''
    CREATE TABLE kv (
      k TEXT PRIMARY KEY NOT NULL,
      v TEXT,
      t TEXT
    )
  ''';
}

class KVQueries {
  static const String get = '''
    SELECT value FROM kv WHERE k = ?
  ''';

  static const String delete = '''
    DELETE FROM kv WHERE k = ?
  ''';

  static const String upsert = '''
    INSERT INTO kv (k, v, t) VALUES (?, ?, ?)
    ON CONFLICT(k) DO UPDATE SET v = ?, t = ?
  ''';
}
