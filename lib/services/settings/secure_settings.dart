import 'package:carer/utils/futures.dart';
import 'package:carer/utils/logs.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

enum _SSNames { nightscoutUrl, nightscoutToken }

class SecureSettings {
  static final SecureSettings _singleton = SecureSettings._();
  factory SecureSettings() => _singleton;

  final Map<_SSNames, ASignal> _signals = {
    _SSNames.nightscoutUrl: ASignal<String?>(null, debugLabel: 'nightscoutUrl'),
    _SSNames.nightscoutToken: ASignal<String?>(null, debugLabel: 'nightscoutToken'),
  };

  late FlutterSecureStorage store;

  SecureSettings._() {
    store = const FlutterSecureStorage(
        aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ));
  }

  String? get nightscoutURL => _signals[_SSNames.nightscoutUrl]!.value as String?;
  set nightscoutURL(String? value) {
    if (value != null) {
      ALogger().addCensoredString("NS_URL", value);
    }
    _signals[_SSNames.nightscoutUrl]!.value = value;
  }

  String? get nightscoutToken => _signals[_SSNames.nightscoutToken]!.value as String?;
  set nightscoutToken(String? value) {
    if (value != null) {
      ALogger().addCensoredString("NS_TOKEN", value);
    }

    _signals[_SSNames.nightscoutToken]!.value = value;
  }

  (String, String) get nightscoutURLAndToken {
    return (nightscoutURL ?? "", nightscoutToken ?? "");
  }

  setupDBPropagation() async {
    // https://github.com/mogol/flutter_secure_storage/issues/709
    // read errors, read all doesn't
    final allKeys = await store.readAll();
    nightscoutURL = allKeys[_SSNames.nightscoutUrl.name];
    nightscoutToken = allKeys[_SSNames.nightscoutToken.name];

    aeffect(() {
      if (nightscoutURL == null) {
        return;
      }

      store.write(key: _SSNames.nightscoutUrl.name, value: nightscoutURL!);
    });

    aeffect(() {
      if (nightscoutToken == null) {
        return;
      }

      store.write(key: _SSNames.nightscoutToken.name, value: nightscoutToken!);
    });
  }
}
