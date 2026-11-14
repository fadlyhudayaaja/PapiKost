// Firestore reference classes are mocked only for isolated SDK boundary tests.
// ignore_for_file: subtype_of_sealed_class

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:papikost_mobile/data/repositories/auth_repository.dart';

class _Auth extends Mock implements FirebaseAuth {}

class _Firestore extends Mock implements FirebaseFirestore {}

class _Collection extends Mock
    implements CollectionReference<Map<String, dynamic>> {}

class _Document extends Mock
    implements DocumentReference<Map<String, dynamic>> {}

class _Snapshot extends Mock
    implements DocumentSnapshot<Map<String, dynamic>> {}

class _User extends Mock implements User {}

class _Credential extends Mock implements UserCredential {}

void main() {
  late _Auth auth;
  late _Firestore firestore;
  late _Collection collection;
  late _Document document;
  late _Snapshot snapshot;
  late _User user;
  late _Credential credential;
  late AuthRepository repository;
  const uid = 'firebase-uid-renter';
  const email = 'siti@example.com';

  setUpAll(() {
    registerFallbackValue(const GetOptions());
    registerFallbackValue(<String, dynamic>{});
  });

  setUp(() {
    auth = _Auth();
    firestore = _Firestore();
    collection = _Collection();
    document = _Document();
    snapshot = _Snapshot();
    user = _User();
    credential = _Credential();
    repository = AuthRepository(auth: auth, firestore: firestore);
    when(() => user.uid).thenReturn(uid);
    when(() => user.email).thenReturn(email);
    when(() => credential.user).thenReturn(user);
    when(() => auth.currentUser).thenReturn(user);
    when(() => auth.authStateChanges()).thenAnswer((_) => Stream.value(user));
    when(() => auth.signOut()).thenAnswer((_) async {});
    when(
      () => auth.createUserWithEmailAndPassword(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    ).thenAnswer((_) async => credential);
    when(
      () => auth.signInWithEmailAndPassword(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    ).thenAnswer((_) async => credential);
    when(() => firestore.collection('users')).thenReturn(collection);
    when(() => collection.doc(uid)).thenReturn(document);
    when(() => document.get(any())).thenAnswer((_) async => snapshot);
    when(() => document.set(any())).thenAnswer((_) async {});
    when(() => document.update(any())).thenAnswer((_) async {});
    when(() => snapshot.exists).thenReturn(false);
    when(() => snapshot.data()).thenReturn({
      'name': 'Siti Pengguna',
      'email': email,
      'phone': '081234567890',
      'role': 'RENTER',
      'isVerified': false,
      'createdAt': Timestamp.fromDate(DateTime.utc(2026, 11, 12)),
    });
  });

  Future<void> register({String role = 'RENTER'}) => repository.register(
    name: ' Siti Pengguna ',
    email: ' $email ',
    password: 'password-test',
    phone: ' 081234567890 ',
    role: role,
  );

  test(
    'registration writes a pending profile keyed by UID without a password',
    () async {
      await register(role: 'OWNER');
      final data =
          verify(() => document.set(captureAny())).captured.single
              as Map<String, dynamic>;
      expect(
        data.keys,
        unorderedEquals([
          'name',
          'email',
          'phone',
          'role',
          'isVerified',
          'createdAt',
          'avatarUrl',
          'bio',
        ]),
      );
      expect(data['name'], 'Siti Pengguna');
      expect(data['email'], email);
      expect(data['role'], 'OWNER');
      expect(data['isVerified'], false);
      expect(data['createdAt'], isA<FieldValue>());
      verify(() => collection.doc(uid)).called(1);
      verify(() => auth.signOut()).called(1);
    },
  );

  test('registration rejects ADMIN before creating an Auth account', () async {
    await expectLater(register(role: 'ADMIN'), throwsA(isA<AuthFailure>()));
    verifyNever(
      () => auth.createUserWithEmailAndPassword(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    );
  });

  test(
    'registration recovers an account whose profile was not saved',
    () async {
      when(
        () => auth.createUserWithEmailAndPassword(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenThrow(FirebaseAuthException(code: 'email-already-in-use'));
      await register();
      verify(
        () => auth.signInWithEmailAndPassword(
          email: email,
          password: 'password-test',
        ),
      ).called(1);
      verify(() => document.set(any())).called(1);
    },
  );

  test('an existing profile is never overwritten by registration', () async {
    when(
      () => auth.createUserWithEmailAndPassword(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    ).thenThrow(FirebaseAuthException(code: 'email-already-in-use'));
    when(() => snapshot.exists).thenReturn(true);
    await expectLater(register(), throwsA(isA<AuthFailure>()));
    verifyNever(() => document.set(any()));
    verify(() => auth.signOut()).called(1);
  });

  test(
    'a failed profile write signs out and keeps the account recoverable',
    () async {
      when(() => document.set(any())).thenThrow(
        FirebaseException(plugin: 'cloud_firestore', code: 'permission-denied'),
      );
      await expectLater(register(), throwsA(isA<AuthFailure>()));
      verify(() => auth.signOut()).called(1);
      verifyNever(() => user.delete());
    },
  );

  test('login reads the UID and role from a server profile', () async {
    final profile = await repository.login(
      email: email,
      password: 'password-test',
    );
    expect(profile.id, uid);
    expect(profile.role, 'RENTER');
    expect(profile.isVerified, false);
    expect(profile.createdAt!.toUtc(), DateTime.utc(2026, 11, 12));
    final options =
        verify(() => document.get(captureAny())).captured.single as GetOptions;
    expect(options.source, Source.server);
  });

  test('login signs out if there is no matching Firestore profile', () async {
    when(() => snapshot.data()).thenReturn(null);
    await expectLater(
      repository.login(email: email, password: 'password-test'),
      throwsA(isA<AuthFailure>()),
    );
    verify(() => auth.signOut()).called(1);
  });

  test('session restoration uses Firebase and reloads the profile', () async {
    expect((await repository.getCurrentUser())!.id, uid);
    verify(() => document.get(any())).called(1);
  });

  test('signed-out sessions do not read any Firestore profile', () async {
    when(() => auth.authStateChanges()).thenAnswer((_) => Stream.value(null));
    expect(await repository.getCurrentUser(), isNull);
    verifyNever(() => firestore.collection(any()));
  });

  test('profile edits only write the allowed editable fields', () async {
    await repository.updateProfile(
      name: 'Siti Baru',
      phone: '081234567890',
      bio: 'Bio',
    );
    final data =
        verify(() => document.update(captureAny())).captured.single as Map;
    expect(data, {'name': 'Siti Baru', 'phone': '081234567890', 'bio': 'Bio'});
  });
}
