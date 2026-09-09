import 'package:flutter/material.dart';
import 'package:sc300_prep/core/constants/exam_constants.dart';
import 'package:sc300_prep/core/database/app_database.dart';
import 'package:sc300_prep/core/models/scenario.dart';
import 'package:sc300_prep/core/services/gamification_service.dart';
import 'package:sc300_prep/theme/app_theme.dart';

class ScenarioListScreen extends StatefulWidget {
  const ScenarioListScreen({super.key});

  @override
  State<ScenarioListScreen> createState() => _ScenarioListScreenState();
}

class _ScenarioListScreenState extends State<ScenarioListScreen> {
  bool _loading = true;
  List<Scenario> _scenarios = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final scenarios = await AppDatabase.instance.getAllScenarios();
    if (!mounted) return;
    setState(() {
      _scenarios = scenarios..sort((a, b) => a.domain.compareTo(b.domain));
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scenario Walkthroughs')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _scenarios.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text('No scenarios found yet. Check back once the scenario bank is seeded.'),
                  ),
                )
              : ListView.builder(
                  padding: EdgeInsets.fromLTRB(12, 12, 12, 12 + AppTheme.safeBottomInset(context)),
                  itemCount: _scenarios.length,
                  itemBuilder: (context, index) {
                    final scenario = _scenarios[index];
                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppTheme.domainColor(scenario.domain).withAlpha(60),
                          child: const Icon(Icons.alt_route, size: 18),
                        ),
                        title: Text(scenario.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(scenario.domain),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => ScenarioDetailScreen(scenario: scenario)),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}

class ScenarioDetailScreen extends StatefulWidget {
  final Scenario scenario;
  final GamificationService? gamification;
  const ScenarioDetailScreen({super.key, required this.scenario, this.gamification});

  @override
  State<ScenarioDetailScreen> createState() => _ScenarioDetailScreenState();
}

class _ScenarioDetailScreenState extends State<ScenarioDetailScreen> {
  int? _selectedIndex;
  bool _xpAwarded = false;

  Future<void> _select(int index) async {
    if (_selectedIndex != null) return;
    setState(() => _selectedIndex = index);
    if (index == widget.scenario.correctIndex && !_xpAwarded) {
      _xpAwarded = true;
      final gamification = widget.gamification ?? GamificationService();
      await gamification.awardXp(ExamConstants.xpScenarioCompleted);
      await gamification.recordActivity();
    }
  }

  @override
  Widget build(BuildContext context) {
    final scenario = widget.scenario;
    final answered = _selectedIndex != null;
    final isCorrect = answered && _selectedIndex == scenario.correctIndex;

    return Scaffold(
      appBar: AppBar(title: Text(scenario.domain)),
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 32 + AppTheme.safeBottomInset(context)),
          children: [
            Text(scenario.title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Text(scenario.scenarioText),
              ),
            ),
            if (scenario.steps != null && scenario.steps!.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text('Sequence', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              for (int i = 0; i < scenario.steps!.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(radius: 12, child: Text('${i + 1}', style: const TextStyle(fontSize: 12))),
                      const SizedBox(width: 10),
                      Expanded(child: Text(scenario.steps![i])),
                    ],
                  ),
                ),
            ],
            const SizedBox(height: 16),
            const Text('What do you do next?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Text(scenario.question),
            const SizedBox(height: 12),
            for (int i = 0; i < scenario.options.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _buildOption(scenario, i),
              ),
            if (answered) ...[
              const SizedBox(height: 8),
              Card(
                color: (isCorrect ? Colors.green : Colors.red).withAlpha(30),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isCorrect ? 'Correct! +${ExamConstants.xpScenarioCompleted} XP' : 'Not quite',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(scenario.explanation),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              OutlinedButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Back to Scenarios')),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildOption(Scenario scenario, int i) {
    final answered = _selectedIndex != null;
    Color? bg;
    IconData? icon;
    if (answered) {
      if (i == scenario.correctIndex) {
        bg = Colors.green.withAlpha(60);
        icon = Icons.check_circle;
      } else if (i == _selectedIndex) {
        bg = Colors.red.withAlpha(60);
        icon = Icons.cancel;
      }
    }
    return Material(
      color: bg ?? Theme.of(context).colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: answered ? null : () => _select(i),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Expanded(child: Text(scenario.options[i])),
              if (icon != null) Icon(icon, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
