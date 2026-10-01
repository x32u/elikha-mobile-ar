import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:elikha_mobile/artwork_export.dart';
import 'package:elikha_mobile/mobile_database_app.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

const _tinyPng =
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAACklEQVQImWNgAAAAAgABSK+kcQAAAABJRU5ErkJggg==';
const _savedPicture = 'data:image/png;base64,$_tinyPng';
const _student = DbStudent(
  id: 'linked-child',
  name: 'Student 26',
  email: 'student26@elikha.com',
  role: 'student',
);

class _TestParentAccess {
  String? currentId = 'parent';
  bool linked = true;
  final identities = StreamController<String?>.broadcast(sync: true);
  late final access = ParentReadAccess(
    parentId: 'parent',
    currentUserId: () => currentId,
    identityChanges: identities.stream,
    isLinked: (_) async => linked,
  );

  Future<void> dispose() async {
    access.dispose();
    await identities.close();
  }
}

class _TestFilePicker extends FilePicker {
  Uint8List? savedBytes;
  String? savedName;
  String? result = '/test/artwork.png';
  Object? failure;
  @override
  Future<String?> saveFile({
    String? dialogTitle,
    String? fileName,
    String? initialDirectory,
    FileType type = FileType.any,
    List<String>? allowedExtensions,
    Uint8List? bytes,
    bool lockParentWindow = false,
  }) async {
    if (failure != null) throw failure!;
    savedBytes = bytes;
    savedName = fileName;
    return result;
  }
}

Future<String> _rasterFixture() async {
  final recorder = ui.PictureRecorder();
  Canvas(recorder).drawColor(const Color(0xFF38B6FF), BlendMode.src);
  final picture = recorder.endRecording();
  final image = await picture.toImage(30, 20);
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  final source =
      'data:image/png;base64,${base64Encode(bytes!.buffer.asUint8List())}';
  image.dispose();
  picture.dispose();
  return source;
}

Future<void> _settleArtworkImages(WidgetTester tester) async {
  // Engine image codecs complete outside the widget test's fake clock.
  await tester.pump();
  for (var attempt = 0; attempt < 50; attempt++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await tester.pump(const Duration(milliseconds: 16));
    final imageWidgets = find.byType(RawImage).evaluate();
    final imagesDecoded = imageWidgets.every(
      (element) => (element.renderObject! as RenderImage).image != null,
    );
    if (find.text('Loading artwork').evaluate().isEmpty && imagesDecoded) break;
  }
  expect(find.text('Loading artwork'), findsNothing);
  for (final element in find.byType(RawImage).evaluate()) {
    expect((element.renderObject! as RenderImage).image, isNotNull);
  }
  await tester.pumpAndSettle();
}

DbSubmission _submission({
  String image = _savedPicture,
  bool reviewed = false,
  String feedback = '',
  DateTime? submittedAt,
}) => DbSubmission(
  id: 'submission-${submittedAt?.day ?? 1}',
  activityId: 'activity',
  studentId: _student.id,
  activityTitle: 'Cup artwork',
  studentName: _student.name,
  studentEmail: _student.email,
  artworkUrl: image,
  rawDescription: '',
  status: reviewed ? 'reviewed' : 'submitted',
  submittedAt: submittedAt ?? DateTime.utc(2026, 9, 24),
  reviewedAt: reviewed ? DateTime.utc(2026, 9, 26) : null,
  score: reviewed ? 4 : 5,
  feedback: feedback,
);

DbActivity _activity({
  String id = 'activity',
  String title = 'Cup artwork',
  DbSubmission? submission,
  DateTime? dueDate,
}) => DbActivity(
  id: id,
  title: title,
  summary: 'Build a cup artwork',
  rawDescription: '',
  dueDate: dueDate,
  status: 'active',
  imageUrl: 'https://example.test/teacher-cover.png',
  classId: 'class-1',
  className: 'Kindergarten - Blue',
  grade: 'Kindergarten',
  subject: 'Arts',
  assignmentStatus: 'assigned',
  assignedAt: DateTime.utc(2026, 9, 20),
  submission: submission,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    FilePicker.platform = _TestFilePicker();
    if (const bool.fromEnvironment('PARENT_SCREENSHOTS')) {
      final font = File('/System/Library/Fonts/Supplemental/Arial.ttf');
      if (await font.exists()) {
        final loader = FontLoader('ParentTestSans')
          ..addFont(
            Future.value(ByteData.sublistView(await font.readAsBytes())),
          );
        await loader.load();
      }
    }
  });

  test(
    'artwork gallery uses submitted images, never teacher assignment covers',
    () {
      final child = ParentChild(
        student: _student,
        activities: [
          _activity(id: 'pending-cover'),
          _activity(
            id: 'submitted-cover',
            submission: _submission(image: ''),
          ),
          _activity(
            id: 'scene-only',
            submission: _submission(image: 'data:application/json;base64,e30='),
          ),
          _activity(id: 'artwork', submission: _submission()),
        ],
      );
      expect(child.artworkActivities.map((item) => item.id), ['artwork']);
      expect(
        child.artworkActivities.single.submission!.artworkUrl,
        _savedPicture,
      );
      expect(child.submittedCount, 3);
      expect(child.completionFraction, .75);
    },
  );

  test('pending work is due-first and submitted artwork is newest-first', () {
    final child = ParentChild(
      student: _student,
      activities: [
        _activity(id: 'no-date'),
        _activity(id: 'later', dueDate: DateTime.utc(2026, 10, 5)),
        _activity(id: 'soon', dueDate: DateTime.utc(2026, 10, 2)),
        _activity(
          id: 'old-art',
          submission: _submission(submittedAt: DateTime.utc(2026, 9, 24)),
        ),
        _activity(
          id: 'new-art',
          submission: _submission(submittedAt: DateTime.utc(2026, 9, 28)),
        ),
      ],
    );
    expect(child.pendingActivities.map((item) => item.id), [
      'soon',
      'later',
      'no-date',
    ]);
    expect(child.artworkActivities.map((item) => item.id), [
      'new-art',
      'old-art',
    ]);
    expect(child.activities.first.id, 'no-date');
    expect(
      parentActivityContext(child.activities.first),
      'Arts · Kindergarten - Blue',
    );
  });

  test('only reviewed work contributes feedback and ratings', () {
    final child = ParentChild(
      student: _student,
      activities: [
        _activity(
          id: 'draft',
          submission: _submission(feedback: 'Draft note'),
        ),
        _activity(
          id: 'reviewed',
          submission: _submission(
            reviewed: true,
            feedback: 'Good color choices',
          ),
        ),
      ],
    );
    expect(child.reviewedActivities.map((item) => item.id), ['reviewed']);
    expect(child.averageScoreLabel, '4.0');
  });

  test('filename is a short path-safe PNG name', () {
    expect(
      artworkPngFileName('Student / 26', 'Cup: artwork'),
      'Student - 26-Cup- artwork.png',
    );
    expect(artworkPngFileName('../', '<>'), 'E-Likha-artwork.png');
    expect(artworkPngFileName('S' * 200, 'A').length, lessThanOrEqualTo(114));
  });

  test(
    'rejects scene JSON, SVG, HTTP and malformed inline image bytes',
    () async {
      for (final source in [
        'data:application/json;base64,e30=',
        'data:image/svg+xml;base64,PHN2Zy8+',
        'http://example.test/art.png',
        'https://user:password@example.test/image.png',
      ]) {
        expect(isSupportedArtworkImage(source), isFalse);
        await expectLater(
          loadArtworkPng(source),
          throwsA(isA<ArtworkExportException>()),
        );
      }
      await expectLater(
        loadArtworkPng('data:image/png;base64,invalid!'),
        throwsA(isA<ArtworkExportException>()),
      );
      await expectLater(
        loadArtworkPng(
          'data:image/png;base64,${base64Encode(utf8.encode('<svg/>'))}',
        ),
        throwsA(isA<ArtworkExportException>()),
      );
    },
  );

  test('converts an encoded raster into a real PNG', () async {
    // Generate a valid raster fixture using the same platform decoder used by
    // the application, rather than relying on browser-only image behavior.
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder)..drawColor(Colors.blue, BlendMode.src);
    final picture = recorder.endRecording();
    final image = await picture.toImage(2, 2);
    final input = await image.toByteData(format: ui.ImageByteFormat.png);
    final output = await artworkBytesToPng(input!.buffer.asUint8List());
    expect(output.sublist(0, 8), [137, 80, 78, 71, 13, 10, 26, 10]);
    final codec = await ui.instantiateImageCodec(output);
    final exported = (await codec.getNextFrame()).image;
    expect(exported.width, 2);
    expect(exported.height, 2);
    exported.dispose();
    codec.dispose();
    image.dispose();
    picture.dispose();
    // Retain the canvas binding until the picture is recorded.
    expect(canvas, isA<Canvas>());
  });

  test(
    'remote download refuses redirects and oversized responses without credentials',
    () async {
      final redirect = MockClient((request) async {
        expect(request.headers.containsKey('authorization'), isFalse);
        expect(request.followRedirects, isFalse);
        return http.Response(
          '',
          302,
          headers: {'location': 'http://unsafe.test/image.png'},
        );
      });
      await expectLater(
        loadArtworkImageBytes('https://example.test/art.png', client: redirect),
        throwsA(isA<ArtworkExportException>()),
      );
      final oversized = MockClient(
        (_) async => http.Response(
          '',
          200,
          headers: {
            'content-type': 'image/png',
            'content-length': '${artworkMaxInputBytes + 1}',
          },
        ),
      );
      await expectLater(
        loadArtworkImageBytes(
          'https://example.test/art.png',
          client: oversized,
        ),
        throwsA(isA<ArtworkExportException>()),
      );
      redirect.close();
      oversized.close();
    },
  );

  testWidgets(
    'parent progress page is read-only and does not expose unreviewed notes',
    (tester) async {
      final access = _TestParentAccess();
      addTearDown(access.dispose);
      final child = ParentChild(
        student: _student,
        activities: [
          _activity(
            submission: _submission(
              image: '',
              feedback: 'Private draft feedback',
            ),
          ),
        ],
      );
      await tester.pumpWidget(
        MaterialApp(
          home: ParentChildProgressPage(child: child, access: access.access),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Student 26’s progress'), findsOneWidget);
      expect(find.text('Private draft feedback'), findsNothing);
      expect(find.text('Submit'), findsNothing);
      expect(find.text('View in AR'), findsNothing);
      expect(find.text('Rate Student'), findsNothing);
      await tester.scrollUntilVisible(find.text('No reviews yet'), 200);
      expect(find.text('No reviews yet'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'missing saved picture never previews or exports the teacher cover',
    (tester) async {
      final access = _TestParentAccess();
      addTearDown(access.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: ParentArtworkPreviewPage(
            studentName: _student.name,
            activity: _activity(submission: _submission(image: '')),
            access: access.access,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.text('This submission has no saved artwork picture.'),
        findsOneWidget,
      );
      final export = tester.widget<OutlinedButton>(
        find.widgetWithText(OutlinedButton, 'Export PNG'),
      );
      expect(export.onPressed, isNull);
      expect(find.byType(Image), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  test(
    'parent history retains submitted work without changing student filtering',
    () {
      expect(
        mobileActivityVisibleForStudent(
          classId: 'archived',
          activeClassIds: {},
          hasCompletedSubmission: true,
        ),
        isFalse,
      );
      expect(
        mobileActivityVisibleForStudent(
          classId: 'archived',
          activeClassIds: {},
          hasCompletedSubmission: true,
          preserveSubmittedHistory: true,
        ),
        isTrue,
      );
      expect(
        mobileActivityVisibleForStudent(
          classId: 'archived',
          activeClassIds: {},
          hasCompletedSubmission: false,
          preserveSubmittedHistory: true,
        ),
        isFalse,
      );
    },
  );

  test(
    'submission timestamps assume UTC and parent date-only deadlines end in PHT',
    () {
      for (final value in [
        '2026-09-24T00:30:00',
        '2026-09-24T00:30:00Z',
        '2026-09-24T08:30:00+08:00',
      ]) {
        expect(
          parseMobileUtcTimestamp(value)?.toUtc(),
          DateTime.utc(2026, 9, 24, 0, 30),
        );
      }
      expect(
        parseMobileParentDeadline('2026-09-24')?.toUtc(),
        DateTime.utc(2026, 9, 24, 15, 59, 59, 999),
      );
      expect(
        parseMobileParentDeadline('2026-09-24T00:30:00')?.toUtc(),
        DateTime.utc(2026, 9, 24, 0, 30),
      );
    },
  );

  test('parent notifications resolve only unambiguous linked children', () {
    final child = ParentChild(student: _student, activities: [_activity()]);
    final bundle = ParentBundle(
      parentId: 'parent',
      children: [child],
      notifications: [],
    );
    DbNotification update(Map<String, dynamic> metadata) => DbNotification(
      id: 'n',
      type: 'review',
      title: 'Review',
      message: 'Reviewed',
      createdAt: null,
      metadata: metadata,
    );
    expect(
      parentNotificationChild(
        bundle,
        update({'student_id': 'linked-child', 'activity_id': 'activity'}),
      ),
      same(child),
    );
    expect(
      parentNotificationChild(
        bundle,
        update({'student_id': 'unlinked-child', 'activity_id': 'activity'}),
      ),
      isNull,
    );
    expect(parentNotificationChild(bundle, update({})), isNull);
  });

  test(
    'access survives same-account refresh but revokes on logout or unlink',
    () async {
      final state = _TestParentAccess();
      expect(await state.access.verify('linked-child'), isTrue);
      state.identities.add('parent');
      expect(state.access.isCurrent, isTrue);
      state.linked = false;
      expect(await state.access.verify('linked-child'), isFalse);
      state.linked = true;
      expect(await state.access.verify('linked-child'), isFalse);
      await state.dispose();
      final signedOut = _TestParentAccess();
      expect(await signedOut.access.verify('linked-child'), isTrue);
      signedOut.currentId = null;
      signedOut.identities.add(null);
      expect(signedOut.access.isCurrent, isFalse);
      await signedOut.dispose();
    },
  );

  test(
    'preview owns independent identity subscription and disposed checks are safe',
    () async {
      final state = _TestParentAccess();
      final preview = state.access.fork();
      state.access.dispose();
      expect(await preview.verify('linked-child'), isTrue);
      state.currentId = 'other-parent';
      state.identities.add('other-parent');
      expect(preview.isCurrent, isFalse);
      preview.dispose();
      await state.identities.close();

      final pendingLink = Completer<bool>();
      final identities = StreamController<String?>.broadcast();
      final pending = ParentReadAccess(
        parentId: 'parent',
        currentUserId: () => 'parent',
        identityChanges: identities.stream,
        isLinked: (_) => pendingLink.future,
      );
      final request = pending.verify('linked-child');
      pending.dispose();
      pendingLink.complete(false);
      expect(await request, isFalse);
      await identities.close();
    },
  );

  testWidgets('open child progress hides immediately on account switch', (
    tester,
  ) async {
    final state = _TestParentAccess();
    addTearDown(state.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: ParentChildProgressPage(
          child: ParentChild(student: _student, activities: []),
          access: state.access,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Student 26’s progress'), findsOneWidget);
    state.currentId = 'another-parent';
    state.identities.add('another-parent');
    await tester.pumpAndSettle();
    expect(find.text('Student 26’s progress'), findsNothing);
    expect(find.text('Return to account'), findsOneWidget);
  });

  testWidgets('replacement access cannot display an unverified child', (
    tester,
  ) async {
    final oldState = _TestParentAccess();
    addTearDown(oldState.dispose);
    final pending = Completer<bool>();
    final identities = StreamController<String?>.broadcast();
    final newAccess = ParentReadAccess(
      parentId: 'parent',
      currentUserId: () => 'parent',
      identityChanges: identities.stream,
      isLinked: (_) => pending.future,
    );
    addTearDown(() async {
      newAccess.dispose();
      await identities.close();
    });
    Widget page(ParentReadAccess access) => MaterialApp(
      home: ParentArtworkPreviewPage(
        studentName: 'Private child name',
        activity: _activity(submission: _submission(image: '')),
        access: access,
      ),
    );
    await tester.pumpWidget(page(oldState.access));
    await tester.pumpAndSettle();
    expect(find.text('Private child name'), findsOneWidget);
    await tester.pumpWidget(page(newAccess));
    await tester.pump();
    expect(find.text('Private child name'), findsNothing);
    pending.complete(false);
    await tester.pumpAndSettle();
    expect(find.text('Private child name'), findsNothing);
  });

  testWidgets(
    'PNG export saves converted bytes and reports success or cancellation',
    (tester) async {
      final state = _TestParentAccess();
      addTearDown(state.dispose);
      final picker = _TestFilePicker();
      final previousPicker = FilePicker.platform;
      FilePicker.platform = picker;
      addTearDown(() => FilePicker.platform = previousPicker);
      final source = (await tester.runAsync(_rasterFixture))!;
      await tester.pumpWidget(
        MaterialApp(
          home: ParentArtworkPreviewPage(
            studentName: _student.name,
            activity: _activity(submission: _submission(image: source)),
            access: state.access,
          ),
        ),
      );
      await _settleArtworkImages(tester);
      await tester.runAsync(() async {
        await tester.tap(find.widgetWithText(OutlinedButton, 'Export PNG'));
        for (
          var attempt = 0;
          picker.savedBytes == null && attempt < 50;
          attempt++
        ) {
          await Future<void>.delayed(const Duration(milliseconds: 20));
        }
      });
      await tester.pumpAndSettle();
      expect(picker.savedBytes?.sublist(0, 8), [
        137,
        80,
        78,
        71,
        13,
        10,
        26,
        10,
      ]);
      expect(picker.savedName, 'Student 26-Cup artwork.png');
      expect(find.text('Artwork PNG saved.'), findsOneWidget);
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
      picker.savedBytes = null;
      picker.result = null;
      await tester.runAsync(() async {
        await tester.tap(find.widgetWithText(OutlinedButton, 'Export PNG'));
        for (
          var attempt = 0;
          picker.savedBytes == null && attempt < 50;
          attempt++
        ) {
          await Future<void>.delayed(const Duration(milliseconds: 20));
        }
      });
      await tester.pumpAndSettle();
      expect(find.text('Export cancelled.'), findsOneWidget);
    },
  );

  for (final size in [
    const Size(320, 568),
    const Size(768, 1024),
    const Size(844, 390),
  ]) {
    testWidgets('parent pages fit ${size.width} x ${size.height}', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final state = _TestParentAccess();
      addTearDown(state.dispose);
      final source = (await tester.runAsync(_rasterFixture))!;
      final art = _activity(
        title:
            'Creative artwork with paper cups, popsicle sticks and carefully selected colors',
        submission: _submission(
          image: source,
          reviewed: true,
          feedback: 'Thoughtful use of color and arrangement.',
        ),
      );
      final boundaryKey = GlobalKey();
      final theme = ThemeData(
        colorScheme: const ColorScheme.light(
          primary: Color(0xFF1800AD),
          secondary: Color(0xFF38B6FF),
          surface: Colors.white,
          onSurface: Colors.black,
        ),
        scaffoldBackgroundColor: Colors.white,
        fontFamily: 'ParentTestSans',
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          home: ParentChildProgressPage(
            child: ParentChild(
              student: _student,
              activities: [
                art,
                _activity(id: 'pending'),
              ],
            ),
            access: state.access,
          ),
        ),
      );
      await _settleArtworkImages(tester);
      expect(tester.takeException(), isNull);
      expect(find.text('Artwork'), findsOneWidget);
      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          home: RepaintBoundary(
            key: boundaryKey,
            child: ParentArtworkPreviewPage(
              studentName: 'A child with a longer full name for layout testing',
              activity: art,
              access: state.access,
            ),
          ),
        ),
      );
      await _settleArtworkImages(tester);
      expect(tester.takeException(), isNull);
      expect(find.byType(InteractiveViewer), findsOneWidget);
      expect(find.byType(Image), findsOneWidget);
      if (const bool.fromEnvironment('PARENT_SCREENSHOTS')) {
        await tester.runAsync(() async {
          final boundary =
              boundaryKey.currentContext!.findRenderObject()!
                  as RenderRepaintBoundary;
          final image = await boundary.toImage();
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          final output = Directory('build/test_artifacts');
          await output.create(recursive: true);
          await File(
            '${output.path}/parent-preview-${size.width.toInt()}x${size.height.toInt()}.png',
          ).writeAsBytes(bytes!.buffer.asUint8List());
          image.dispose();
        });
      }
    });
  }
}
