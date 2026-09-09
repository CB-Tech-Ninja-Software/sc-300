import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sc300_prep/core/database/app_database.dart';
import 'package:sc300_prep/core/models/reference_note.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('ReferenceNote Model & Database Tests', () {
    late AppDatabase db;

    setUp(() async {
      db = AppDatabase.instance;
      final inMemoryDb = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
      await db.init(dbOverride: inMemoryDb);
    });

    tearDown(() async {
      await db.close();
    });

    test('ReferenceNote serialization and deserialization', () {
      final json = {
        'id': 'rn_test_1',
        'domain': 'Implement and manage user identities',
        'topic': 'Administrative Units',
        'title': 'Administrative Units in Entra ID',
        'body': 'Markdown content...',
        'sourceUrl': 'https://learn.microsoft.com/en-us/entra/identity/role-based-access-control/administrative-units',
        'bookmarked': true,
        'lastReadAt': '2026-09-01T18:00:00.000Z',
      };

      final note = ReferenceNote.fromJson(json);
      expect(note.id, 'rn_test_1');
      expect(note.domain, 'Implement and manage user identities');
      expect(note.topic, 'Administrative Units');
      expect(note.title, 'Administrative Units in Entra ID');
      expect(note.body, 'Markdown content...');
      expect(note.sourceUrl, 'https://learn.microsoft.com/en-us/entra/identity/role-based-access-control/administrative-units');
      expect(note.bookmarked, isTrue);
      expect(note.lastReadAt, isNotNull);

      final map = note.toMap();
      final fromMap = ReferenceNote.fromMap(map);
      expect(fromMap.id, note.id);
      expect(fromMap.bookmarked, isTrue);
      expect(fromMap.sourceUrl, note.sourceUrl);

      final updated = note.copyWith(bookmarked: false, title: 'Updated Title');
      expect(updated.bookmarked, isFalse);
      expect(updated.title, 'Updated Title');
    });

    test('ReferenceNote Database CRUD and filtering', () async {
      final note1 = ReferenceNote(
        id: 'rn_1',
        domain: 'Implement and manage user identities',
        topic: 'Topic A',
        title: 'Title 1',
        body: 'Body 1',
        bookmarked: false,
      );

      final note2 = ReferenceNote(
        id: 'rn_2',
        domain: 'Implement authentication and access management',
        topic: 'Topic B',
        title: 'Title 2',
        body: 'Body 2',
        bookmarked: true,
      );

      await db.batchInsertReferenceNotes([note1, note2]);

      final all = await db.getAllReferenceNotes();
      expect(all.length, 2);

      final identitiesOnly = await db.getAllReferenceNotes(domain: 'Implement and manage user identities');
      expect(identitiesOnly.length, 1);
      expect(identitiesOnly.first.id, 'rn_1');

      final bookmarkedOnly = await db.getAllReferenceNotes(bookmarkedOnly: true);
      expect(bookmarkedOnly.length, 1);
      expect(bookmarkedOnly.first.id, 'rn_2');

      await db.toggleReferenceNoteBookmark('rn_1', true);
      final bookmarkedNow = await db.getAllReferenceNotes(bookmarkedOnly: true);
      expect(bookmarkedNow.length, 2);

      await db.markReferenceNoteAsRead('rn_1');
      final queried1 = await db.getReferenceNoteById('rn_1');
      expect(queried1?.lastReadAt, isNotNull);
    });
  });
}
