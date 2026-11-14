import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:papikost_mobile/data/models/ticket_model.dart';
import 'package:papikost_mobile/data/repositories/auth_repository.dart';
import 'package:papikost_mobile/features/renter/ticket/providers/renter_ticket_provider.dart';
import 'package:papikost_mobile/features/owner/presentation/providers/owner_provider.dart';
import 'support/auth_fixtures.dart';
import 'support/kost_fixtures.dart';
import 'support/reservation_fixtures.dart';
import 'support/ticket_fixtures.dart';

void main() {
  late MockTicketRepository repository;
  late StreamController<List<TicketModel>> updates;
  late RenterTicketProvider provider;
  setUp(() {
    repository = emptyTicketRepository();
    updates = StreamController<List<TicketModel>>();
    when(
      () => repository.watchForRenter(testUser.id),
    ).thenAnswer((_) => updates.stream);
    provider = RenterTicketProvider(repository: repository)..bindUser(testUser);
  });
  tearDown(() async {
    provider.dispose();
    await updates.close();
  });

  test(
    'renter list receives real statuses and owner notes from its listener',
    () async {
      updates.add([testTicket]);
      await Future<void>.delayed(Duration.zero);
      expect(provider.tickets.single.id, testTicket.id);
      updates.add([
        testTicket.copyWith(
          status: 'IN_PROGRESS',
          ownerNote: 'Teknisi datang besok.',
        ),
      ]);
      await Future<void>.delayed(Duration.zero);
      expect(provider.tickets.single.status, 'IN_PROGRESS');
      expect(provider.tickets.single.ownerNote, 'Teknisi datang besok.');
    },
  );
  test(
    'stream permission errors show an error rather than mock data',
    () async {
      updates.addError(
        FirebaseException(plugin: 'cloud_firestore', code: 'permission-denied'),
      );
      await Future<void>.delayed(Duration.zero);
      expect(provider.listState, ViewState.error);
      expect(provider.listError, contains('Akses laporan ditolak'));
      expect(provider.tickets, isEmpty);
    },
  );
  test(
    'switching accounts clears data and discards a late list response',
    () async {
      final pending = Completer<List<TicketModel>>();
      when(
        () => repository.fetchForRenter(testUser.id),
      ).thenAnswer((_) => pending.future);
      final loading = provider.loadTickets();
      provider.bindUser(testUser.copyWith(id: 'other-renter'));
      pending.complete([testTicket]);
      await loading;
      expect(provider.tickets, isEmpty);
      expect(provider.selectedTicket, isNull);
    },
  );
  test('detail status and notes change live while its page is open', () async {
    final details = StreamController<TicketModel?>();
    when(
      () => repository.watchById(testTicket.id),
    ).thenAnswer((_) => details.stream);
    await provider.loadTicketDetail(testTicket.id);
    details.add(testTicket);
    await Future<void>.delayed(Duration.zero);
    expect(provider.selectedTicket!.status, 'PENDING');
    details.add(
      testTicket.copyWith(status: 'DONE', ownerNote: 'Sudah diperbaiki.'),
    );
    await Future<void>.delayed(Duration.zero);
    expect(provider.selectedTicket!.status, 'DONE');
    expect(provider.selectedTicket!.ownerNote, 'Sudah diperbaiki.');
    provider.bindUser(null);
    await details.close();
    expect(provider.selectedTicket, isNull);
  });
  test(
    'failed deletion keeps the report visible and exposes the server failure',
    () async {
      updates.add([testTicket]);
      await Future<void>.delayed(Duration.zero);
      when(
        () => repository.deleteTicket(testTicket.id),
      ).thenThrow(const AuthFailure('Laporan sudah diproses.'));
      await expectLater(
        provider.deleteTicket(testTicket.id),
        throwsA(isA<AuthFailure>()),
      );
      expect(provider.tickets.single.id, testTicket.id);
      expect(provider.isSubmitting, false);
    },
  );
  test(
    'a submission finishing after logout cannot repopulate another accounts list',
    () async {
      final pending = Completer<TicketModel>();
      when(
        () => repository.createTicket(
          reservationId: testTicket.reservationId,
          title: testTicket.title,
          description: testTicket.description,
          category: testTicket.category,
          incidentDate: testTicket.incidentDate,
          imageUrls: const [],
        ),
      ).thenAnswer((_) => pending.future);
      final submission = provider.createTicket(
        reservationId: testTicket.reservationId,
        title: testTicket.title,
        description: testTicket.description,
        category: testTicket.category,
        incidentDate: testTicket.incidentDate,
      );
      provider.bindUser(null);
      pending.complete(testTicket);
      expect(await submission, isNull);
      expect(provider.tickets, isEmpty);
      expect(provider.isSubmitting, false);
    },
  );
  test(
    'owner live counts and successful status changes reflect the same ticket',
    () async {
      final ownerUpdates = StreamController<List<TicketModel>>();
      final reservations = MockReservationRepository();
      when(
        () => reservations.watchForOwner(testTicket.ownerId),
      ).thenAnswer((_) => const Stream.empty());
      when(
        () => repository.watchForOwner(testTicket.ownerId),
      ).thenAnswer((_) => ownerUpdates.stream);
      final owner = OwnerProvider(
        repository: MockKostRepository(),
        reservationRepository: reservations,
        ticketRepository: repository,
      )..bindUser(testUser.copyWith(id: testTicket.ownerId, role: 'OWNER'));
      ownerUpdates.add([testTicket]);
      await Future<void>.delayed(Duration.zero);
      expect(owner.stats!.pendingTickets, 1);
      when(
        () => repository.updateStatus(
          testTicket.id,
          'IN_PROGRESS',
          ownerNote: 'Teknisi datang.',
        ),
      ).thenAnswer(
        (_) async => testTicket.copyWith(
          status: 'IN_PROGRESS',
          ownerNote: 'Teknisi datang.',
        ),
      );
      expect(
        await owner.updateTicketStatus(
          testTicket.id,
          'IN_PROGRESS',
          ownerNote: 'Teknisi datang.',
        ),
        true,
      );
      expect(owner.stats!.pendingTickets, 0);
      expect(owner.tickets.single.ownerNote, 'Teknisi datang.');
      when(
        () => repository.updateStatus(testTicket.id, 'DONE', ownerNote: null),
      ).thenThrow(
        FirebaseException(plugin: 'cloud_firestore', code: 'permission-denied'),
      );
      expect(await owner.updateTicketStatus(testTicket.id, 'DONE'), false);
      expect(owner.tickets.single.status, 'IN_PROGRESS');
      expect(owner.errorMessage, contains('Akses laporan ditolak'));
      owner.dispose();
      await ownerUpdates.close();
    },
  );
}
