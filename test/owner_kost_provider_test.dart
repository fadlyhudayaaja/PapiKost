import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:papikost_mobile/data/models/kost_model.dart';
import 'package:papikost_mobile/data/models/user_model.dart';
import 'package:papikost_mobile/features/owner/presentation/providers/owner_provider.dart';
import 'support/kost_fixtures.dart';
import 'support/reservation_fixtures.dart';
import 'support/ticket_fixtures.dart';

const owner = UserModel(
  id: 'firebase-owner-a',
  name: 'Owner A',
  email: 'owner@example.com',
  phone: '081234567890',
  role: 'OWNER',
);

void main() {
  late MockKostRepository repository;
  late OwnerProvider provider;
  setUp(() {
    repository = MockKostRepository();
    final reservations = MockReservationRepository();
    when(
      () => reservations.watchForOwner(any()),
    ).thenAnswer((_) => const Stream.empty());
    when(() => reservations.fetchForOwner(any())).thenAnswer((_) async => []);
    provider = OwnerProvider(
      repository: repository,
      reservationRepository: reservations,
      ticketRepository: emptyTicketRepository(),
    )..bindUser(owner);
  });
  tearDown(() => provider.dispose());

  test(
    'dashboard room counts come from the owners Firestore properties',
    () async {
      when(
        () => repository.fetchForOwner(owner.id),
      ).thenAnswer((_) async => [testKost]);
      await provider.fetchDashboard();
      expect(provider.stats!.totalRooms, 5);
      expect(provider.stats!.occupiedRooms, 2);
      expect(provider.stats!.availableRooms, 3);
      expect(provider.reservations, isEmpty);
    },
  );
  test(
    'failed deletion leaves the listing visible and reports failure',
    () async {
      when(
        () => repository.fetchForOwner(owner.id),
      ).thenAnswer((_) async => [testKost]);
      when(() => repository.deleteKost(testKost.id)).thenThrow(
        FirebaseException(plugin: 'cloud_firestore', code: 'permission-denied'),
      );
      await provider.fetchKostList();
      expect(await provider.deleteKost(testKost.id), false);
      expect(provider.kostList.single.id, testKost.id);
      expect(provider.errorMessage, isNotNull);
      expect(provider.isSubmitting, false);
    },
  );
  test(
    'switching accounts clears owner data and ignores a late query',
    () async {
      final pending = Completer<List<KostModel>>();
      when(
        () => repository.fetchForOwner(owner.id),
      ).thenAnswer((_) => pending.future);
      final loading = provider.fetchKostList();
      provider.bindUser(owner.copyWith(id: 'firebase-owner-b'));
      pending.complete([testKost]);
      await loading;
      expect(provider.kostList, isEmpty);
      expect(provider.stats, isNull);
      expect(provider.kostLoading, false);
    },
  );
  test(
    'read failures are represented as errors rather than an empty success',
    () async {
      when(() => repository.fetchForOwner(owner.id)).thenThrow(
        FirebaseException(plugin: 'cloud_firestore', code: 'permission-denied'),
      );
      await provider.fetchKostList();
      expect(provider.kostError, isNotNull);
      expect(provider.kostLoading, false);
    },
  );
}
