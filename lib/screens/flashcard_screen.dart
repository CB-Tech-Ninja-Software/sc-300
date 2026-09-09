import 'package:flutter/material.dart';
import 'package:sc300_prep/core/models/flashcard.dart';
import 'package:sc300_prep/core/services/spaced_repetition_engine.dart';
import 'package:sc300_prep/theme/app_theme.dart';

class FlashcardScreen extends StatefulWidget {
  const FlashcardScreen({super.key});

  @override
  State<FlashcardScreen> createState() => _FlashcardScreenState();
}

enum _Stage { loading, playing, empty, done }

class _FlashcardScreenState extends State<FlashcardScreen> {
  final _engine = SpacedRepetitionEngine();
  _Stage _stage = _Stage.loading;
  List<Flashcard> _cards = [];
  int _index = 0;
  bool _flipped = false;
  int _gotIt = 0;
  int _stillShaky = 0;
  FlashcardDeckStats? _finalStats;

  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    setState(() => _stage = _Stage.loading);
    final cards = await _engine.pickFlashcardsForReview(count: 15);
    if (!mounted) return;
    if (cards.isEmpty) {
      setState(() => _stage = _Stage.empty);
      return;
    }
    setState(() {
      _cards = cards;
      _index = 0;
      _flipped = false;
      _gotIt = 0;
      _stillShaky = 0;
      _stage = _Stage.playing;
    });
  }

  Future<void> _rate(bool isCorrect) async {
    final card = _cards[_index];
    await _engine.reviewCard(card: card, isCorrect: isCorrect);
    if (!mounted) return;
    setState(() {
      if (isCorrect) {
        _gotIt++;
      } else {
        _stillShaky++;
      }
    });

    if (_index == _cards.length - 1) {
      final stats = await _engine.getDeckStats();
      if (!mounted) return;
      setState(() {
        _finalStats = stats;
        _stage = _Stage.done;
      });
      return;
    }
    setState(() {
      _index++;
      _flipped = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Flashcards')),
      body: SafeArea(minimum: const EdgeInsets.only(bottom: 12), child: _buildBody()),
    );
  }

  Widget _buildBody() {
    switch (_stage) {
      case _Stage.loading:
        return const Center(child: CircularProgressIndicator());
      case _Stage.empty:
        return const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text('No flashcards found yet. Check back once the deck is seeded.'),
          ),
        );
      case _Stage.playing:
        return _buildCard();
      case _Stage.done:
        return _buildSummary();
    }
  }

  Widget _buildCard() {
    final card = _cards[_index];
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LinearProgressIndicator(value: _index / _cards.length),
          const SizedBox(height: 8),
          Text('Card ${_index + 1} of ${_cards.length}', style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 8),
          Chip(
            label: Text(card.domain, style: const TextStyle(fontSize: 12)),
            backgroundColor: AppTheme.domainColor(card.domain).withAlpha(50),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _flipped = !_flipped),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                transitionBuilder: (child, animation) => ScaleTransition(scale: animation, child: child),
                child: Card(
                  key: ValueKey(_flipped),
                  elevation: 3,
                  color: _flipped
                      ? Theme.of(context).colorScheme.primaryContainer
                      : Theme.of(context).colorScheme.surfaceContainerHighest,
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Center(
                      child: SingleChildScrollView(
                        child: Text(
                          _flipped ? card.back : card.front,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: _flipped ? 16 : 20,
                            fontWeight: _flipped ? FontWeight.normal : FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _flipped ? 'Tap to flip back' : 'Tap card to flip',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.grey, fontSize: 12),
          ),
          const SizedBox(height: 16),
          if (_flipped)
            Padding(
              padding: EdgeInsets.only(bottom: AppTheme.safeBottomInset(context)),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _rate(false),
                      style: OutlinedButton.styleFrom(foregroundColor: Colors.redAccent, padding: const EdgeInsets.symmetric(vertical: 14)),
                      child: const Text('Still Shaky'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => _rate(true),
                      style: FilledButton.styleFrom(backgroundColor: Colors.green, padding: const EdgeInsets.symmetric(vertical: 14)),
                      child: const Text('Got It'),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSummary() {
    final stats = _finalStats;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.style, size: 64, color: AppTheme.seedColor),
          const SizedBox(height: 16),
          Text('$_gotIt got it • $_stillShaky still shaky', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          if (stats != null) ...[
            const SizedBox(height: 8),
            Text('Deck mastery: ${stats.masteryPercentage.round()}%', style: const TextStyle(color: Colors.grey)),
          ],
          const SizedBox(height: 24),
          FilledButton(onPressed: _start, child: const Text('Review Again')),
          const SizedBox(height: 8),
          OutlinedButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Back to Home')),
        ],
      ),
    );
  }
}
