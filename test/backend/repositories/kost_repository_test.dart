// SDK references and transactions are mocked to test the Firestore boundary.
// ignore_for_file: subtype_of_sealed_class
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:papikost_mobile/data/models/kost_model.dart';
import 'package:papikost_mobile/data/repositories/auth_repository.dart';
import 'package:papikost_mobile/data/repositories/kost_repository.dart';

import '../../support/fixtures/kost_fixtures.dart';

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
  late _Collection kostCollection;
  late _Collection userCollection;
  late _Document kostDocument;
  late _Document userDocument;
  late _Snapshot kostSnapshot;
  late _Snapshot userSnapshot;
  late _Transaction transaction;
  late _Query ownerQuery;
  late _QuerySnapshot results;
  late _QueryDocument result;
  late KostRepository repository;

  setUpAll(() {
    registerFallbackValue(const GetOptions());
    registerFallbackValue(Duration.zero);
    registerFallbackValue(<String, dynamic>{});
    registerFallbackValue((Transaction _) async => testKost);
    registerFallbackValue((Transaction _) async {});
  });
  setUp(() {
    auth = _Auth();
    user = _User();
    firestore = _Firestore();
    kostCollection = _Collection();
    userCollection = _Collection();
    kostDocument = _Document();
    userDocument = _Document();
    kostSnapshot = _Snapshot();
    userSnapshot = _Snapshot();
    transaction = _Transaction();
    ownerQuery = _Query();
    results = _QuerySnapshot();
    result = _QueryDocument();
    repository = KostRepository(auth: auth, firestore: firestore);
    when(() => auth.currentUser).thenReturn(user);
    when(() => user.uid).thenReturn(testKost.ownerId);
    when(() => firestore.collection('users')).thenReturn(userCollection);
    when(() => firestore.collection('kost')).thenReturn(kostCollection);
    when(() => userCollection.doc(testKost.ownerId)).thenReturn(userDocument);
    when(() => userDocument.get(any())).thenAnswer((_) async => userSnapshot);
    when(
      () => userSnapshot.data(),
    ).thenReturn({'name': 'Owner A', 'role': 'OWNER'});
    when(() => kostCollection.doc()).thenReturn(kostDocument);
    when(() => kostCollection.doc(testKost.id)).thenReturn(kostDocument);
    when(() => kostDocument.id).thenReturn(testKost.id);
    when(() => kostDocument.set(any())).thenAnswer((_) async {});
    when(() => kostDocument.get(any())).thenAnswer((_) async => kostSnapshot);
    when(() => kostSnapshot.exists).thenReturn(true);
    when(() => kostSnapshot.data()).thenReturn(testKost.toJson());
    when(
      () => transaction.get(kostDocument),
    ).thenAnswer((_) async => kostSnapshot);
    when(() => transaction.update(kostDocument, any())).thenReturn(transaction);
    when(() => transaction.delete(kostDocument)).thenReturn(transaction);
    when(
      () => firestore.runTransaction<KostModel>(
        any(),
        timeout: any(named: 'timeout'),
        maxAttempts: any(named: 'maxAttempts'),
      ),
    ).thenAnswer((invocation) async {
      final handler =
          invocation.positionalArguments.first
              as Future<KostModel> Function(Transaction);
      return handler(transaction);
    });
    when(
      () => firestore.runTransaction<void>(
        any(),
        timeout: any(named: 'timeout'),
        maxAttempts: any(named: 'maxAttempts'),
      ),
    ).thenAnswer((invocation) async {
      final handler =
          invocation.positionalArguments.first
              as Future<void> Function(Transaction);
      await handler(transaction);
    });
    when(
      () => kostCollection.where('ownerId', isEqualTo: testKost.ownerId),
    ).thenReturn(ownerQuery);
    when(() => ownerQuery.get(any())).thenAnswer((_) async => results);
    when(
      () => kostCollection.snapshots(),
    ).thenAnswer((_) => Stream.value(results));
    when(() => results.docs).thenReturn([result]);
    when(() => result.id).thenReturn(testKost.id);
    when(
      () => result.data(),
    ).thenReturn({...testKost.toJson(), 'id': 'forged-id'});
  });

  Future<KostModel> create({String? photoUrl}) => repository.createKost(
    name: testKost.name,
    address: testKost.address,
    city: testKost.city,
    pricePerMonth: testKost.pricePerMonth,
    type: testKost.type,
    totalRooms: 5,
    isSplitBillAvailable: false,
    facilities: ['WiFi'],
    photoUrl: photoUrl,
  );
  Future<KostModel> update(int rooms) => repository.updateKost(
    id: testKost.id,
    name: testKost.name,
    address: testKost.address,
    city: testKost.city,
    pricePerMonth: testKost.pricePerMonth,
    type: testKost.type,
    totalRooms: rooms,
    isSplitBillAvailable: false,
    facilities: ['WiFi'],
  );

  test(
    'listing creation uses the authenticated owner and server timestamps',
    () async {
      final created = await create();
      final data =
          verify(() => kostDocument.set(captureAny())).captured.single as Map;
      expect(created.id, testKost.id);
      expect(data['ownerId'], testKost.ownerId);
      expect(data['ownerName'], 'Owner A');
      expect(data['availableRooms'], 5);
      expect(data['createdAt'], isA<FieldValue>());
      expect(data['updatedAt'], isA<FieldValue>());
      expect(data['rating'], isNull);
      expect(data['reviewCount'], 0);
      expect(data['verificationStatus'], 'PROSES');
      expect(created.verificationStatus, 'PROSES');
      expect(data['reviewedBy'], isNull);
      expect(data['reviewedAt'], isNull);
      expect(data.containsKey('id'), false);
    },
  );
  test('a renter profile cannot create a listing', () async {
    when(
      () => userSnapshot.data(),
    ).thenReturn({'name': 'Renter', 'role': 'RENTER'});
    await expectLater(create(), throwsA(isA<AuthFailure>()));
    verifyNever(() => kostDocument.set(any()));
  });
  test('local file paths are rejected before accessing Firestore', () async {
    await expectLater(
      create(photoUrl: '/data/private/photo.jpg'),
      throwsA(isA<AuthFailure>()),
    );
    verifyNever(() => firestore.collection(any()));
  });
  test('owner listings are queried using the Firebase UID', () async {
    final list = await repository.fetchForOwner(testKost.ownerId);
    expect(list.single.id, testKost.id);
    verify(
      () => kostCollection.where('ownerId', isEqualTo: testKost.ownerId),
    ).called(1);
  });
  test(
    'catalogue updates use document IDs instead of an embedded ID field',
    () async {
      expect((await repository.watchAll().first).single.id, testKost.id);
    },
  );
  test(
    'editing room totals preserves occupied rooms in a transaction',
    () async {
      final updated = await update(6);
      final data =
          verify(
                () => transaction.update(kostDocument, captureAny()),
              ).captured.single
              as Map;
      expect(updated.availableRooms, 4);
      expect(data['availableRooms'], 4);
      expect(data.containsKey('ownerId'), false);
      expect(data.containsKey('createdAt'), false);
      expect(data['verificationStatus'], 'PROSES');
      expect(data['rejectionReason'], isNull);
      expect(data['reviewedBy'], isNull);
      expect(data['reviewedAt'], isNull);
    },
  );
  test('room totals cannot be reduced below occupied rooms', () async {
    await expectLater(update(1), throwsA(isA<AuthFailure>()));
    verifyNever(() => transaction.update(kostDocument, any()));
  });
  test(
    'catalogue excludes pending, rejected and legacy unreviewed rooms',
    () async {
      for (final status in ['PROSES', 'TOLAK', null]) {
        final data = {...testKost.toJson(), 'verificationStatus': status};
        when(() => result.data()).thenReturn(data);
        expect(await repository.watchAll().first, isEmpty);
      }
    },
  );
  test('editing a property belonging to another owner is rejected', () async {
    when(
      () => kostSnapshot.data(),
    ).thenReturn({...testKost.toJson(), 'ownerId': 'other-owner'});
    await expectLater(update(6), throwsA(isA<AuthFailure>()));
    verifyNever(() => transaction.update(kostDocument, any()));
  });
  test('occupied properties cannot be deleted', () async {
    await expectLater(
      repository.deleteKost(testKost.id),
      throwsA(isA<AuthFailure>()),
    );
    verifyNever(() => transaction.delete(kostDocument));
  });
  test('a vacant property can be deleted inside a transaction', () async {
    when(
      () => kostSnapshot.data(),
    ).thenReturn({...testKost.toJson(), 'availableRooms': 5});
    await repository.deleteKost(testKost.id);
    verify(() => transaction.delete(kostDocument)).called(1);
  });
}
