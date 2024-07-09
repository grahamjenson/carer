import 'package:carer/utils/futures.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:signals/signals_flutter.dart';

enum _SSNames { nightscoutUrl }

class SecureSettings {
  static final SecureSettings _singleton = SecureSettings._();
  factory SecureSettings() => _singleton;

  final Map<_SSNames, Signal> _signals = {
    _SSNames.nightscoutUrl: Signal<String?>(null, debugLabel: 'nightscoutUrl'),
  };

  late Computed<(String, String)> _nightscoutURLAndTokenSignal;
  late FlutterSecureStorage store;

  SecureSettings._() {
    store = const FlutterSecureStorage(
        aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ));

    _nightscoutURLAndTokenSignal = acomputed(() {
      if (nightscoutURL == null || nightscoutURL!.isEmpty) {
        return ('', '');
      }

      var uri = Uri.parse(nightscoutURL!);
      var token = uri.queryParameters["token"];
      token ??= '';
      var base = '${uri.scheme}://${uri.host}';
      return (base.toString(), token);
    }, ('', ''), debugLabel: 'nightscoutURLAndToken');
  }

  String? get nightscoutURL => _signals[_SSNames.nightscoutUrl]!.value as String?;
  set nightscoutURL(String? value) => _signals[_SSNames.nightscoutUrl]!.value = value;

  (String, String) get nightscoutURLAndToken => _nightscoutURLAndTokenSignal.value;

  setupDBPropagation() async {
    nightscoutURL = await store.read(key: _SSNames.nightscoutUrl.name);

    aeffect(() {
      if (nightscoutURL == null) {
        return;
      }
      store.write(key: _SSNames.nightscoutUrl.name, value: nightscoutURL!);
    });
  }
}
