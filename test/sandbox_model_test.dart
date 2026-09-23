import 'package:elikha_mobile/mobile_database_app.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

void main() {
  test('parses AR-ready and Blender source model formats', () {
    expect(
      SandboxModelOption.fromJson({
        'id': 'school-chair',
        'label': 'School Chair',
        'fileType': 'GLB',
        'description': 'A classroom chair',
      })?.fileType,
      'glb',
    );
    final source = SandboxModelOption.fromJson({
      'id': 'source-file',
      'label': 'Source File',
      'fileType': 'blend',
      'isCustom': true,
      'storageProvider': 'r2',
    });
    expect(source?.isArReady, isFalse);
    expect(source?.canManage, isTrue);
  });

  test('shared catalogue merges with offline fallback models', () async {
    final client = MockClient((request) async {
      expect(request.url.path, '/models');
      return http.Response(
        '{"success":true,"data":['
        '{"id":"cactus","label":"Updated Cactus","fileType":"glb","isBuiltIn":true},'
        '{"id":"school-chair","label":"School Chair","fileType":"obj"}'
        ']}',
        200,
      );
    });

    final models = await fetchSandboxModels(client: client);

    expect(models.any((model) => model.id == 'school-chair'), isTrue);
    expect(
      models.singleWhere((model) => model.id == 'school-chair').canManage,
      isTrue,
    );
    expect(
      models.singleWhere((model) => model.id == 'cactus').label,
      'Updated Cactus',
    );
    expect(models.any((model) => model.id == 'tree'), isTrue);
  });

  test('model catalogue failure quietly uses bundled models', () async {
    final client = MockClient((_) async {
      throw http.ClientException('Browser CORS blocked the request');
    });

    final models = await fetchSandboxModels(client: client);

    expect(models, isNotEmpty);
    expect(models.any((model) => model.id == 'cactus'), isTrue);
  });

  test('model upload uses the authenticated worker contract', () async {
    final file = PlatformFile(
      name: 'school chair.glb',
      size: 4,
      bytes: Uint8List.fromList([1, 2, 3, 4]),
    );
    final client = MockClient((request) async {
      expect(request.method, 'POST');
      expect(request.url.path, '/models');
      expect(request.headers['authorization'], 'Bearer test-token');
      expect(request.headers['x-model-name'], 'School%20Chair');
      expect(request.headers['x-model-file-name'], 'school%20chair.glb');
      expect(request.bodyBytes, [1, 2, 3, 4]);
      return http.Response('{"success":true,"data":{}}', 201);
    });

    await MobileModelLibraryService.upload(
      label: 'School Chair',
      description: 'For the classroom',
      file: file,
      client: client,
      accessToken: 'test-token',
    );
  });

  test('model file validation rejects unsupported and oversized files', () {
    expect(
      MobileModelLibraryService.validateFile(
        PlatformFile(
          name: 'model.zip',
          size: 1,
          bytes: Uint8List.fromList([1]),
        ),
      ),
      contains('Only .obj'),
    );
    expect(
      MobileModelLibraryService.validateFile(
        PlatformFile(
          name: 'model.glb',
          size: MobileModelLibraryService.maxFileBytes + 1,
          bytes: Uint8List(0),
        ),
      ),
      contains('50 MB'),
    );
  });

  test('free model search uses the authenticated Poly Pizza proxy', () async {
    final client = MockClient((request) async {
      expect(request.method, 'GET');
      expect(request.url.path, '/models/search');
      expect(request.url.queryParameters['q'], 'apple');
      expect(request.headers['authorization'], 'Bearer test-token');
      return http.Response(
        '{"success":true,"data":{"results":['
        '{"id":"apple-1","name":"Apple","downloadUrl":"https://static.poly.pizza/apple.glb",'
        '"thumbnailUrl":"https://static.poly.pizza/apple.png","creator":"Artist","license":"CC-BY"}'
        ']}}',
        200,
      );
    });

    final results = await MobileModelLibraryService.searchFreeCatalog(
      'apple',
      client: client,
      accessToken: 'test-token',
    );

    expect(results.single.name, 'Apple');
    expect(results.single.creator, 'Artist');
    expect(results.single.source, 'Poly Pizza');
  });

  test('mobile activity builder preserves the full AR configuration', () {
    const cactus = SandboxModelOption(
      id: 'cactus',
      label: 'Cactus',
      fileType: 'glb',
    );
    const requirement = ActivityColorRequirement(
      targetType: 'model',
      targetId: 'cactus',
      targetLabel: 'Cactus',
      colorHex: '#FF0000',
      colorName: 'Red',
    );

    final encoded = encodeMobileActivityDescription(
      'Paint the cactus',
      instructions: 'Make the cactus red.',
      allowedObjectIds: const ['cube'],
      models: const [cactus, cactus],
      puzzlePieces: 3,
      allowedColors: const ['#FF0000'],
      allowedColorNames: const {'#FF0000': 'Signal red'},
      colorRequirements: const [requirement],
    );
    final json = jsonDecode(encoded) as Map<String, dynamic>;
    final draft = ActivityArDraft.parse(encoded);

    expect(json['tag'], 'activity_ar_v1');
    expect(draft.summary, 'Paint the cactus');
    expect(draft.instructions, 'Make the cactus red.');
    expect(draft.allowedObjectIds, ['cube']);
    expect(draft.modelIds, ['cactus', 'cactus']);
    expect(draft.puzzlePieces, 3);
    expect(draft.allowedColors, ['#FF0000']);
    expect(draft.allowedColorNames['#FF0000'], 'signal red');
    expect(draft.colorRequirements.single.targetId, 'cactus');
  });

  test('mobile activity builder supports the rectangle object', () {
    final draft = ActivityArDraft.parse(
      encodeMobileActivityDescription(
        'Build a sign',
        allowedObjectIds: const ['rectangle'],
      ),
    );

    expect(draft.allowedObjectIds, ['rectangle']);
  });

  test('activity builder drops color rules for tools no longer selected', () {
    const staleRequirement = ActivityColorRequirement(
      targetType: 'object',
      targetId: 'sphere',
      targetLabel: 'Sphere',
      colorHex: '#FF0000',
      colorName: 'Red',
    );

    final draft = ActivityArDraft.parse(
      encodeMobileActivityDescription(
        'Cube only',
        allowedObjectIds: const ['cube'],
        allowedColors: const ['#FF0000'],
        colorRequirements: const [staleRequirement],
      ),
    );

    expect(draft.colorRequirements, isEmpty);
  });
}
