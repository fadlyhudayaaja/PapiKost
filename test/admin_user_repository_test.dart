// ignore_for_file: subtype_of_sealed_class
import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:papikost_mobile/data/models/user_model.dart';
import 'package:papikost_mobile/data/repositories/admin_user_repository.dart';
import 'support/verification_fixtures.dart';

class _Firestore extends Mock implements FirebaseFirestore {}

class _Collection extends Mock
    implements CollectionReference<Map<String, dynamic>> {}

class _Snapshot extends Mock implements QuerySnapshot<Map<String, dynamic>> {}

class _Document extends Mock
    implements QueryDocumentSnapshot<Map<String, dynamic>> {}

void main() {
  late _Firestore firestore;
  late _Collection users;
  late _Snapshot snapshot;
  late AdminUserRepository repository;
  setUpAll(() {
    registerFallbackValue(const GetOptions());
  });
  setUp(() {
    firestore = _Firestore();
    users = _Collection();
    snapshot = _Snapshot();
    repository = AdminUserRepository(firestore: firestore);
    when(() => firestore.collection('users')).thenReturn(users);
    when(() => users.get(any())).thenAnswer((_) async => snapshot);
    when(() => users.snapshots()).thenAnswer((_) => const Stream.empty());
    when(() => snapshot.docs).thenReturn([]);
  });
  test(
    'user list reads the server before treating the collection as empty',
    () async {
      expect(await repository.watchUsers().first, isEmpty);
      final options =
          verify(() => users.get(captureAny())).captured.single as GetOptions;
      expect(options.source, Source.server);
    },
  );
  test(
    'permission error is surfaced instead of displaying a cached empty list',
    () async {
      when(() => users.get(any())).thenThrow(
        FirebaseException(plugin: 'cloud_firestore', code: 'permission-denied'),
      );
      await expectLater(
        repository.watchUsers(),
        emitsError(isA<FirebaseException>()),
      );
      verifyNever(() => users.snapshots());
    },
  );
  test(
    'Firebase document UID is authoritative and native timestamp is decoded',
    () async {
      final document = _Document();
      final date = DateTime(2026, 11, 12);
      when(() => document.id).thenReturn(verificationOwner.id);
      when(() => document.data()).thenReturn({
        ...verificationOwner.toJson(),
        'id': 'old-numeric-id',
        'createdAt': Timestamp.fromDate(date),
      });
      when(() => snapshot.docs).thenReturn([document]);
      final result = await repository.watchUsers().first;
      expect(result.single.id, verificationOwner.id);
      expect(result.single.createdAt, date);
    },
  );
  test('legacy ISO profile timestamps remain readable', () {
    final user = UserModel.fromFirestore('actual-uid', {
      ...verificationOwner.toJson(),
      'createdAt': '2026-11-12T10:00:00.000',
    });
    expect(user.id, 'actual-uid');
    expect(user.createdAt, DateTime(2026, 11, 12, 10));
  });
  test('initial load is followed by live account changes', () async {
    final controller = StreamController<QuerySnapshot<Map<String, dynamic>>>();
    when(() => users.snapshots()).thenAnswer((_) => controller.stream);
    final events = <List<UserModel>>[];
    final subscription = repository.watchUsers().listen(events.add);
    await Future<void>.delayed(Duration.zero);
    expect(events, hasLength(1));
    controller.add(snapshot);
    await Future<void>.delayed(Duration.zero);
    expect(events, hasLength(2));
    await subscription.cancel();
    await controller.close();
  });
}
