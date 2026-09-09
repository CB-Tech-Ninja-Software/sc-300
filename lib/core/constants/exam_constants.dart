/// Constants for the Microsoft SC-300 Exam Study App (sc300_prep).
class ExamConstants {
  // Exam Identification & Logistics
  static const String examTitle = 'Microsoft Certified: Identity and Access Administrator Associate';
  static const String examCode = 'SC-300';
  static const String? targetExamDateIso = null;

  // 4 Skill Domains (25% each, sums to 1.0)
  static const String domainManageIdentities = 'Implement and manage user identities';
  static const String domainAuthenticationAccess = 'Implement authentication and access management';
  static const String domainWorkloadIdentities = 'Plan and implement workload identities';
  static const String domainIdentityGovernance = 'Plan and automate identity governance';

  static const double weightManageIdentities = 0.25;
  static const double weightAuthenticationAccess = 0.25;
  static const double weightWorkloadIdentities = 0.25;
  static const double weightIdentityGovernance = 0.25;

  static const Map<String, double> domainWeights = {
    domainManageIdentities: weightManageIdentities,
    domainAuthenticationAccess: weightAuthenticationAccess,
    domainWorkloadIdentities: weightWorkloadIdentities,
    domainIdentityGovernance: weightIdentityGovernance,
  };

  static const List<String> allDomains = [
    domainManageIdentities,
    domainAuthenticationAccess,
    domainWorkloadIdentities,
    domainIdentityGovernance,
  ];

  // Mock Exam Specifications (100 min duration, 60 questions, 70% passing threshold matching 700/1000)
  static const int mockExamQuestionCount = 60;
  static const int mockExamTimeLimitSeconds = 6000; // 100 minutes (6000s)
  static const double mockExamPassingScorePercentage = 70.0; // 700 / 1000 = 70%

  // Spaced Repetition (Leitner Box) Configuration
  static const int leitnerMinBox = 1;
  static const int leitnerMaxBox = 3;
  static const String box1Label = 'Still Shaky';
  static const String box2Label = 'Reviewing';
  static const String box3Label = 'Mastered';

  // Selection probability weights for Leitner boxes
  static const double box1SelectionWeight = 0.60;
  static const double box2SelectionWeight = 0.30;
  static const double box3SelectionWeight = 0.10;

  // Gamification XP Rewards
  static const int xpQuestionCorrect = 10;
  static const int xpFlashcardReviewed = 5;
  static const int xpScenarioCompleted = 25;
  static const int xpMockExamCompleted = 100;
  static const int xpMockExamPassedBonus = 50;
  static const int xpPerLevel = 100; // 100 XP per level
}
