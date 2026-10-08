// test/auth_notifier_test.dart

import 'package:flutter_application_1/models/app_user.dart';
import 'package:flutter_test/flutter_test.dart';

// Для тестов создаём минимальную заглушку AuthApi. Она не делает
// сетевых запросов и нужна только чтобы конструктор не падал.

// Хелпер: создаёт клиента с заданной ролью.
AppUser _u(Role r) => AppUser(id: 1, username: 'u', fullName: 'Test', role: r);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Role', () {
    test('reader не имеет доступ к master-операциям', () {
      expect(_u(Role.reader).role.level >= Role.master.level, isFalse);
    });

    test('master имеет доступ к master-операциям', () {
      expect(_u(Role.master).role.level >= Role.master.level, isTrue);
    });

    test('master не имеет доступ к admin-операциям', () {
      expect(_u(Role.master).role.level >= Role.admin.level, isFalse);
    });

    test('admin имеет доступ ко всем операциям', () {
      expect(_u(Role.admin).role.level >= Role.reader.level, isTrue);
      expect(_u(Role.admin).role.level >= Role.master.level, isTrue);
      expect(_u(Role.admin).role.level >= Role.admin.level, isTrue);
    });

    test('Role.fromString корректно разбирает строки', () {
      expect(Role.fromString('admin'), Role.admin);
      expect(Role.fromString('master'), Role.master);
      expect(Role.fromString('reader'), Role.reader);
      expect(Role.fromString(null), Role.reader);
      expect(Role.fromString('unknown'), Role.reader);
    });
  });
}
