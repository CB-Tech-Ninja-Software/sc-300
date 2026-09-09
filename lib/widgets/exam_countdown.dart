import 'dart:async';
import 'package:flutter/material.dart';
import 'package:sc300_prep/core/constants/exam_constants.dart';

class ExamCountdown extends StatefulWidget {
  const ExamCountdown({super.key});

  @override
  State<ExamCountdown> createState() => _ExamCountdownState();
}

class _ExamCountdownState extends State<ExamCountdown> {
  Timer? _timer;
  Duration _remaining = Duration.zero;

  bool get _hasTarget => ExamConstants.targetExamDateIso != null;

  @override
  void initState() {
    super.initState();
    if (_hasTarget) {
      _tick();
      _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
    }
  }

  void _tick() {
    final iso = ExamConstants.targetExamDateIso;
    if (iso == null) return;
    final target = DateTime.tryParse(iso);
    if (target == null) return;
    final diff = target.difference(DateTime.now());
    setState(() => _remaining = diff.isNegative ? Duration.zero : diff);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [scheme.primary.withAlpha(60), scheme.primary.withAlpha(15)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: scheme.primary.withAlpha(90)),
      ),
      child: _hasTarget ? _buildCountdown(scheme) : _buildNoDateSet(scheme),
    );
  }

  Widget _buildNoDateSet(ColorScheme scheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'EXAM NOT YET SCHEDULED',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.5, color: scheme.primary),
        ),
        const SizedBox(height: 10),
        const Text(
          'Book your SC-300 exam date to start the countdown. Keep studying in the meantime.',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _buildCountdown(ColorScheme scheme) {
    final isExamTime = _remaining == Duration.zero;
    final days = _remaining.inDays;
    final hours = _remaining.inHours % 24;
    final minutes = _remaining.inMinutes % 60;
    final seconds = _remaining.inSeconds % 60;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isExamTime ? "IT'S EXAM TIME" : 'TIME UNTIL EXAM',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.5, color: scheme.primary),
        ),
        const SizedBox(height: 10),
        if (isExamTime)
          const Text('Go show them what you know. 🔥', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))
        else
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _unit('$days', 'days'),
              _unit(hours.toString().padLeft(2, '0'), 'hrs'),
              _unit(minutes.toString().padLeft(2, '0'), 'min'),
              _unit(seconds.toString().padLeft(2, '0'), 'sec'),
            ],
          ),
      ],
    );
  }

  Widget _unit(String value, String label) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }
}
