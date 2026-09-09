import 'package:flutter/material.dart';
import 'package:sc300_prep/core/constants/checklist_items.dart';
import 'package:sc300_prep/core/local/checklist_storage.dart';
import 'package:sc300_prep/theme/app_theme.dart';

class ChecklistScreen extends StatefulWidget {
  final Set<String>? initialChecked;
  final bool? initialLoading;
  final ChecklistStorage? storage;

  const ChecklistScreen({
    super.key,
    this.initialChecked,
    this.initialLoading,
    this.storage,
  });

  @override
  State<ChecklistScreen> createState() => _ChecklistScreenState();
}

class _ChecklistScreenState extends State<ChecklistScreen> {
  late final ChecklistStorage _storage;
  late Set<String> _checked;
  late bool _loading;

  @override
  void initState() {
    super.initState();
    _storage = widget.storage ?? ChecklistStorage();
    _checked = widget.initialChecked != null ? Set.from(widget.initialChecked!) : {};
    _loading = widget.initialLoading ?? (widget.initialChecked == null);

    if (_loading) {
      _load();
    }
  }

  Future<void> _load() async {
    final checked = await _storage.loadChecked();
    if (!mounted) return;
    setState(() {
      _checked = checked;
      _loading = false;
    });
  }

  void _toggle(String id, bool? value) {
    setState(() {
      if (value == true) {
        _checked.add(id);
      } else {
        _checked.remove(id);
      }
    });
    _storage.saveChecked(_checked);
  }

  @override
  Widget build(BuildContext context) {
    final total = ChecklistItems.items.length;
    final done = _checked.length;

    return Scaffold(
      appBar: AppBar(title: const Text('Day-of-Exam Checklist')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('$done / $total ready', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: total == 0 ? 0 : done / total,
                          minHeight: 10,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: EdgeInsets.fromLTRB(8, 8, 8, 8 + AppTheme.safeBottomInset(context)),
                    itemCount: ChecklistItems.items.length,
                    itemBuilder: (context, index) {
                      final item = ChecklistItems.items[index];
                      final isChecked = _checked.contains(item.id);
                      return Card(
                        child: CheckboxListTile(
                          value: isChecked,
                          onChanged: (v) => _toggle(item.id, v),
                          controlAffinity: ListTileControlAffinity.leading,
                          title: Text(
                            item.title,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              decoration: isChecked ? TextDecoration.lineThrough : null,
                            ),
                          ),
                          subtitle: Text(item.detail),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
