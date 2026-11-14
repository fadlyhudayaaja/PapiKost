// ignore_for_file: subtype_of_sealed_class
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:papikost_mobile/data/repositories/auth_repository.dart';
import 'package:papikost_mobile/data/repositories/owner_verification_repository.dart';
import 'support/kost_fixtures.dart';
import 'package:papikost_mobile/data/models/owner_submission.dart';

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

class _QuerySnapshot extends Mock
    implements QuerySnapshot<Map<String, dynamic>> {}

class _QueryDocument extends Mock
    implements QueryDocumentSnapshot<Map<String, dynamic>> {}

void main() {
  late _Auth auth;
  late _User user;
  late _Firestore firestore;
  late _Transaction transaction;
  late _Document adminRef, ownerRef, verificationRef;
  late _Document kostRef;
  late _Snapshot kost;
  late _Collection kosts, verifications;
  late _Snapshot admin, owner, verification;
  late OwnerVerificationRepository repository;
  setUpAll(() {
    registerFallbackValue(Duration.zero);
    registerFallbackValue(<String, dynamic>{});
    registerFallbackValue((Transaction _) async {});
    registerFallbackValue(_Document());
    registerFallbackValue(const GetOptions());
  });
  setUp(() {
    auth = _Auth();
    user = _User();
    firestore = _Firestore();
    transaction = _Transaction();
    adminRef = _Document();
    ownerRef = _Document();
    verificationRef = _Document();
    admin = _Snapshot();
    owner = _Snapshot();
    verification = _Snapshot();
    final users = _Collection();
    verifications = _Collection();
    kosts = _Collection();
    kostRef = _Document();
    kost = _Snapshot();
    repository = OwnerVerificationRepository(auth: auth, firestore: firestore);
    when(() => auth.currentUser).thenReturn(user);
    when(() => user.uid).thenReturn('admin-a');
    when(() => firestore.collection('users')).thenReturn(users);
    when(() => firestore.collection('kost')).thenReturn(kosts);
    when(() => kosts.doc(testKost.id)).thenReturn(kostRef);
    when(
      () => firestore.collection('ownerVerifications'),
    ).thenReturn(verifications);
    when(() => users.doc('admin-a')).thenReturn(adminRef);
    when(() => users.doc('owner-a')).thenReturn(ownerRef);
    when(() => verifications.doc('owner-a')).thenReturn(verificationRef);
    for (final pair in [
      (adminRef, admin),
      (ownerRef, owner),
      (verificationRef, verification),
      (kostRef, kost),
    ]) {
      when(() => transaction.get(pair.$1)).thenAnswer((_) async => pair.$2);
      when(() => transaction.update(pair.$1, any())).thenReturn(transaction);
    }
    when(
      () => transaction.set<Map<String, dynamic>>(verificationRef, any()),
    ).thenReturn(transaction);
    when(() => admin.data()).thenReturn({'role': 'ADMIN'});
    when(
      () => kost.data(),
    ).thenReturn({...testKost.toJson(), 'verificationStatus': 'PROSES'});
    when(() => owner.data()).thenReturn({
      'role': 'OWNER',
      'isVerified': false,
      'name': 'Owner A',
      'email': 'owner@example.com',
      'phone': '081234567890',
    });
    when(
      () => verification.data(),
    ).thenReturn({'ownerId': 'owner-a', 'status': 'PROSES'});
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

  Future<void> submit({
    String ktp = '1234567890123456',
    String photo = 'https://example.com/ktp.jpg',
  }) => repository.submit(
    ktpNumber: ktp,
    propertyName: 'Kost Melati',
    propertyAddress: 'Jalan Melati 10',
    propertyType: 'CAMPUR',
    ktpImageUrl: photo,
    sertifikatImageUrl: 'https://example.com/sertifikat.jpg',
    fotoRumahImageUrl: 'https://example.com/kost.jpg',
  );

  test(
    'approval persists decision, audit and verified flag in one transaction',
    () async {
      await repository.review('owner-a', approve: true);
      final update =
          verify(
                () => transaction.update(verificationRef, captureAny()),
              ).captured.single
              as Map;
      expect(update['status'], 'ACC');
      expect(update['reviewedBy'], 'admin-a');
      expect(update['reviewedAt'], isA<FieldValue>());
      expect(update['rejectionReason'], isNull);
      verify(
        () => transaction.update(ownerRef, {'isVerified': true}),
      ).called(1);
      verify(
        () => firestore.runTransaction<void>(
          any(),
          timeout: any(named: 'timeout'),
          maxAttempts: any(named: 'maxAttempts'),
        ),
      ).called(1);
    },
  );
  test(
    'room approval updates the listing without verifying owner identity',
    () async {
      await repository.review('kost/${testKost.id}', approve: true);
      final changes =
          verify(
                () => transaction.update(kostRef, captureAny()),
              ).captured.single
              as Map;
      expect(changes['verificationStatus'], 'ACC');
      expect(changes['reviewedBy'], 'admin-a');
      expect(changes['reviewedAt'], isA<FieldValue>());
      verifyNever(() => transaction.update(ownerRef, any()));
      verifyNever(() => transaction.update(verificationRef, any()));
    },
  );
  test(
    'room rejection requires a reason and stale or non-admin decisions fail',
    () async {
      await expectLater(
        repository.review('kost/${testKost.id}', approve: false, reason: ' '),
        throwsA(isA<AuthFailure>()),
      );
      verifyNever(() => transaction.update(kostRef, any()));
      await repository.review(
        'kost/${testKost.id}',
        approve: false,
        reason: '  Harga kamar tidak sesuai.  ',
      );
      final changes =
          verify(
                () => transaction.update(kostRef, captureAny()),
              ).captured.single
              as Map;
      expect(changes['verificationStatus'], 'TOLAK');
      expect(changes['rejectionReason'], 'Harga kamar tidak sesuai.');
      when(
        () => kost.data(),
      ).thenReturn({...testKost.toJson(), 'verificationStatus': 'ACC'});
      await expectLater(
        repository.review('kost/${testKost.id}', approve: true),
        throwsA(isA<AuthFailure>()),
      );
      when(() => admin.data()).thenReturn({'role': 'OWNER'});
      await expectLater(
        repository.review('kost/${testKost.id}', approve: true),
        throwsA(isA<AuthFailure>()),
      );
      verifyNever(() => transaction.update(kostRef, any()));
    },
  );
  test(
    'legacy rooms can be reviewed without resubmitting owner documents',
    () async {
      final data = {...testKost.toJson()}..remove('verificationStatus');
      when(() => kost.data()).thenReturn(data);
      await repository.review('kost/${testKost.id}', approve: true);
      verify(() => transaction.update(kostRef, any())).called(1);
    },
  );
  test(
    'admin queue merges owner applications and live rooms with distinct IDs',
    () async {
      final ownerSnapshot = _QuerySnapshot(), roomSnapshot = _QuerySnapshot();
      final roomDoc = _QueryDocument();
      final ownerUpdates =
          StreamController<QuerySnapshot<Map<String, dynamic>>>();
      final roomUpdates =
          StreamController<QuerySnapshot<Map<String, dynamic>>>();
      when(
        () => verifications.get(any()),
      ).thenAnswer((_) async => ownerSnapshot);
      when(() => kosts.get(any())).thenAnswer((_) async => roomSnapshot);
      when(
        () => verifications.snapshots(),
      ).thenAnswer((_) => ownerUpdates.stream);
      when(() => kosts.snapshots()).thenAnswer((_) => roomUpdates.stream);
      final ownerDoc = _QueryDocument();
      when(() => ownerDoc.id).thenReturn('owner-a');
      when(() => ownerDoc.data()).thenReturn({
        'name': 'Owner A',
        'email': 'owner@example.com',
        'phone': '081234567890',
        'ktpNumber': '1234567890123456',
        'propertyName': 'Kost Lama',
        'propertyAddress': 'Jalan Lama',
        'propertyType': 'CAMPUR',
        'ktpImageUrl': '',
        'sertifikatImageUrl': '',
        'fotoRumahImageUrl': '',
        'status': 'PROSES',
      });
      when(() => ownerSnapshot.docs).thenReturn([ownerDoc]);
      when(() => roomSnapshot.docs).thenReturn([]);
      when(() => roomDoc.id).thenReturn(testKost.id);
      final legacy = {...testKost.toJson()}..remove('verificationStatus');
      when(() => roomDoc.data()).thenReturn(legacy);
      final values = <List<OwnerSubmission>>[];
      final subscription = repository.watchAll().listen(values.add);
      await Future<void>.delayed(Duration.zero);
      expect(values.last.single.id, 'owner-a');
      when(() => roomSnapshot.docs).thenReturn([roomDoc]);
      roomUpdates.add(roomSnapshot);
      await Future<void>.delayed(Duration.zero);
      expect(
        values.last.map((s) => s.id),
        containsAll(['owner-a', 'kost/${testKost.id}']),
      );
      expect(
        values.last.where((s) => s.isKostSubmission).single.status,
        VerificationStatus.proses,
      );
      when(
        () => roomDoc.data(),
      ).thenReturn({...testKost.toJson(), 'verificationStatus': 'ACC'});
      roomUpdates.add(roomSnapshot);
      await Future<void>.delayed(Duration.zero);
      expect(
        values.last.where((s) => s.isKostSubmission).single.status,
        VerificationStatus.acc,
      );
      await subscription.cancel();
      expect(ownerUpdates.hasListener, false);
      expect(roomUpdates.hasListener, false);
      await ownerUpdates.close();
      await roomUpdates.close();
    },
  );
  test(
    'rejection records trimmed reason and leaves owner unverified',
    () async {
      await repository.review(
        'owner-a',
        approve: false,
        reason: '  Foto KTP tidak terbaca.  ',
      );
      final update =
          verify(
                () => transaction.update(verificationRef, captureAny()),
              ).captured.single
              as Map;
      expect(update['status'], 'TOLAK');
      expect(update['rejectionReason'], 'Foto KTP tidak terbaca.');
      verify(
        () => transaction.update(ownerRef, {'isVerified': false}),
      ).called(1);
    },
  );
  test(
    'a non-admin cannot review even if the UI calls the repository',
    () async {
      when(() => admin.data()).thenReturn({'role': 'OWNER'});
      await expectLater(
        repository.review('owner-a', approve: true),
        throwsA(isA<AuthFailure>()),
      );
      verifyNever(() => transaction.update(any(), any()));
    },
  );
  test('a stale decision cannot overwrite an existing decision', () async {
    for (final status in ['ACC', 'TOLAK']) {
      when(
        () => verification.data(),
      ).thenReturn({'ownerId': 'owner-a', 'status': status});
      await expectLater(
        repository.review('owner-a', approve: true),
        throwsA(isA<AuthFailure>()),
      );
    }
    verifyNever(() => transaction.update(any(), any()));
  });
  test('invalid rejection is refused before contacting Firestore', () async {
    await expectLater(
      repository.review('owner-a', approve: false, reason: '  '),
      throwsA(isA<AuthFailure>()),
    );
    verifyNever(() => firestore.collection(any()));
  });
  test(
    'submission uses Firebase UID and profile instead of invented identity',
    () async {
      when(() => user.uid).thenReturn('owner-a');
      when(() => verification.data()).thenReturn(null);
      await submit();
      final data =
          verify(
                () => transaction.set<Map<String, dynamic>>(
                  verificationRef,
                  captureAny(),
                ),
              ).captured.single
              as Map;
      expect(data['ownerId'], 'owner-a');
      expect(data['name'], 'Owner A');
      expect(data['status'], 'PROSES');
      expect(data['submittedAt'], isA<FieldValue>());
      expect(data['reviewedAt'], isNull);
      verifyNever(() => transaction.update(ownerRef, any()));
    },
  );
  test(
    'rejected submission may be corrected but pending cannot be overwritten',
    () async {
      when(() => user.uid).thenReturn('owner-a');
      await expectLater(submit(), throwsA(isA<AuthFailure>()));
      when(() => verification.data()).thenReturn({'status': 'TOLAK'});
      await submit();
      verify(
        () => transaction.set<Map<String, dynamic>>(verificationRef, any()),
      ).called(1);
    },
  );
  test('invalid KTP and local document paths are rejected', () async {
    await expectLater(submit(ktp: '123'), throwsA(isA<AuthFailure>()));
    for (final photo in [
      '/local/ktp.jpg',
      'verificationDocuments/owner-a/12345678-1234-4234-a234-123456789012/ktp.png',
      'http://example.com/ktp.jpg',
      'https://user:pass@example.com/x.jpg',
    ]) {
      await expectLater(submit(photo: photo), throwsA(isA<AuthFailure>()));
    }
    expect(
      OwnerVerificationRepository.validDocumentUrl(
        'https://user:pass@example.com/x.jpg',
      ),
      false,
    );
    verifyNever(() => firestore.collection(any()));
  });
  test('signed out user cannot submit or review', () async {
    when(() => auth.currentUser).thenReturn(null);
    await expectLater(submit(), throwsA(isA<AuthFailure>()));
    await expectLater(
      repository.review('owner-a', approve: true),
      throwsA(isA<AuthFailure>()),
    );
    verifyNever(() => firestore.collection(any()));
  });

  test(
    'owner verification connection failures are shown instead of an empty form',
    () async {
      when(() => verificationRef.get(any())).thenThrow(
        FirebaseException(plugin: 'cloud_firestore', code: 'permission-denied'),
      );
      await expectLater(
        repository.watchForOwner('owner-a'),
        emitsError(isA<FirebaseException>()),
      );
      final options =
          verify(() => verificationRef.get(captureAny())).captured.single
              as GetOptions;
      expect(options.source, Source.server);
      verifyNever(() => verificationRef.snapshots());
    },
  );
}
