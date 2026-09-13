import 'package:elikha_mobile/mobile_database_app.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses only learner-facing rubric and confirmed review fields', () {
    final assessment = StudentActivityAssessment.fromJson({
      'rubric': {
        'id': 'rubric-1',
        'title': 'Color and Shape',
        'description': 'How the artwork will be checked.',
        'assignedVersion': '2',
        'criteria': [
          {
            'name': 'Uses color intentionally',
            'levels': [
              {
                'code': 'B',
                'label': 'Beginning',
                'description': 'Uses one color.',
                'score': 999,
              },
            ],
          },
        ],
        'teacher_id': 'must-not-be-exposed',
      },
      'final_review': {
        'score': 4,
        'feedback': 'Good progress.',
        'overall_comment': 'Keep exploring color.',
        'next_steps': 'Try contrasting colors.',
        'evidence_url': 'https://example.test/evidence',
        'teacher_confirmed_at': '2026-08-14T00:00:00Z',
        'criteria': [
          {
            'criterion_title_snapshot': 'Uses color intentionally',
            'selected_rating': 'C',
            'teacher_note': 'Strong choice.',
            'internal_ai_score': 100,
          },
        ],
        'approved_color_suggestion': {
          'message': 'Try blue next time.',
          'rationale': 'It adds contrast.',
          'colors': [
            {'name': 'Blue', 'hex': '#0000FF'},
          ],
          'suggested_score': 5,
        },
        'ai_evaluation_id': 'must-not-be-exposed',
      },
    });

    expect(assessment.rubric?.title, 'Color and Shape');
    expect(assessment.rubric?.version, '2');
    expect(assessment.rubric?.criteria.single.levels.single.code, 'BG');
    expect(assessment.rubric?.criteria.single.levels.single.label, 'Beginning');
    expect(assessment.finalReview?.score, 4);
    expect(assessment.finalReview?.criteria.single.ratingLabel, 'Consistent');
    expect(
      assessment.finalReview?.colorSuggestion?.colors.single.hex,
      '#0000FF',
    );
  });

  test('handles an activity with no rubric or confirmed review', () {
    final assessment = StudentActivityAssessment.fromJson({
      'rubric': null,
      'final_review': null,
    });

    expect(assessment.rubric, isNull);
    expect(assessment.finalReview, isNull);
  });

  test('student activity hides retired public-school rubric branding', () {
    final rubric = StudentRubric.fromJson({
      'id': 'legacy-rubric',
      'title': 'DepEd SF9 Kindergarten Rubric',
      'description': 'Public-school curriculum standard',
      'criteria': const [],
    });

    expect(rubric.title, 'Activity rubric');
    expect(rubric.description, isEmpty);
  });

  test('maps all developmental result labels', () {
    for (final entry in const {
      'B': 'Beginning',
      'D': 'Developing',
      'C': 'Consistent',
      'NO': 'Not observed',
      'NA': 'Not applicable',
    }.entries) {
      final result = StudentCriterionResult.fromJson({
        'criterion_title_snapshot': 'Criterion',
        'selected_rating': entry.key,
      });
      expect(result.ratingLabel, entry.value);
    }
  });

  test('normalizes current and legacy scores to five stars', () {
    expect(normalizeMobileStarRating(null), 0);
    expect(normalizeMobileStarRating(0), 0);
    expect(normalizeMobileStarRating(4), 4);
    expect(normalizeMobileStarRating(80), 4);
    expect(normalizeMobileStarRating(100), 5);
    expect(normalizeMobileStarRating(140), 5);
    expect(mobileStarRatingLabel(null), 'Not rated');
    expect(mobileStarRatingLabel(80), '4/5 stars');
  });
}
