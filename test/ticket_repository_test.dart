// ignore_for_file: subtype_of_sealed_class
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:papikost_mobile/data/models/ticket_model.dart';
import 'package:papikost_mobile/data/repositories/auth_repository.dart';
import 'package:papikost_mobile/data/repositories/ticket_repository.dart';
import 'support/auth_fixtures.dart';
import 'support/reservation_fixtures.dart';
import 'support/ticket_fixtures.dart';

class _Auth extends Mock implements FirebaseAuth {}

class _User extends Mock implements User {}

class _Firestore extends Mock implements FirebaseFirestore {}

class _Collection extends Mock
    implements CollectionReference<Map<String, dynamic>> {}

class _Document extends Mock
    implements DocumentReference<Map<String, dynamic>> {}

class _Snapshot extends Mock
    implements DocumentSnapshot<Map<String, dynamic>> {}

class _Transaction extends Mock implements Transaction {}

class _Query extends Mock implements Query<Map<String, dynamic>> {}

class _QuerySnapshot extends Mock
    implements QuerySnapshot<Map<String, dynamic>> {}

class _QueryDocument extends Mock
    implements QueryDocumentSnapshot<Map<String, dynamic>> {}

void main() {
  late _Auth auth;
  late _User user;
  late _Firestore firestore;
  late _Transaction transaction;
  late _Collection ticketCollection, reservationCollection;
  late _Document ticketDoc, userDoc, reservationDoc;
  late _Snapshot ticketSnapshot, userSnapshot, reservationSnapshot;
  late TicketRepository repository;
  setUpAll(() {
    registerFallbackValue(Duration.zero);
    registerFallbackValue(const GetOptions());
    registerFallbackValue(<String, dynamic>{});
    registerFallbackValue((Transaction _) async {});
    registerFallbackValue((Transaction _) async => testTicket);
  });
  setUp(() {
    auth = _Auth();
    user = _User();
    firestore = _Firestore();
    transaction = _Transaction();
    ticketCollection = _Collection();
    reservationCollection = _Collection();
    final users = _Collection();
    ticketDoc = _Document();
    userDoc = _Document();
    reservationDoc = _Document();
    ticketSnapshot = _Snapshot();
    userSnapshot = _Snapshot();
    reservationSnapshot = _Snapshot();
    repository = TicketRepository(auth: auth, firestore: firestore);
    when(() => auth.currentUser).thenReturn(user);
    when(() => user.uid).thenReturn(testUser.id);
    when(() => firestore.collection('users')).thenReturn(users);
    when(() => users.doc(testUser.id)).thenReturn(userDoc);
    when(() => firestore.collection('tickets')).thenReturn(ticketCollection);
    when(
      () => firestore.collection('reservations'),
    ).thenReturn(reservationCollection);
    when(() => ticketCollection.doc()).thenReturn(ticketDoc);
    when(() => ticketCollection.doc(testTicket.id)).thenReturn(ticketDoc);
    when(() => ticketDoc.id).thenReturn(testTicket.id);
    when(
      () => reservationCollection.doc(testReservation.id),
    ).thenReturn(reservationDoc);
    for (final pair in [
      (ticketDoc, ticketSnapshot),
      (userDoc, userSnapshot),
      (reservationDoc, reservationSnapshot),
    ]) {
      when(() => transaction.get(pair.$1)).thenAnswer((_) async => pair.$2);
    }
    when(() => userSnapshot.data()).thenReturn(testUser.toJson());
    when(
      () => reservationSnapshot.data(),
    ).thenReturn({...testReservation.toJson(), 'status': 'APPROVED'});
    when(() => ticketSnapshot.data()).thenReturn(testTicket.toJson());
    when(() => ticketSnapshot.exists).thenReturn(true);
    when(
      () => transaction.set<Map<String, dynamic>>(ticketDoc, any()),
    ).thenReturn(transaction);
    when(() => transaction.update(ticketDoc, any())).thenReturn(transaction);
    when(() => transaction.delete(ticketDoc)).thenReturn(transaction);
    when(
      () => firestore.runTransaction<TicketModel>(
        any(),
        timeout: any(named: 'timeout'),
        maxAttempts: any(named: 'maxAttempts'),
      ),
    ).thenAnswer(
      (invocation) =>
          (invocation.positionalArguments.first
              as Future<TicketModel> Function(Transaction))(transaction),
    );
    when(
      () => firestore.runTransaction<void>(
        any(),
        timeout: any(named: 'timeout'),
        maxAttempts: any(named: 'maxAttempts'),
      ),
    ).thenAnswer(
      (invocation) =>
          (invocation.positionalArguments.first
              as Future<void> Function(Transaction))(transaction),
    );
  });

  Future<TicketModel> create({
    String? title,
    String? description,
    String? category,
    DateTime? date,
    List<String> photos = const [],
  }) => repository.createTicket(
    reservationId: testReservation.id,
    title: title ?? testTicket.title,
    description: description ?? testTicket.description,
    category: category ?? testTicket.category,
    incidentDate: date ?? DateTime.now(),
    imageUrls: photos,
  );
  Future<TicketModel> edit() => repository.updateTicket(
    id: testTicket.id,
    title: 'Lampu kamar rusak',
    description: testTicket.description,
    category: 'LISTRIK',
    incidentDate: DateTime.now(),
  );
  void ownerLogin() => when(() => user.uid).thenReturn(testTicket.ownerId);

  test(
    'creation derives the owner, renter and property from the real approved reservation',
    () async {
      final result = await create();
      expect(result.id, testTicket.id);
      expect(result.ownerId, testReservation.ownerId);
      expect(result.kostId, testReservation.kostId);
      expect(result.renterId, testUser.id);
      expect(result.reservationId, testReservation.id);
      expect(result.status, 'PENDING');
      final data =
          verify(
                () => transaction.set<Map<String, dynamic>>(
                  ticketDoc,
                  captureAny(),
                ),
              ).captured.single
              as Map;
      expect(data['createdAt'], isA<FieldValue>());
      expect(data['updatedAt'], isA<FieldValue>());
      expect(data['incidentDate'], isA<Timestamp>());
      expect(data['ownerNote'], isNull);
    },
  );
  test('signed-out users cannot submit tickets', () async {
    when(() => auth.currentUser).thenReturn(null);
    await expectLater(create(), throwsA(isA<AuthFailure>()));
    verifyNever(() => transaction.set<Map<String, dynamic>>(ticketDoc, any()));
  });
  test(
    'pending, rejected, missing and someone elses reservations are rejected',
    () async {
      for (final data in [
        {...testReservation.toJson(), 'status': 'PENDING'},
        {...testReservation.toJson(), 'status': 'REJECTED'},
        {
          ...testReservation.toJson(),
          'status': 'APPROVED',
          'renterId': 'someone-else',
        },
        null,
      ]) {
        when(() => reservationSnapshot.data()).thenReturn(data);
        await expectLater(create(), throwsA(isA<AuthFailure>()));
      }
      verifyNever(
        () => transaction.set<Map<String, dynamic>>(ticketDoc, any()),
      );
    },
  );
  test('owner profiles cannot create renter reports', () async {
    when(
      () => userSnapshot.data(),
    ).thenReturn({...testUser.toJson(), 'role': 'OWNER'});
    await expectLater(create(), throwsA(isA<AuthFailure>()));
  });
  test(
    'invalid content, date, category and local photo files fail before writes',
    () async {
      for (final action in [
        () => create(title: 'abc'),
        () => create(description: 'short'),
        () => create(category: 'UNKNOWN'),
        () => create(date: DateTime.now().add(const Duration(days: 3))),
        () => create(date: DateTime.now().subtract(const Duration(days: 400))),
        () => create(photos: ['/data/user/0/photo.jpg']),
        () => create(photos: ['http://example.com/a.jpg']),
        () => create(photos: List.filled(4, 'https://example.com/photo.jpg')),
      ]) {
        await expectLater(action(), throwsA(isA<AuthFailure>()));
      }
      verifyNever(
        () => transaction.set<Map<String, dynamic>>(ticketDoc, any()),
      );
    },
  );
  test(
    'editing a pending ticket preserves ownership, photos and its creation time',
    () async {
      when(() => ticketSnapshot.data()).thenReturn({
        ...testTicket.toJson(),
        'imageUrls': ['https://example.com/original.jpg'],
      });
      final result = await edit();
      expect(result.createdAt, testTicket.createdAt);
      expect(result.imageUrls, ['https://example.com/original.jpg']);
      final changes =
          verify(
                () => transaction.update(ticketDoc, captureAny()),
              ).captured.single
              as Map;
      expect(changes.containsKey('ownerId'), false);
      expect(changes.containsKey('renterId'), false);
      expect(changes.containsKey('status'), false);
      expect(changes.containsKey('createdAt'), false);
    },
  );
  test('editing and deletion check the latest processing status', () async {
    for (final status in ['IN_PROGRESS', 'DONE']) {
      when(
        () => ticketSnapshot.data(),
      ).thenReturn({...testTicket.toJson(), 'status': status});
      await expectLater(edit(), throwsA(isA<AuthFailure>()));
      await expectLater(
        repository.deleteTicket(testTicket.id),
        throwsA(isA<AuthFailure>()),
      );
    }
    verifyNever(() => transaction.update(ticketDoc, any()));
    verifyNever(() => transaction.delete(ticketDoc));
  });
  test('a renter can delete their own pending report', () async {
    await repository.deleteTicket(testTicket.id);
    verify(() => transaction.delete(ticketDoc)).called(1);
  });
  test('an unrelated renter cannot edit or delete the report', () async {
    when(() => user.uid).thenReturn('another-renter');
    await expectLater(edit(), throwsA(isA<AuthFailure>()));
    await expectLater(
      repository.deleteTicket(testTicket.id),
      throwsA(isA<AuthFailure>()),
    );
  });
  test(
    'the owner can process a ticket and attach a note without editing its content',
    () async {
      ownerLogin();
      final result = await repository.updateStatus(
        testTicket.id,
        'IN_PROGRESS',
        ownerNote: '  Teknisi datang besok.  ',
      );
      expect(result.status, 'IN_PROGRESS');
      expect(result.ownerNote, 'Teknisi datang besok.');
      final changes =
          verify(
                () => transaction.update(ticketDoc, captureAny()),
              ).captured.single
              as Map;
      expect(changes.keys.toSet(), {'status', 'updatedAt', 'ownerNote'});
    },
  );
  test('status cannot skip processing or move backwards', () async {
    ownerLogin();
    await expectLater(
      repository.updateStatus(testTicket.id, 'DONE'),
      throwsA(isA<AuthFailure>()),
    );
    when(
      () => ticketSnapshot.data(),
    ).thenReturn({...testTicket.toJson(), 'status': 'DONE'});
    await expectLater(
      repository.updateStatus(testTicket.id, 'IN_PROGRESS'),
      throwsA(isA<AuthFailure>()),
    );
  });
  test('a repeated status response is idempotent', () async {
    ownerLogin();
    when(
      () => ticketSnapshot.data(),
    ).thenReturn({...testTicket.toJson(), 'status': 'IN_PROGRESS'});
    final result = await repository.updateStatus(testTicket.id, 'IN_PROGRESS');
    expect(result.status, 'IN_PROGRESS');
    verifyNever(() => transaction.update(ticketDoc, any()));
  });
  test('another account cannot process a report', () async {
    await expectLater(
      repository.updateStatus(testTicket.id, 'IN_PROGRESS'),
      throwsA(isA<AuthFailure>()),
    );
  });
  test(
    'eligible property choices use only the renters approved server documents',
    () async {
      final query = _Query(),
          snapshot = _QuerySnapshot(),
          approved = _QueryDocument(),
          pending = _QueryDocument();
      when(
        () => reservationCollection.where('renterId', isEqualTo: testUser.id),
      ).thenReturn(query);
      when(() => query.get(any())).thenAnswer((_) async => snapshot);
      when(() => snapshot.docs).thenReturn([pending, approved]);
      when(() => pending.id).thenReturn('pending-a');
      when(() => pending.data()).thenReturn(testReservation.toJson());
      when(() => approved.id).thenReturn('approved-server-id');
      when(() => approved.data()).thenReturn({
        ...testReservation.toJson(),
        'id': 'forged',
        'status': 'APPROVED',
      });
      final result = await repository.eligibleReservations(testUser.id);
      expect(result.single.id, 'approved-server-id');
    },
  );
  test(
    'a detail listener uses the document ID and decodes Firestore timestamps',
    () async {
      when(
        () => ticketDoc.snapshots(),
      ).thenAnswer((_) => Stream.value(ticketSnapshot));
      when(() => ticketSnapshot.id).thenReturn('server-ticket-id');
      when(() => ticketSnapshot.data()).thenReturn({
        ...testTicket.toJson(),
        'id': 'forged',
        'incidentDate': Timestamp.fromDate(testTicket.incidentDate),
        'createdAt': Timestamp.fromDate(testTicket.createdAt),
      });
      final result = await repository.watchById(testTicket.id).first;
      expect(result!.id, 'server-ticket-id');
      expect(result.incidentDate, testTicket.incidentDate);
    },
  );
}
