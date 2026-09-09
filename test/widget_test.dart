import 'package:flutter_test/flutter_test.dart';
import 'package:sc300_prep/main.dart';
import 'package:sc300_prep/core/models/user_profile.dart';

void main() {
  testWidgets('HomeScreen renders title and summary cards cleanly', (WidgetTester tester) async {
    const testProfile = UserProfile(
      id: 'default',
      xp: 250,
      level: 3,
      streakDays: 4,
      totalQuizzesTaken: 5,
      totalFlashcardsReviewed: 20,
      totalMockExamsTaken: 1,
    );

    await tester.pumpWidget(
      const Sc300App(
        homeOverride: HomeScreen(
          initialLoading: false,
          initialProfile: testProfile,
          initialQuestionCount: 8,
          initialFlashcardCount: 8,
          initialScenarioCount: 4,
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Microsoft SC-300 Training'), findsOneWidget);
    expect(find.text('4d streak'), findsOneWidget);
    expect(find.text('Lvl 3 (250 XP)'), findsOneWidget);
    expect(find.text('Questions'), findsOneWidget);
    expect(find.text('Flashcards'), findsOneWidget);
    expect(find.text('Scenarios'), findsOneWidget);
    expect(find.text('Mock Exams'), findsOneWidget);
  });
}
