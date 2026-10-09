import 'package:shared_preferences/shared_preferences.dart';

import 'save_data.dart';

abstract interface class KeyValueStore {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> remove(String key);
}

class SharedPreferencesStore implements KeyValueStore {
  SharedPreferencesStore(this._preferences);

  final SharedPreferences _preferences;

  static Future<SharedPreferencesStore> create() async =>
      SharedPreferencesStore(await SharedPreferences.getInstance());

  @override
  Future<String?> read(String key) async => _preferences.getString(key);

  @override
  Future<void> write(String key, String value) async {
    await _preferences.setString(key, value);
  }

  @override
  Future<void> remove(String key) async {
    await _preferences.remove(key);
  }
}

class SaveLoadResult {
  const SaveLoadResult({required this.data, this.recovered = false, this.corruptDataDiscarded = false});

  final SaveData data;
  final bool recovered;
  final bool corruptDataDiscarded;
}

/// Primary+last-known-good storage. Every decode failure is contained and a
/// recovered/default profile replaces corrupt data on the next normal save.
class SaveRepository {
  SaveRepository(this._store);

  static const String primaryKey = 'orbit_hop_profile_v3';
  static const String backupKey = 'orbit_hop_profile_backup_v3';

  final KeyValueStore _store;

  Future<SaveLoadResult> load() async {
    final String? primary = await _store.read(primaryKey);
    final SaveData? primaryData = _tryDecode(primary);
    if (primaryData != null) return SaveLoadResult(data: primaryData);

    final String? backup = await _store.read(backupKey);
    final SaveData? backupData = _tryDecode(backup);
    if (backupData != null) {
      await _store.write(primaryKey, backupData.encode());
      return SaveLoadResult(data: backupData, recovered: true, corruptDataDiscarded: primary != null);
    }

    return SaveLoadResult(data: SaveData(), corruptDataDiscarded: primary != null || backup != null);
  }

  Future<void> save(SaveData data) async {
    final String? current = await _store.read(primaryKey);
    if (_tryDecode(current) != null) {
      await _store.write(backupKey, current!);
    }
    await _store.write(primaryKey, data.encode());
  }

  Future<void> clear() async {
    await _store.remove(primaryKey);
    await _store.remove(backupKey);
  }

  SaveData? _tryDecode(String? value) {
    if (value == null || value.isEmpty) return null;
    try {
      return SaveData.decode(value);
    } on FormatException {
      return null;
    } on TypeError {
      return null;
    } catch (_) {
      return null;
    }
  }
}

/// In-memory store used by unit tests and safe for deterministic simulations.
class MemoryKeyValueStore implements KeyValueStore {
  final Map<String, String> values = <String, String>{};

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async {
    values[key] = value;
  }

  @override
  Future<void> remove(String key) async {
    values.remove(key);
  }
}
