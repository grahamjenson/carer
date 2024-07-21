class SQLRow {
  String table;
  final Map<String, Object?> _attributes;

  SQLRow(this.table, this._attributes);

  Object? operator [](String key) => _attributes[key];

  List<String> validateRequiredAttributes(List<String> keys) {
    List<String> errors = [];
    for (var key in keys) {
      if (_attributes[key] == null) {
        errors.add("Missing Key $key");
      }
    }
    return errors;
  }

  List<String> validateTypes(List<(String, Type)> keysTypes) {
    List<String> errors = [];
    for (var i = 0; i < keysTypes.length; i++) {
      var (key, type) = keysTypes[i];
      if (_attributes[key] == null) {
        continue; // Ignore if null
      }
      if (_attributes[key].runtimeType != type) {
        errors.add("Mismatched Type $key ${_attributes[key].runtimeType} $type");
      }
    }
    return errors;
  }

  Map<String, Object> toCleanMap() {
    return _attributes.map((key, value) {
      if (value != null) {
        return MapEntry(key, value);
      } else {
        return MapEntry(key, value);
      }
    }).cast<String, Object>();
  }
}
