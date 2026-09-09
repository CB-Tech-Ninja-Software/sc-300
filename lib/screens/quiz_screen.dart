import 'package:flutter/material.dart';
import 'package:sc300_prep/core/models/question.dart';
import 'package:sc300_prep/core/services/question_engine.dart';
import 'package:sc300_prep/theme/app_theme.dart';

class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

enum _QuizStage { intro, loading, playing, empty, done }

class _QuizScreenState extends State<QuizScreen> {
  final _engine = QuestionEngine();
  _QuizStage _stage = _QuizStage.intro;
  List<Question> _questions = [];
  int _index = 0;
  int? _selectedIndex;
  QuestionAnswerResult? _result;
  int _correctCount = 0;
  int _xpTotal = 0;
  DateTime _questionStartedAt = DateTime.now();

  Future<void> _start() async {
    setState(() => _stage = _QuizStage.loading);
    final questions = await _engine.pickWeightedQuestions(count: 10);
    if (!mounted) return;
    if (questions.isEmpty) {
      setState(() => _stage = _QuizStage.empty);
      return;
    }
    setState(() {
      _questions = questions;
      _index = 0;
      _correctCount = 0;
      _xpTotal = 0;
      _selectedIndex = null;
      _result = null;
      _questionStartedAt = DateTime.now();
      _stage = _QuizStage.playing;
    });
  }

  Future<void> _select(int optionIndex) async {
    if (_selectedIndex != null) return;
    final question = _questions[_index];
    final spent = DateTime.now().difference(_questionStartedAt).inSeconds;
    final result = await _engine.submitAnswer(
      question: question,
      selectedIndex: optionIndex,
      timeSpentSeconds: spent,
      mode: 'quiz',
    );
    if (!mounted) return;
    setState(() {
      _selectedIndex = optionIndex;
      _result = result;
      if (result.isCorrect) _correctCount++;
      _xpTotal += result.xpEarned;
    });
  }

  void _next() {
    if (_index == _questions.length - 1) {
      setState(() => _stage = _QuizStage.done);
      return;
    }
    setState(() {
      _index++;
      _selectedIndex = null;
      _result = null;
      _questionStartedAt = DateTime.now();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Weighted Quiz')),
      body: SafeArea(minimum: const EdgeInsets.only(bottom: 12), child: _buildBody()),
    );
  }

  Widget _buildBody() {
    switch (_stage) {
      case _QuizStage.intro:
        return _buildIntro();
      case _QuizStage.loading:
        return const Center(child: CircularProgressIndicator());
      case _QuizStage.empty:
        return const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text('No questions found yet. Check back once the question bank is seeded.'),
          ),
        );
      case _QuizStage.playing:
        return _buildQuestion();
      case _QuizStage.done:
        return _buildSummary();
    }
  }

  Widget _buildIntro() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.quiz, size: 64, color: AppTheme.seedColor),
          const SizedBox(height: 16),
          const Text(
            'Domain-weighted quiz',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            '10 questions, sampled to match real exam point value across all skill domains.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          FilledButton(onPressed: _start, child: const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text('Start Quiz'),
          )),
        ],
      ),
    );
  }

  Widget _buildQuestion() {
    final question = _questions[_index];
    final answered = _selectedIndex != null;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LinearProgressIndicator(value: (_index) / _questions.length),
          const SizedBox(height: 8),
          Text('Question ${_index + 1} of ${_questions.length}', style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 8),
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
                    child: _buildOption(question, i),
                  ),
                if (answered && _result != null) ...[
                  const SizedBox(height: 8),
                  _buildExplanation(_result!),
                ],
              ],
            ),
          ),
          if (answered)
            Padding(
              padding: EdgeInsets.only(bottom: AppTheme.safeBottomInset(context)),
              child: FilledButton(
                onPressed: _next,
                style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                child: Text(_index == _questions.length - 1 ? 'Finish' : 'Next Question'),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildOption(Question question, int i) {
    final answered = _selectedIndex != null;
    Color? bg;
    IconData? icon;
    if (answered) {
      if (i == question.correctIndex) {
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
              Expanded(child: Text(question.options[i])),
              if (icon != null) Icon(icon, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExplanation(QuestionAnswerResult result) {
    return Card(
      color: (result.isCorrect ? Colors.green : Colors.red).withAlpha(30),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(result.isCorrect ? Icons.celebration : Icons.info_outline, size: 18),
                const SizedBox(width: 8),
                Text(
                  result.isCorrect ? 'Correct! +${result.xpEarned} XP' : 'Not quite',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(result.explanation),
          ],
        ),
      ),
    );
  }

  Widget _buildSummary() {
    final total = _questions.length;
    final pct = total == 0 ? 0 : (_correctCount / total * 100).round();
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.emoji_events, size: 64, color: AppTheme.xpColor),
          const SizedBox(height: 16),
          Text('$_correctCount / $total correct ($pct%)', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('+$_xpTotal XP earned', style: const TextStyle(fontSize: 16, color: AppTheme.xpColor)),
          const SizedBox(height: 24),
          FilledButton(onPressed: _start, child: const Text('Play Again')),
          const SizedBox(height: 8),
          OutlinedButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Back to Home')),
        ],
      ),
    );
  }
}
