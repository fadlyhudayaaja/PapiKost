import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:papikost_mobile/data/models/reservation_model.dart';
import 'package:papikost_mobile/data/models/user_model.dart';
import 'package:papikost_mobile/features/owner/presentation/providers/owner_provider.dart';
import '../support/fixtures/kost_fixtures.dart';
import '../support/fixtures/reservation_fixtures.dart';
import '../support/fixtures/ticket_fixtures.dart';

const owner = UserModel(
  id: 'firebase-owner-a',
  name: 'Owner A',
  email: 'owner@example.com',
  phone: '08123',
  role: 'OWNER',
);

void main() {
  late MockKostRepository kosts;
  late MockReservationRepository reservations;
  late StreamController<List<ReservationModel>> updates;
  late OwnerProvider provider;
  setUp(() {
    kosts = MockKostRepository();
    reservations = MockReservationRepository();
    updates = StreamController<List<ReservationModel>>();
    when(() => reservations.watchForOwner(any())).thenAnswer(
      (invocation) => invocation.positionalArguments.first == owner.id
          ? updates.stream
          : const Stream.empty(),
    );
    when(() => reservations.fetchForOwner(any())).thenAnswer((_) async => []);
    when(() => kosts.fetchForOwner(any())).thenAnswer((_) async => [testKost]);
    provider = OwnerProvider(
      repository: kosts,
      reservationRepository: reservations,
      ticketRepository: emptyTicketRepository(),
    )..bindUser(owner);
  });
  tearDown(() async {
    provider.dispose();
    await updates.close();
  });
  test('live reservations update owner pending counts', () async {
    await provider.fetchKostList();
    updates.add([testReservation]);
    await Future<void>.delayed(Duration.zero);
    expect(provider.reservations.single.id, testReservation.id);
    expect(provider.stats!.pendingReservations, 1);
    expect(provider.stats!.occupiedRooms, 2);
  });
  test('switching owners discards late reservation reads', () async {
    final pending = Completer<List<ReservationModel>>();
    when(
      () => reservations.fetchForOwner(owner.id),
    ).thenAnswer((_) => pending.future);
    final request = provider.fetchReservations();
    provider.bindUser(owner.copyWith(id: 'other-owner'));
    pending.complete([testReservation]);
    await request;
    expect(provider.reservations, isEmpty);
    expect(provider.stats, isNull);
  });
  test(
    'failed responses keep pending data and expose the actual failure',
    () async {
      updates.add([testReservation]);
      await Future<void>.delayed(Duration.zero);
      when(
        () => reservations.respond(testReservation.id, approve: true),
      ).thenThrow(
        FirebaseException(plugin: 'cloud_firestore', code: 'permission-denied'),
      );
      expect(
        await provider.respondToReservation(testReservation.id, true),
        false,
      );
      expect(provider.reservations.single.status, 'PENDING');
      expect(provider.errorMessage, contains('Akses reservasi ditolak'));
      expect(provider.isSubmitting, false);
    },
  );
  test(
    'successful approval refreshes room counts after the transaction',
    () async {
      when(
        () => reservations.respond(testReservation.id, approve: true),
      ).thenAnswer((_) async {});
      when(() => reservations.fetchForOwner(owner.id)).thenAnswer(
        (_) async => [
          ReservationModel.fromJson({
            ...testReservation.toJson(),
            'status': 'APPROVED',
          }),
        ],
      );
      expect(
        await provider.respondToReservation(testReservation.id, true),
        true,
      );
      expect(provider.reservations.single.status, 'APPROVED');
      expect(provider.stats!.pendingReservations, 0);
      verify(() => kosts.fetchForOwner(owner.id)).called(1);
    },
  );
}
