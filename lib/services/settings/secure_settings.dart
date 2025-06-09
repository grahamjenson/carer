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

  List<ASignal> allSignals() {
    return _signals.values.toList();
  }

  SecureSettings._() {
    store = const FlutterSecureStorage(
        aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ));
  }

  (String, String) nightscoutURLAndTokenFromString(String url) {
    var uri = Uri.parse(url);
    var token = uri.queryParameters["token"];
    token ??= '';
    var base = '${uri.scheme}://${uri.host}';

    return (base.toString(), token);
  }

  void setNSValuesFromURL(String url) {
    var (base, token) = nightscoutURLAndTokenFromString(url);
    nightscoutURL = base;
    nightscoutToken = token;
  }

  String? get nightscoutURL => _signals[_SSNames.nightscoutUrl]!.value as String?;
  set nightscoutURL(String? value) {
    if (value != null && value.isNotEmpty && value.length > 8) {
      ALogger().addCensoredString("NS_URL", value);
      Uri? uri = Uri.tryParse(value);
      if (uri != null) {
        ALogger().addCensoredString("NS_HOST", uri.host);
      }
      _signals[_SSNames.nightscoutUrl]!.value = value;
    }
  }

  String? get nightscoutToken => _signals[_SSNames.nightscoutToken]!.value as String?;
  set nightscoutToken(String? value) {
    if (value != null && value.isNotEmpty && value.length > 8) {
      ALogger().addCensoredString("NS_TOKEN", value);
      _signals[_SSNames.nightscoutToken]!.value = value;
    }
  }

  (String, String) get nightscoutURLAndToken {
    return (nightscoutURL ?? "", nightscoutToken ?? "");
  }

  String? get nightscoutURLWithToken {
    if (nightscoutURL == null || nightscoutURL!.isEmpty) {
      return null;
    }
    if (nightscoutToken == null || nightscoutToken!.isEmpty) {
      return null;
    }
    return "$nightscoutURL?token=$nightscoutToken";
  }

  bool nightscoutURLAndTokenSet() {
    return nightscoutURL != null && nightscoutToken != null && nightscoutURL!.isNotEmpty && nightscoutToken!.isNotEmpty;
  }

  setupDBPropagation() async {
    // https://github.com/mogol/flutter_secure_storage/issues/709
    // read errors, read all doesn't
    final allKeys = await store.readAll();
    nightscoutURL = allKeys[_SSNames.nightscoutUrl.name];
    nightscoutToken = allKeys[_SSNames.nightscoutToken.name];

    aeffect(() {
      if (nightscoutURL == null || nightscoutURL!.isEmpty || nightscoutURL!.length < 8) {
        return;
      }

      store.write(key: _SSNames.nightscoutUrl.name, value: nightscoutURL!);
    }, debugLabel: 'writeNightscoutURL');

    aeffect(() {
      if (nightscoutToken == null || nightscoutToken!.isEmpty || nightscoutToken!.length < 8) {
        return;
      }

      store.write(key: _SSNames.nightscoutToken.name, value: nightscoutToken!);
    }, debugLabel: 'writeNightscoutToken');
  }

  debugDeleteNSValues() {
    _signals[_SSNames.nightscoutToken]!.value = null;
    _signals[_SSNames.nightscoutUrl]!.value = null;
    store.delete(key: _SSNames.nightscoutUrl.name);
    store.delete(key: _SSNames.nightscoutToken.name);
  }
}
