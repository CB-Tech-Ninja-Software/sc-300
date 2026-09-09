import 'dart:async';
import 'package:flutter/material.dart';
import 'package:sc300_prep/core/constants/exam_constants.dart';
import 'package:sc300_prep/core/models/mock_exam.dart';
import 'package:sc300_prep/core/services/mock_exam_engine.dart';
import 'package:sc300_prep/theme/app_theme.dart';

class MockExamScreen extends StatefulWidget {
  const MockExamScreen({super.key});

  @override
  State<MockExamScreen> createState() => _MockExamScreenState();
}

enum _Stage { intro, loading, exam, results }

class _MockExamScreenState extends State<MockExamScreen> {
  final _engine = MockExamEngine();
  _Stage _stage = _Stage.intro;
  MockExamSession? _session;
  MockExamResult? _result;
  int? _selectedIndex;
  Timer? _timer;
  int _remainingSeconds = ExamConstants.mockExamTimeLimitSeconds;
  DateTime _questionStartedAt = DateTime.now();

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _startExam() async {
    setState(() => _stage = _Stage.loading);
    final session = await _engine.startExam();
    if (!mounted) return;
    if (session.questions.isEmpty) {
      setState(() => _stage = _Stage.intro);
      return;
    }
    setState(() {
      _session = session;
      _remainingSeconds = session.timeLimitSeconds;
      _selectedIndex = null;
      _questionStartedAt = DateTime.now();
      _stage = _Stage.exam;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _remainingSeconds--);
      if (_remainingSeconds <= 0) {
        _timer?.cancel();
        _finish();
      }
    });
  }

  Future<void> _select(int optionIndex) async {
    if (_selectedIndex != null || _session == null) return;
    final spent = DateTime.now().difference(_questionStartedAt).inSeconds;
    setState(() => _selectedIndex = optionIndex);

    await _engine.submitAnswer(
      _session!,
      selectedIndex: optionIndex,
      timeSpentOnQuestionSeconds: spent,
    );
    if (!mounted) return;

    if (_session!.isFinished) {
      _timer?.cancel();
      await _finish();
      return;
    }

    setState(() {
      _selectedIndex = null;
      _questionStartedAt = DateTime.now();
    });
  }

  Future<void> _finish() async {
    if (_session == null || _result != null) return;
    final result = await _engine.completeExam(_session!);
    if (!mounted) return;
    setState(() {
      _result = result;
      _stage = _Stage.results;
    });
  }

  Future<bool> _confirmAbandon() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Abandon mock exam?'),
        content: const Text('Your progress on this attempt will not be scored or saved.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Keep Going')),
          FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Abandon')),
        ],
      ),
    );
    return confirmed ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _stage != _Stage.exam,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop || _stage != _Stage.exam) return;
        final shouldPop = await _confirmAbandon();
        if (shouldPop && context.mounted) {
          _timer?.cancel();
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Mock Exam'),
          actions: _stage == _Stage.exam
              ? [
                  TextButton(
                    onPressed: () async {
                      if (await _confirmAbandon() && context.mounted) {
                        _timer?.cancel();
                        Navigator.of(context).pop();
                      }
                    },
                    child: const Text('Exit'),
                  ),
                ]
              : null,
        ),
        body: SafeArea(child: _buildBody()),
      ),
    );
  }

  Widget _buildBody() {
    switch (_stage) {
      case _Stage.intro:
        return _buildIntro();
      case _Stage.loading:
        return const Center(child: CircularProgressIndicator());
      case _Stage.exam:
        return _buildExam();
      case _Stage.results:
        return _buildResults();
    }
  }

  Widget _buildIntro() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.timer, size: 64, color: Colors.deepPurple),
          const SizedBox(height: 16),
          const Text('Mock Exam', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Text(
            '${ExamConstants.mockExamQuestionCount} questions • '
            '${ExamConstants.mockExamTimeLimitSeconds ~/ 60}-minute hard countdown • '
            'once you submit an answer, it locks — no going back.\n\n'
            'This mirrors the real exam conditions, so treat it like the real thing.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _startExam,
            style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14)),
            child: const Text('Start Mock Exam'),
          ),
        ],
      ),
    );
  }

  Widget _buildExam() {
    final session = _session!;
    final question = session.currentQuestion;
    if (question == null) return const Center(child: CircularProgressIndicator());

    final minutes = (_remainingSeconds ~/ 60).clamp(0, 999);
    final seconds = (_remainingSeconds % 60).clamp(0, 59);
    final urgent = _remainingSeconds <= 60;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Question ${session.currentQuestionIndex + 1} of ${session.totalQuestions}'),
              Row(
                children: [
                  Icon(Icons.timer_outlined, size: 18, color: urgent ? Colors.redAccent : null),
                  const SizedBox(width: 4),
                  Text(
                    '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: urgent ? Colors.redAccent : null,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(value: session.currentQuestionIndex / session.totalQuestions),
          const SizedBox(height: 16),
          Chip(
            label: Text(question.domain, style: const TextStyle(fontSize: 12)),
            backgroundColor: AppTheme.domainColor(question.domain).withAlpha(50),
          ),
          const SizedBox(height: 12),
          Text(question.question, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 16),
          Expanded(
            child: ListView(
              children: [
                for (int i = 0; i < question.options.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Material(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => _select(i),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Text(question.options[i]),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResults() {
    final result = _result!;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(
            result.isPassed ? Icons.emoji_events : Icons.replay,
            size: 64,
            color: result.isPassed ? AppTheme.xpColor : Colors.grey,
          ),
          const SizedBox(height: 12),
          Text(
            result.isPassed ? 'PASSED' : 'NOT YET — KEEP DRILLING',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: result.isPassed ? Colors.green : Colors.orangeAccent,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${result.score} / ${result.totalQuestions} correct (${result.percentage.round()}%)',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 18),
          ),
          Text(
            'Time used: ${(result.timeSpentSeconds / 60).round()} min • Passing threshold: ${ExamConstants.mockExamPassingScorePercentage.round()}%',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 20),
          const Text('Domain Breakdown', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          for (final entry in result.domainBreakdown.entries) _buildDomainRow(entry.value),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () => setState(() {
              _result = null;
              _session = null;
              _selectedIndex = null;
              _stage = _Stage.intro;
            }),
            child: const Text('Retake Mock Exam'),
          ),
          const SizedBox(height: 8),
          OutlinedButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Back to Home')),
          SizedBox(height: AppTheme.safeBottomInset(context)),
        ],
      ),
    );
  }

  Widget _buildDomainRow(DomainScore score) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: Text(score.domain, style: const TextStyle(fontWeight: FontWeight.w600))),
              Text('${score.correctAnswers}/${score.totalQuestions} (${score.percentage.round()}%)'),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: score.percentage / 100,
              minHeight: 8,
              color: AppTheme.domainColor(score.domain),
            ),
          ),
        ],
      ),
    );
  }
}
