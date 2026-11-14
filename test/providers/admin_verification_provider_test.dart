import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:papikost_mobile/data/repositories/auth_repository.dart';
import 'package:papikost_mobile/features/admin/presentation/providers/admin_provider.dart';
import '../support/fixtures/verification_fixtures.dart';

void main() {
  late MockVerificationRepository repository;
  late AdminProvider provider;
  late StreamController<List<OwnerSubmission>> updates;
  setUp(() {
    repository = MockVerificationRepository();
    updates = StreamController<List<OwnerSubmission>>.broadcast();
    when(() => repository.watchAll()).thenAnswer((_) => updates.stream);
    provider = AdminProvider(repository: repository)
      ..bindUser(verificationAdmin);
  });
  tearDown(() async {
    provider.dispose();
    await updates.close();
  });

  test(
    'live decisions survive refreshing the list without restoring mock data',
    () async {
      await provider.loadSubmissions();
      updates.add([submissionFixture()]);
      await Future<void>.delayed(Duration.zero);
      expect(provider.pendingSubmissions, hasLength(1));
      updates.add([submissionFixture(status: VerificationStatus.acc)]);
      await Future<void>.delayed(Duration.zero);
      expect(provider.pendingSubmissions, isEmpty);
      await provider.loadSubmissions();
      updates.add([submissionFixture(status: VerificationStatus.acc)]);
      await Future<void>.delayed(Duration.zero);
      expect(provider.submissions.single.status, VerificationStatus.acc);
    },
  );
  test('read failures show an error, with a working retry', () async {
    await provider.loadSubmissions();
    updates.addError(
      FirebaseException(plugin: 'cloud_firestore', code: 'permission-denied'),
    );
    await Future<void>.delayed(Duration.zero);
    expect(provider.state, AdminLoadState.error);
    expect(provider.error, contains('Akses verifikasi ditolak'));
    await provider.loadSubmissions();
    updates.add([]);
    await Future<void>.delayed(Duration.zero);
    expect(provider.state, AdminLoadState.loaded);
    expect(provider.error, isEmpty);
  });
  test(
    'failed review reports server error and never fabricates success',
    () async {
      await provider.loadSubmissions();
      updates.add([submissionFixture()]);
      await Future<void>.delayed(Duration.zero);
      when(
        () => repository.review('owner-a', approve: true),
      ).thenThrow(const AuthFailure('Pengajuan sudah diproses admin lain.'));
      expect(await provider.approveSubmission('owner-a'), false);
      expect(provider.error, contains('sudah diproses'));
      expect(provider.pendingSubmissions, hasLength(1));
      expect(provider.isSubmitting, false);
    },
  );
  test(
    'sign out clears sensitive data and ignores completion from old account',
    () async {
      final decision = Completer<void>();
      await provider.loadSubmissions();
      updates.add([submissionFixture()]);
      await Future<void>.delayed(Duration.zero);
      when(
        () => repository.review('owner-a', approve: true),
      ).thenAnswer((_) => decision.future);
      final result = provider.approveSubmission('owner-a');
      expect(provider.isSubmitting, true);
      provider.bindUser(null);
      expect(provider.submissions, isEmpty);
      decision.complete();
      expect(await result, false);
      updates.add([submissionFixture()]);
      await Future<void>.delayed(Duration.zero);
      expect(provider.submissions, isEmpty);
    },
  );
  test('non-admin cannot listen to the queue or issue decisions', () async {
    provider.bindUser(verificationOwner);
    await provider.loadSubmissions();
    expect(await provider.approveSubmission('owner-a'), false);
    verifyNever(() => repository.watchAll());
    verifyNever(() => repository.review(any(), approve: any(named: 'approve')));
  });
}
