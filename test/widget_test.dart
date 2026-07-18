import 'package:flutter_test/flutter_test.dart';

import 'package:elikha_mobile/main.dart';

void main() {
  test('normalizes database roles for mobile routing', () {
    final user = MobileUser.fromJson({
      'id': 'user-1',
      'name': 'Test User',
      'email': 'test@example.com',
      'role': 'Super Admin',
    });

    expect(user.role, 'superadmin');
  });
}
