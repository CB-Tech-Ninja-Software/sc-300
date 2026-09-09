# SC-300 Training — Project Context for Claude Code

Offline-first Android and Windows desktop study app to prep for the **Microsoft Certified: Identity and Access Administrator Associate (SC-300)** exam.
Built for individual study, no accounts, no backend, no cloud sync, sideload APK and native Windows executable targets.

Dart package name: `sc300_prep`.
Display title: `Microsoft SC-300 Training`.
Stack: Flutter 3.47+ / Dart 3.13+, SQLite via `sqflite` (mobile) and `sqflite_common_ffi` (desktop / testing).

---

## 1. Exam Structure & Ground Truth

Sourced directly from the official Microsoft Learn study guide (as of April 2026):
- **Duration:** 100 minutes
- **Passing score:** 700 (on Microsoft's 1–1000 scaled score, mapped to 70%)
- **Target practice question budget:** 60 questions / 100 min
- **Structure:** 4 flat, equally-weighted skill domains (25% each, sums to 100%):

1. **Implement and manage user identities (25%)**
   - Configure and manage Microsoft Entra tenant (roles, administrative units, custom domains, branding, tenant settings).
   - Create, configure, and manage Microsoft Entra identities (users, groups, custom security attributes, PowerShell automation, device join/registration, licenses).
   - Implement and manage external identities (External collaboration, B2B guest invites, cross-tenant access settings, cross-tenant synchronization, external IdPs / SAML / WS-Fed).
   - Implement and manage hybrid identity (Microsoft Entra Connect Sync, Cloud Sync, Password Hash Sync, Pass-through Auth, Seamless SSO, AD FS migration, Connect Health).

2. **Implement authentication and access management (25%)**
   - User authentication methods (Certificate-based auth, Temporary Access Pass, OAuth 2.0 tokens, Microsoft Authenticator, FIDO2 passkeys, tenant-wide MFA, SSPR, Windows Hello for Business, password protection, Kerberos).
   - Conditional Access (Policy planning, assignments, access controls/grant, session controls, device-enforced restrictions, continuous access evaluation CAE, authentication context, protected actions, policy templates).
   - Microsoft Entra ID Protection (User risk, sign-in risk, MFA registration campaigns, risky user/sign-in investigation and remediation, risky workload identities).
   - Global Secure Access (Client deployment, Private Access, Internet Access, Internet Access for Microsoft 365).

3. **Plan and implement workload identities (25%)**
   - Application and Azure workload identities (Managed identities for Azure resources, service principals, user accounts, managed service accounts).
   - Enterprise application integration (Application and tenant settings, admin roles, Microsoft Entra Application Proxy for on-premises apps, SaaS integration, app roles/assignment, user/admin consent, application collections).
   - App registrations (Planning, app creation, authentication/redirect URIs, API permissions/scopes, application roles).
   - Microsoft Defender for Cloud Apps (Cloud discovery, connected apps, app-enforced restrictions, Conditional Access app control, access/session policies, OAuth app policies, Cloud app catalog).

4. **Plan and automate identity governance (25%)**
   - Entitlement management (Catalogs, access packages, access requests, terms of use ToU, external user lifecycle, connected organizations).
   - Access reviews (Planning, review creation/configuration, activity monitoring, self/manager review responses).
   - Privileged access management (Microsoft Entra roles in PIM, Azure resources in PIM, PIM for Groups, request and approval workflows, audit history/reports, break-glass / emergency access accounts).
   - Identity monitoring and reporting (Sign-in/audit/provisioning logs, diagnostic settings to Log Analytics/Storage/Event Hubs, KQL queries in Log Analytics, workbooks, Identity Secure Score).

*Integrity note:* No leaked exam dumps. Content generates textbook-style original questions against official topics from `reference/sc-300-exam-study-guide.md`.

---

## 2. Architecture & Directory Layout

```
sc-300/
  assets/
    data/
      questions.json       # Multiple-choice question bank (flat 4 domains)
      flashcards.json      # Term/concept flashcards deck (Leitner 3-box)
      scenarios.json       # Decision & sequence troubleshooting scenarios
      reference_notes.json # Browsable summary study notes with MS Learn URLs
  lib/
    core/
      constants/
        exam_constants.dart          # 4 domain weights (25% each), times, thresholds, XP rewards
        checklist_items.dart         # OnVUE / exam-day verification items
      database/
        app_database.dart            # SQLite schema, tables, queries & transactions
        seed_importer.dart           # Loads assets/data/*.json into SQLite on first run
      models/
        question.dart                # Question entity & JSON/Map serialization (domain-only, no part)
        flashcard.dart               # Flashcard entity & Leitner progression
        scenario.dart                # Scenario walkthrough entity (domain-only, no useCaseNumber)
        reference_note.dart          # Browsable summary note entity & bookmarking
        question_attempt.dart        # Attempt history & accuracy tracker
        mock_exam.dart               # Mock exam session & 4-domain score breakdown
        user_profile.dart            # Gamification, XP, level & streak state
        badge.dart                   # Unlockable badges & criteria
      services/
        question_engine.dart         # Domain-weighted question picker (4 domains @ 25% each)
        spaced_repetition_engine.dart # Leitner 3-box flashcard scheduler
        mock_exam_engine.dart        # 60-Q / 100-min countdown / hard sequential lock
        gamification_service.dart    # XP rewards, streak tracking, level & badge evaluator
    theme/
      app_theme.dart                 # Dark theme palette & safeBottomInset gesture padding
    main.dart                        # App entry point with desktop SQLite FFI initialization
  reference/
    sc-300-exam-study-guide.md       # Canonical study guide & topic deep dive
  test/
    app_database_test.dart
    models_test.dart
    question_engine_test.dart
    spaced_repetition_engine_test.dart
    mock_exam_engine_test.dart
    gamification_service_test.dart
    reference_notes_test.dart
    seed_data_validation_test.dart
    widget_test.dart
```

---

## 3. Core Engine Mechanics

1. **Domain-Weighted Question Picker (`QuestionEngine`):**
   - Allocates target questions equally (25% each) across the 4 skill domains.
   - Samples randomly without replacement within domain buckets.
   - Evaluates answers, records attempts in SQLite, and awards XP.

2. **Spaced Repetition Flashcards (`SpacedRepetitionEngine`):**
   - Leitner 3-box system: Box 1 = "Still Shaky" (weight 0.60), Box 2 = "Reviewing" (weight 0.30), Box 3 = "Mastered" (weight 0.10).
   - "Got It" advances card bucket (`min(bucket + 1, 3)`).
   - "Still Shaky" immediately drops card back to Box 1.

3. **Mock Exam Engine (`MockExamEngine`):**
   - Generates exact 60-question set matching 4 domains (15 questions per domain = 25% each).
   - 100-minute hard countdown (6000 seconds).
   - Strict no-going-back rule: submitting an answer locks it and immediately advances.
   - Calculates 4-domain score breakdown and pass/fail (threshold >= 70%).
   - Awards +100 XP completion bonus and +50 XP pass bonus.

4. **Gamification & Streak (`GamificationService`):**
   - Level = 1 + floor(XP / 100).
   - Streak tracking based on consecutive calendar days (`YYYY-MM-DD`).
   - Badges: `domain_master`, `mock_champion`, `streak_warrior`, `sc300_master`, `flashcard_fiend`.

5. **Seed Importer (`SeedImporter`):**
   - On first launch, reads `assets/data/questions.json`, `flashcards.json`, `scenarios.json`, and `reference_notes.json` and inserts into SQLite in a batch transaction.

---

## 4. House Rules & Guardrails

1. **Offline-first:** Zero external network calls. All state, attempts, and progress live in local SQLite.
2. **Desktop + Mobile SQLite initialization:** `main.dart` must initialize `sqfliteFfiInit()` and `databaseFactory = databaseFactoryFfi` whenever running on Windows or Linux.
3. **Step dates by calendar days:** Calculate streak dates with `DateTime(y, m, d + n)`, never `Duration(days: n)` across DST transitions.
4. **Touch targets & safe areas:** Always use `AppTheme.safeBottomInset(context)` for bottom-anchored action bars to avoid Android gesture navigation swallow zones.
