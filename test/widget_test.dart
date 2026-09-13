import 'package:flutter_test/flutter_test.dart';

import 'package:elikha_mobile/main.dart';
import 'package:elikha_mobile/mobile_database_app.dart';

void main() {
  test('student display names prefer real enrollment snapshots', () {
    expect(
      resolveMobileStudentDisplayName(
        profileName: 'Student',
        enrollmentName: 'Nicos Raphael Nicolas',
        email: 'nicos@example.com',
      ),
      'Nicos Raphael Nicolas',
    );
    expect(
      resolveMobileStudentDisplayName(
        profileName: '',
        enrollmentName: 'Learner',
        email: 'nicos@example.com',
      ),
      'nicos',
    );
  });

  test('teacher settings merge saved values with safe defaults', () {
    final settings = TeacherMobileSettings.fromRows(
      {'voiceInstructions': false, 'quality': 'low'},
      {'email_enabled': false, 'in_app_enabled': true},
    );

    expect(settings.voiceInstructions, isFalse);
    expect(settings.quality, 'low');
    expect(settings.emailEnabled, isFalse);
    expect(settings.soundEffects, isTrue);
    expect(settings.notificationPreferencesJson['in_app_enabled'], isTrue);
  });

  test('class and learner image paths are preserved for private R2 display', () {
    final klass = DbClass.fromRow({
      'id': 'class-1',
      'name': 'Grade 4 - Ruby',
      'grade': 'Grade 4',
      'section': 'Ruby',
      'subject': 'Arts',
      'color': '#C2410C',
      'image_url': 'r2-media/classes/class-1',
    });
    final student = DbStudent.fromUserRow({
      'id': 'student-1',
      'name': 'Nicos Raphael Nicolas',
      'email': 'nicos@example.com',
      'role': 'student',
      'avatar_url': 'r2-media/avatars/student-1',
    });

    expect(klass.displayName, 'Grade 4 - Ruby');
    expect(klass.color, '#C2410C');
    expect(klass.imagePath, 'r2-media/classes/class-1');
    expect(student.avatarPath, 'r2-media/avatars/student-1');
  });

  test('teacher rubrics normalize legacy developmental rating codes', () {
    final rubric = TeacherRubricDefinition.fromRow({
      'id': 'rubric-1',
      'title': 'Coloring care',
      'metadata': {'activityType': 'paint'},
      'criteria': [
        {
          'name': 'Colors the requested areas',
          'levels': [
            {'code': 'B', 'description': 'Needs guidance'},
            {'code': 'D', 'description': 'Uses some support'},
            {'code': 'C', 'description': 'Works independently'},
          ],
        },
      ],
    });

    expect(rubric.activityType, 'paint');
    expect(rubric.criteriaSummary, 'Colors the requested areas');
    expect(rubric.criteria.single.beginning, 'Needs guidance');
    expect(rubric.criteria.single.consistent, 'Works independently');
  });

  test('normalizes database roles for mobile routing', () {
    final user = MobileUser.fromJson({
      'id': 'user-1',
      'name': 'Test User',
      'email': 'test@example.com',
      'role': 'Super Admin',
    });

    expect(user.role, 'superadmin');
  });

  group('password recovery input', () {
    test('normalizes email and six-digit codes', () {
      expect(
        normalizePasswordResetEmail('  Learner@Example.COM  '),
        'learner@example.com',
      );
      expect(normalizePasswordResetOtp('1a2 3-4567'), '123456');
      expect(isValidPasswordResetEmail('learner@example.com'), isTrue);
      expect(isValidPasswordResetEmail('not-an-email'), isFalse);
    });

    test('requires matching passwords with at least eight characters', () {
      expect(
        validateRecoveredPassword('short', 'short'),
        'Password must be at least 8 characters.',
      );
      expect(
        validateRecoveredPassword('new-password', 'different-password'),
        'Passwords do not match.',
      );
      expect(validateRecoveredPassword('new-password', 'new-password'), isNull);
    });
  });
}
