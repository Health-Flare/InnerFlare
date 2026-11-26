import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inner_flare/core/security/db_passphrase_store.dart';

void main() {
  const keyName = 'inner_flare.db_passphrase';

  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  test('getOrCreate makes one key and then keeps returning it', () async {
    final store = DbPassphraseStore();
    final first = await store.getOrCreate();
    expect(await store.getOrCreate(), first);
    expect(await const FlutterSecureStorage().read(key: keyName), first);
  });

  test('delete removes the key, and the next getOrCreate makes a new '
      'one', () async {
    final store = DbPassphraseStore();
    final before = await store.getOrCreate();

    await store.delete();
    expect(await const FlutterSecureStorage().read(key: keyName), isNull);

    final after = await store.getOrCreate();
    expect(after, isNot(before));
  });

  test('delete with no key stored is fine', () async {
    await DbPassphraseStore().delete();
    expect(await const FlutterSecureStorage().read(key: keyName), isNull);
  });
}
