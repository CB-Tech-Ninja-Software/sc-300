import 'package:flutter/material.dart';
import 'package:sc300_prep/core/database/app_database.dart';
import 'package:sc300_prep/core/models/badge.dart';
import 'package:sc300_prep/core/models/user_profile.dart';
import 'package:sc300_prep/core/services/gamification_service.dart';
import 'package:sc300_prep/core/services/spaced_repetition_engine.dart';
import 'package:sc300_prep/theme/app_theme.dart';

const Map<String, IconData> _badgeIcons = {
  'folder_shared': Icons.folder_shared,
  'emoji_events': Icons.emoji_events,
  'local_fire_department': Icons.local_fire_department,
  'military_tech': Icons.military_tech,
  'style': Icons.style,
};

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  bool _loading = true;
  UserProfile _profile = const UserProfile();
  Map<String, Map<String, dynamic>> _domainStats = {};
  FlashcardDeckStats? _deckStats;
  int _mockExamsPassed = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final db = AppDatabase.instance;
    final gamification = GamificationService(db: db);
    final srEngine = SpacedRepetitionEngine(db: db);

    final profile = await gamification.getProfile();
    final domainStats = await db.getDomainStats();
    final deckStats = await srEngine.getDeckStats();
    final mockExams = await db.getAllMockExams();

    if (!mounted) return;
    setState(() {
      _profile = profile;
      _domainStats = domainStats;
      _deckStats = deckStats;
      _mockExamsPassed = mockExams.where((e) => e.isPassed).length;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Progress Dashboard')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + AppTheme.safeBottomInset(context)),
                children: [
                  _buildXpCard(),
                  const SizedBox(height: 20),
                  const Text('Domain Mastery', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  if (_domainStats.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Text('No attempts yet — take a quiz to start tracking mastery.', style: TextStyle(color: Colors.grey)),
                    )
                  else
                    for (final entry in _domainStats.entries) _buildDomainRow(entry.key, entry.value),
                  const SizedBox(height: 20),
                  if (_deckStats != null) _buildDeckStatsCard(_deckStats!),
                  const SizedBox(height: 20),
                  const Text('Badges', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  _buildBadgeGrid(),
                ],
              ),
            ),
    );
  }

  Widget _buildXpCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Level ${_profile.level}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  Text('${_profile.xp} XP total', style: const TextStyle(color: Colors.grey)),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(value: _profile.currentLevelProgressFraction, minHeight: 8),
                  ),
                  const SizedBox(height: 4),
                  Text('${_profile.currentLevelXpProgress}/100 XP to next level', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              children: [
                const Icon(Icons.local_fire_department, color: AppTheme.streakColor, size: 32),
                Text('${_profile.streakDays}d', style: const TextStyle(fontWeight: FontWeight.bold)),
                const Text('streak', style: TextStyle(fontSize: 11, color: Colors.grey)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDomainRow(String domain, Map<String, dynamic> stats) {
    final accuracy = (stats['accuracy'] as double? ?? 0.0);
    final total = stats['total'] as int? ?? 0;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: Text(domain)),
              Text('${accuracy.round()}% ($total attempts)', style: const TextStyle(color: Colors.grey)),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(value: accuracy / 100, minHeight: 8, color: AppTheme.domainColor(domain)),
          ),
        ],
      ),
    );
  }

  Widget _buildDeckStatsCard(FlashcardDeckStats stats) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _statColumn('${stats.masteryPercentage.round()}%', 'Mastery'),
            _statColumn('${stats.box3Count}', 'Mastered'),
            _statColumn('${stats.box1Count}', 'Still Shaky'),
            _statColumn('$_mockExamsPassed', 'Mocks Passed'),
          ],
        ),
      ),
    );
  }

  Widget _statColumn(String value, String label) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
      ],
    );
  }

  Widget _buildBadgeGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 2.4,
      ),
      itemCount: AppBadge.predefinedBadges.length,
      itemBuilder: (context, index) {
        final badge = AppBadge.predefinedBadges[index];
        final unlocked = _profile.unlockedBadgeIds.contains(badge.id);
        return Card(
          color: unlocked ? AppTheme.xpColor.withAlpha(30) : null,
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                Icon(
                  _badgeIcons[badge.iconName] ?? Icons.emoji_events,
                  color: unlocked ? AppTheme.xpColor : Colors.grey,
                  size: 28,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        badge.title,
                        style: TextStyle(fontWeight: FontWeight.bold, color: unlocked ? null : Colors.grey),
                      ),
                      Text(
                        badge.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 10, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
