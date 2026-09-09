import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class ChecklistStorage {
  Future<File> _file() async {
    final dir = await getApplicationDocumentsDirectory();
    return File(p.join(dir.path, 'checklist_state.json'));
  }

  Future<Set<String>> loadChecked() async {
    try {
      final file = await _file();
      if (!await file.exists()) return {};
      final decoded = jsonDecode(await file.readAsString());
      if (decoded is List) return decoded.map((e) => e.toString()).toSet();
      return {};
    } catch (_) {
      return {};
    }
  }

  Future<void> saveChecked(Set<String> checkedIds) async {
    try {
      final file = await _file();
      await file.writeAsString(jsonEncode(checkedIds.toList()));
    } catch (_) {
      // Best-effort local preference; safe to drop on write failure.
    }
  }
}
