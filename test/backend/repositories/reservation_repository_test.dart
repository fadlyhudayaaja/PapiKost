// ignore_for_file: subtype_of_sealed_class
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:papikost_mobile/data/models/reservation_model.dart';
import 'package:papikost_mobile/data/repositories/auth_repository.dart';
import 'package:papikost_mobile/data/repositories/reservation_repository.dart';
import '../../support/fixtures/auth_fixtures.dart';
import '../../support/fixtures/kost_fixtures.dart';
import '../../support/fixtures/reservation_fixtures.dart';

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
  late _Collection reservations;
  late _Document reservationDoc, kostDoc, userDoc, lockDoc, previousDoc;
  late _Snapshot reservationSnapshot,
      kostSnapshot,
      userSnapshot,
      lockSnapshot,
      previousSnapshot;
  late ReservationRepository repository;
  final date = DateTime.now().add(const Duration(days: 7));

  setUpAll(() {
    registerFallbackValue(Duration.zero);
    registerFallbackValue(<String, dynamic>{});
    registerFallbackValue((Transaction _) async {});
    registerFallbackValue((Transaction _) async => testReservation);
  });
  setUp(() {
    auth = _Auth();
    user = _User();
    firestore = _Firestore();
    transaction = _Transaction();
    reservations = _Collection();
    final kosts = _Collection(), users = _Collection(), locks = _Collection();
    reservationDoc = _Document();
    kostDoc = _Document();
    userDoc = _Document();
    lockDoc = _Document();
    previousDoc = _Document();
    reservationSnapshot = _Snapshot();
    kostSnapshot = _Snapshot();
    userSnapshot = _Snapshot();
    lockSnapshot = _Snapshot();
    previousSnapshot = _Snapshot();
    repository = ReservationRepository(auth: auth, firestore: firestore);
    when(() => auth.currentUser).thenReturn(user);
    when(() => user.uid).thenReturn(testUser.id);
    when(() => firestore.collection('reservations')).thenReturn(reservations);
    when(() => firestore.collection('kost')).thenReturn(kosts);
    when(() => firestore.collection('users')).thenReturn(users);
    when(() => reservations.doc()).thenReturn(reservationDoc);
    when(() => reservations.doc('reservation-a')).thenReturn(reservationDoc);
    when(() => reservations.doc('previous')).thenReturn(previousDoc);
    when(() => reservationDoc.id).thenReturn('reservation-a');
    when(() => kosts.doc(testKost.id)).thenReturn(kostDoc);
    when(() => users.doc(testUser.id)).thenReturn(userDoc);
    when(() => userDoc.collection('reservationLocks')).thenReturn(locks);
    when(() => locks.doc(testKost.id)).thenReturn(lockDoc);
    for (final pair in [
      (userDoc, userSnapshot),
      (kostDoc, kostSnapshot),
      (lockDoc, lockSnapshot),
      (reservationDoc, reservationSnapshot),
      (previousDoc, previousSnapshot),
    ]) {
      when(() => transaction.get(pair.$1)).thenAnswer((_) async => pair.$2);
    }
    when(() => userSnapshot.data()).thenReturn(testUser.toJson());
    when(() => kostSnapshot.data()).thenReturn(testKost.toJson());
    when(() => lockSnapshot.data()).thenReturn(null);
    when(() => previousSnapshot.data()).thenReturn({'status': 'PENDING'});
    when(() => reservationSnapshot.data()).thenReturn({
      'ownerId': testKost.ownerId,
      'kostId': testKost.id,
      'status': 'PENDING',
    });
    when(
      () => transaction.set<Map<String, dynamic>>(reservationDoc, any()),
    ).thenReturn(transaction);
    when(
      () => transaction.set<Map<String, dynamic>>(lockDoc, any()),
    ).thenReturn(transaction);
    when(
      () => transaction.update(reservationDoc, any()),
    ).thenReturn(transaction);
    when(() => transaction.update(kostDoc, any())).thenReturn(transaction);
    when(
      () => firestore.runTransaction<ReservationModel>(
        any(),
        timeout: any(named: 'timeout'),
        maxAttempts: any(named: 'maxAttempts'),
      ),
    ).thenAnswer(
      (invocation) =>
          (invocation.positionalArguments.first
              as Future<ReservationModel> Function(Transaction))(transaction),
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

  Future<ReservationModel> create({
    bool split = false,
    int? members,
    DateTime? checkIn,
    String? notes,
  }) => repository.createReservation(
    kostId: testKost.id,
    isSplitBill: split,
    splitMemberCount: members,
    checkInDate: checkIn ?? date,
    notes: notes,
  );
  void ownerLogin() => when(() => user.uid).thenReturn(testKost.ownerId);

  test(
    'submission uses Firebase UID, profile, latest server price and a lock',
    () async {
      when(
        () => kostSnapshot.data(),
      ).thenReturn({...testKost.toJson(), 'pricePerMonth': 1500000});
      final result = await create(notes: '  Masuk sore  ');
      expect(result.id, 'reservation-a');
      expect(result.renterId, testUser.id);
      expect(result.ownerId, testKost.ownerId);
      expect(result.totalPrice, 1500000);
      expect(result.notes, 'Masuk sore');
      expect(result.status, 'PENDING');
      final data =
          verify(
                () => transaction.set<Map<String, dynamic>>(
                  reservationDoc,
                  captureAny(),
                ),
              ).captured.single
              as Map;
      expect(data['createdAt'], isA<FieldValue>());
      expect(data['updatedAt'], isA<FieldValue>());
      expect(data['checkInDate'], isA<Timestamp>());
      verify(
        () => transaction.set<Map<String, dynamic>>(lockDoc, {
          'renterId': testUser.id,
          'kostId': testKost.id,
          'reservationId': 'reservation-a',
        }),
      ).called(1);
    },
  );
  test('unauthenticated submissions are rejected', () async {
    when(() => auth.currentUser).thenReturn(null);
    await expectLater(create(), throwsA(isA<AuthFailure>()));
    verifyNever(
      () => transaction.set<Map<String, dynamic>>(reservationDoc, any()),
    );
  });
  test('owners cannot submit renter requests', () async {
    when(
      () => userSnapshot.data(),
    ).thenReturn({...testUser.toJson(), 'role': 'OWNER'});
    await expectLater(create(), throwsA(isA<AuthFailure>()));
  });
  test('a full property cannot receive a new request', () async {
    when(
      () => kostSnapshot.data(),
    ).thenReturn({...testKost.toJson(), 'availableRooms': 0});
    await expectLater(create(), throwsA(isA<AuthFailure>()));
  });
  test('pending and rejected rooms cannot receive reservations', () async {
    for (final status in ['PROSES', 'TOLAK', null]) {
      when(
        () => kostSnapshot.data(),
      ).thenReturn({...testKost.toJson(), 'verificationStatus': status});
      await expectLater(create(), throwsA(isA<AuthFailure>()));
    }
    verifyNever(
      () => transaction.set<Map<String, dynamic>>(reservationDoc, any()),
    );
  });
  test('patungan requires support on the property', () async {
    await expectLater(
      create(split: true, members: 2),
      throwsA(isA<AuthFailure>()),
    );
  });
  test(
    'patungan calculates each share from the current property price',
    () async {
      when(
        () => kostSnapshot.data(),
      ).thenReturn({...testKost.toJson(), 'isSplitBillAvailable': true});
      expect(
        (await create(split: true, members: 3)).pricePerPerson,
        1000000 / 3,
      );
    },
  );
  test(
    'invalid dates, notes and member counts are rejected before any writes',
    () async {
      for (final operation in [
        () => create(checkIn: DateTime.now().subtract(const Duration(days: 2))),
        () => create(checkIn: DateTime.now().add(const Duration(days: 100))),
        () => create(notes: 'x' * 2001),
        () => create(split: true, members: 5),
        () => create(split: true),
        () => create(members: 2),
      ]) {
        await expectLater(operation(), throwsA(isA<AuthFailure>()));
      }
      verifyNever(
        () => transaction.set<Map<String, dynamic>>(reservationDoc, any()),
      );
    },
  );
  test('an existing pending request prevents duplicates', () async {
    when(() => lockSnapshot.data()).thenReturn({'reservationId': 'previous'});
    await expectLater(create(), throwsA(isA<AuthFailure>()));
  });
  test('a rejected request permits a fresh submission', () async {
    when(() => lockSnapshot.data()).thenReturn({'reservationId': 'previous'});
    when(() => previousSnapshot.data()).thenReturn({'status': 'REJECTED'});
    expect((await create()).status, 'PENDING');
  });
  test(
    'approval reduces exactly one room and writes the matching reservation ID',
    () async {
      ownerLogin();
      await repository.respond('reservation-a', approve: true);
      final changes =
          verify(
                () => transaction.update(kostDoc, captureAny()),
              ).captured.single
              as Map;
      expect(changes['availableRooms'], 2);
      expect(changes['lastReservationId'], 'reservation-a');
      final response =
          verify(
                () => transaction.update(reservationDoc, captureAny()),
              ).captured.single
              as Map;
      expect(response['status'], 'APPROVED');
    },
  );
  test('repeated approval does not consume another room', () async {
    ownerLogin();
    when(
      () => reservationSnapshot.data(),
    ).thenReturn({'ownerId': testKost.ownerId, 'status': 'APPROVED'});
    await repository.respond('reservation-a', approve: true);
    verifyNever(() => transaction.update(kostDoc, any()));
    verifyNever(() => transaction.update(reservationDoc, any()));
  });
  test('rejection does not read or change property inventory', () async {
    ownerLogin();
    await repository.respond('reservation-a', approve: false);
    verifyNever(() => transaction.get(kostDoc));
    verifyNever(() => transaction.update(kostDoc, any()));
    final data =
        verify(
              () => transaction.update(reservationDoc, captureAny()),
            ).captured.single
            as Map;
    expect(data['status'], 'REJECTED');
  });
  test('a different account cannot respond to a reservation', () async {
    await expectLater(
      repository.respond('reservation-a', approve: true),
      throwsA(isA<AuthFailure>()),
    );
  });
  test('rejected reservations cannot subsequently be approved', () async {
    ownerLogin();
    when(
      () => reservationSnapshot.data(),
    ).thenReturn({'ownerId': testKost.ownerId, 'status': 'REJECTED'});
    await expectLater(
      repository.respond('reservation-a', approve: true),
      throwsA(isA<AuthFailure>()),
    );
  });
  test('an approval fails when the last room has been taken', () async {
    ownerLogin();
    when(
      () => kostSnapshot.data(),
    ).thenReturn({...testKost.toJson(), 'availableRooms': 0});
    await expectLater(
      repository.respond('reservation-a', approve: true),
      throwsA(isA<AuthFailure>()),
    );
    verifyNever(() => transaction.update(reservationDoc, any()));
  });

  test(
    'history filters by the renter UID and uses Firestore document IDs',
    () async {
      final query = _Query(),
          snapshot = _QuerySnapshot(),
          item = _QueryDocument();
      when(
        () => reservations.where('renterId', isEqualTo: testUser.id),
      ).thenReturn(query);
      when(() => query.snapshots()).thenAnswer((_) => Stream.value(snapshot));
      when(() => snapshot.docs).thenReturn([item]);
      when(() => item.id).thenReturn('server-document-id');
      when(() => item.data()).thenReturn({
        'id': 'forged-id',
        'ownerId': testKost.ownerId,
        'kostId': testKost.id,
        'kostName': testKost.name,
        'renterId': testUser.id,
        'renterName': testUser.name,
        'renterEmail': testUser.email,
        'status': 'PENDING',
        'totalPrice': 1000000,
        'checkInDate': Timestamp.fromDate(date),
        'createdAt': Timestamp.now(),
      });
      final result = await repository.watchForRenter(testUser.id).first;
      expect(result.single.id, 'server-document-id');
      expect(result.single.renterId, testUser.id);
    },
  );
}
