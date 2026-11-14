import { readFileSync } from 'node:fs';
import assert from 'node:assert/strict';
import { after, before, beforeEach, test } from 'node:test';
import {
  initializeTestEnvironment, assertFails, assertSucceeds,
} from '@firebase/rules-unit-testing';
import {
  collection, deleteDoc, doc, getDoc, getDocs, query, serverTimestamp,
  setDoc, setLogLevel, Timestamp, updateDoc, where, writeBatch, runTransaction,
} from 'firebase/firestore';

let environment;
const profile = (role, name) => ({
  name, role, email: name + '@example.com', phone: '081234567890',
  isVerified: false, createdAt: Timestamp.now(), avatarUrl: null, bio: null,
});
const listing = (overrides = {}) => ({
  ownerId: 'owner-a', ownerName: 'Owner A', name: 'Kost Melati',
  address: 'Jalan Melati 10', city: 'Medan', pricePerMonth: 1000000,
  type: 'CAMPUR', facilities: ['WiFi'], imageUrls: [],
  isSplitBillAvailable: false, totalRooms: 5, availableRooms: 5,
  description: null, latitude: null, longitude: null, rating: null,
  reviewCount: 0, createdAt: serverTimestamp(), updatedAt: serverTimestamp(),
  verificationStatus: 'PROSES', rejectionReason: null, reviewedBy: null, reviewedAt: null,
  ...overrides,
});
const database = (uid) => environment.authenticatedContext(
  uid, { email: uid + '@example.com' },
).firestore();
const seedKost = async (overrides = {}) => environment.withSecurityRulesDisabled(
  async (context) => setDoc(doc(context.firestore(), 'kost', 'listing-a'), listing({
    verificationStatus: 'ACC', ...overrides,
  })),
);

before(async () => {
  setLogLevel('silent');
  environment = await initializeTestEnvironment({
    projectId: 'demo-papikost',
    firestore: { rules: readFileSync(new URL('../firestore.rules', import.meta.url), 'utf8') },
  });
});
after(async () => environment?.cleanup());
beforeEach(async () => {
  await environment.clearFirestore();
  await environment.withSecurityRulesDisabled(async (context) => {
    const db = context.firestore();
    await Promise.all([
      setDoc(doc(db, 'users', 'owner-a'), profile('OWNER', 'Owner A')),
      setDoc(doc(db, 'users', 'owner-b'), profile('OWNER', 'Owner B')),
      setDoc(doc(db, 'users', 'renter-a'), profile('RENTER', 'Renter A')),
      setDoc(doc(db, 'users', 'renter-b'), profile('RENTER', 'Renter B')),
      setDoc(doc(db, 'users', 'admin-a'), profile('ADMIN', 'Admin A')),
      setDoc(doc(db, 'users', 'admin-b'), profile('ADMIN', 'Admin B')),
    ]);
  });
});

test('an owner can create a listing belonging to their own UID', async () => {
  await assertSucceeds(setDoc(doc(database('owner-a'), 'kost', 'new-kost'), listing()));
});

const roomDecision = (status = 'ACC', overrides = {}) => ({
  verificationStatus: status, rejectionReason: status === 'ACC' ? null : 'Data kamar belum sesuai.',
  reviewedBy: 'admin-a', reviewedAt: serverTimestamp(), updatedAt: serverTimestamp(),
  ...overrides,
});

test('a newly created room is immediately available in the admin verification query', async () => {
  await assertSucceeds(setDoc(doc(database('owner-a'), 'kost', 'new-kost'), listing()));
  const snapshot = await assertSucceeds(getDocs(collection(database('admin-a'), 'kost')));
  assert.equal(snapshot.docs.length, 1);
  assert.equal(snapshot.docs[0].data().verificationStatus, 'PROSES');
});

test('owner cannot publish an already approved room or omit the review status', async () => {
  await assertFails(setDoc(doc(database('owner-a'), 'kost', 'forged'), listing({verificationStatus: 'ACC'})));
  const legacy = listing();
  delete legacy.verificationStatus;
  await assertFails(setDoc(doc(database('owner-a'), 'kost', 'missing-status'), legacy));
});

test('only admin can approve a room and room approval does not verify owner identity', async () => {
  await seedKost({verificationStatus: 'PROSES'});
  for (const uid of ['owner-a', 'owner-b', 'renter-a']) {
    await assertFails(updateDoc(doc(database(uid), 'kost', 'listing-a'), roomDecision()));
  }
  await assertSucceeds(updateDoc(doc(database('admin-a'), 'kost', 'listing-a'), roomDecision()));
  assert.equal((await getDoc(doc(database('owner-a'), 'users', 'owner-a'))).data().isVerified, false);
  await assertFails(updateDoc(doc(database('admin-b'), 'kost', 'listing-a'), roomDecision('TOLAK', {reviewedBy: 'admin-b'})));
});

test('room decisions enforce reviewer, server time, reason and immutable listing data', async () => {
  await seedKost({verificationStatus: 'PROSES'});
  const ref = doc(database('admin-a'), 'kost', 'listing-a');
  for (const changes of [
    {reviewedBy: 'admin-b'}, {reviewedAt: Timestamp.fromMillis(1)},
    {pricePerMonth: 1}, {ownerId: 'owner-b'},
  ]) {
    await assertFails(updateDoc(ref, roomDecision('ACC', changes)));
  }
  for (const rejectionReason of [null, 'singkat', '                ', 'x'.repeat(301)]) {
    await assertFails(updateDoc(ref, roomDecision('TOLAK', {rejectionReason})));
  }
  await assertSucceeds(updateDoc(ref, roomDecision('TOLAK')));
});

test('owner correction resubmits a rejected room and clears the prior decision', async () => {
  await seedKost({verificationStatus: 'PROSES'});
  await updateDoc(doc(database('admin-a'), 'kost', 'listing-a'), roomDecision('TOLAK'));
  const ref = doc(database('owner-a'), 'kost', 'listing-a');
  await assertFails(updateDoc(ref, {name: 'Kost Diperbaiki', updatedAt: serverTimestamp()}));
  await assertSucceeds(updateDoc(ref, {
    name: 'Kost Diperbaiki', verificationStatus: 'PROSES', rejectionReason: null,
    reviewedBy: null, reviewedAt: null, updatedAt: serverTimestamp(),
  }));
  await assertSucceeds(updateDoc(doc(database('admin-a'), 'kost', 'listing-a'), roomDecision()));
});

test('existing rooms without review fields can still be approved by admin', async () => {
  await environment.withSecurityRulesDisabled(async (context) => {
    const legacy = listing();
    for (const field of ['verificationStatus', 'rejectionReason', 'reviewedBy', 'reviewedAt']) delete legacy[field];
    await setDoc(doc(context.firestore(), 'kost', 'legacy-room'), legacy);
  });
  await assertSucceeds(updateDoc(doc(database('admin-a'), 'kost', 'legacy-room'), roomDecision()));
});
test('an unauthenticated visitor cannot read the catalogue', async () => {
  await assertFails(getDocs(collection(environment.unauthenticatedContext().firestore(), 'kost')));
});
test('a renter can read the catalogue and detail', async () => {
  await seedKost();
  await assertSucceeds(getDocs(collection(database('renter-a'), 'kost')));
  await assertSucceeds(getDoc(doc(database('renter-a'), 'kost', 'listing-a')));
});
test('the owner query can filter by Firebase owner UID', async () => {
  await seedKost();
  await assertSucceeds(getDocs(query(
    collection(database('owner-a'), 'kost'), where('ownerId', '==', 'owner-a'),
  )));
});
test('a renter cannot create a listing', async () => {
  await assertFails(setDoc(doc(database('renter-a'), 'kost', 'new-kost'), listing({
    ownerId: 'renter-a', ownerName: 'Renter A',
  })));
});
test('an owner cannot impersonate a different owner', async () => {
  await assertFails(setDoc(doc(database('owner-b'), 'kost', 'new-kost'), listing()));
});
test('an owner cannot invent a different display name', async () => {
  await assertFails(setDoc(doc(database('owner-a'), 'kost', 'new-kost'), listing({
    ownerName: 'Someone Else',
  })));
});
test('an owner can edit their own listing', async () => {
  await seedKost();
  await assertSucceeds(updateDoc(doc(database('owner-a'), 'kost', 'listing-a'), {
    name: 'Kost Melati Baru', pricePerMonth: 1200000, updatedAt: serverTimestamp(),
    verificationStatus: 'PROSES', rejectionReason: null, reviewedBy: null, reviewedAt: null,
  }));
});
test('an owner cannot edit a different owners listing', async () => {
  await seedKost();
  await assertFails(updateDoc(doc(database('owner-b'), 'kost', 'listing-a'), {
    name: 'Taken Over', updatedAt: serverTimestamp(),
  }));
});
test('an owner cannot transfer the owner UID', async () => {
  await seedKost();
  await assertFails(updateDoc(doc(database('owner-a'), 'kost', 'listing-a'), {
    ownerId: 'owner-b', updatedAt: serverTimestamp(),
  }));
});
test('an owner cannot fabricate initial ratings', async () => {
  await assertFails(setDoc(doc(database('owner-a'), 'kost', 'new-kost'), listing({
    rating: 5, reviewCount: 100,
  })));
});
test('an owner cannot edit protected ratings', async () => {
  await seedKost();
  await assertFails(updateDoc(doc(database('owner-a'), 'kost', 'listing-a'), {
    rating: 5, reviewCount: 100, updatedAt: serverTimestamp(),
  }));
});
test('an owner cannot fabricate vacant rooms in an occupied property', async () => {
  await seedKost({ availableRooms: 3 });
  await assertFails(updateDoc(doc(database('owner-a'), 'kost', 'listing-a'), {
    availableRooms: 5, updatedAt: serverTimestamp(),
  }));
});
test('room totals can change while preserving occupied rooms', async () => {
  await seedKost({ availableRooms: 3 });
  await assertSucceeds(updateDoc(doc(database('owner-a'), 'kost', 'listing-a'), {
    totalRooms: 6, availableRooms: 4, updatedAt: serverTimestamp(),
    verificationStatus: 'PROSES', rejectionReason: null, reviewedBy: null, reviewedAt: null,
  }));
});
test('negative prices and inconsistent room counts are rejected', async () => {
  await assertFails(setDoc(doc(database('owner-a'), 'kost', 'negative-price'), listing({
    pricePerMonth: -1,
  })));
  await assertFails(setDoc(doc(database('owner-a'), 'kost', 'bad-rooms'), listing({
    availableRooms: 6,
  })));
});
test('private local photo paths cannot be published', async () => {
  await assertFails(setDoc(doc(database('owner-a'), 'kost', 'new-kost'), listing({
    imageUrls: ['/data/user/0/com.example.papikost/photo.jpg'],
  })));
});
test('HTTPS photo URLs are accepted', async () => {
  await assertSucceeds(setDoc(doc(database('owner-a'), 'kost', 'new-kost'), listing({
    imageUrls: ['https://example.com/kost.jpg'],
  })));
});
test('unknown fields and forged creation timestamps are rejected', async () => {
  await assertFails(setDoc(doc(database('owner-a'), 'kost', 'extra-field'), listing({
    isAdmin: true,
  })));
  await assertFails(setDoc(doc(database('owner-a'), 'kost', 'wrong-clock'), listing({
    createdAt: Timestamp.fromMillis(1),
  })));
});
test('an owner can delete their vacant listing', async () => {
  await seedKost();
  await assertSucceeds(deleteDoc(doc(database('owner-a'), 'kost', 'listing-a')));
});
test('occupied listings cannot be deleted', async () => {
  await seedKost({ availableRooms: 3 });
  await assertFails(deleteDoc(doc(database('owner-a'), 'kost', 'listing-a')));
});
test('a different owner cannot delete a listing', async () => {
  await seedKost();
  await assertFails(deleteDoc(doc(database('owner-b'), 'kost', 'listing-a')));
});
test('users still cannot escalate their account role or verification', async () => {
  await assertFails(updateDoc(doc(database('renter-a'), 'users', 'renter-a'), { role: 'ADMIN' }));
  await assertFails(updateDoc(doc(database('owner-a'), 'users', 'owner-a'), { isVerified: true }));
});
test('profiles remain private to their account', async () => {
  await assertSucceeds(getDoc(doc(database('owner-a'), 'users', 'owner-a')));
  await assertFails(getDoc(doc(database('owner-b'), 'users', 'owner-a')));
});
test('new account registration can still create its pending profile', async () => {
  const db = database('new-owner');
  await assertSucceeds(setDoc(doc(db, 'users', 'new-owner'), {
    ...profile('OWNER', 'New Owner'),
    email: 'new-owner@example.com',
    createdAt: serverTimestamp(),
  }));
});
test('self registration cannot create an administrator profile', async () => {
  const db = database('new-admin');
  await assertFails(setDoc(doc(db, 'users', 'new-admin'), {
    ...profile('ADMIN', 'New Admin'),
    email: 'new-admin@example.com',
    createdAt: serverTimestamp(),
  }));
});

const reservation = (overrides = {}) => ({
  ownerId: 'owner-a', kostId: 'listing-a', kostName: 'Kost Melati',
  kostAddress: 'Jalan Melati 10', kostImageUrl: null,
  renterId: 'renter-a', renterName: 'Renter A',
  renterEmail: 'Renter A@example.com', renterPhone: '081234567890',
  status: 'PENDING', isSplitBill: false, splitMemberCount: null,
  totalPrice: 1000000, pricePerPerson: null,
  checkInDate: Timestamp.fromMillis(Date.now() + 7 * 86400000),
  checkOutDate: null, notes: null,
  createdAt: serverTimestamp(), updatedAt: serverTimestamp(),
  ...overrides,
});

function reserve(db, overrides = {}, id = 'reservation-a') {
  const data = reservation(overrides);
  const batch = writeBatch(db);
  batch.set(doc(db, 'reservations', id), data);
  batch.set(doc(db, 'users', data.renterId, 'reservationLocks', data.kostId), {
    renterId: data.renterId, kostId: data.kostId, reservationId: id,
  });
  return batch.commit();
}

function approve(db, id = 'reservation-a') {
  return runTransaction(db, async (transaction) => {
    const reservationRef = doc(db, 'reservations', id);
    const data = (await transaction.get(reservationRef)).data();
    if (data.status === 'APPROVED') return;
    if (data.status !== 'PENDING') throw new Error('already processed');
    const kostRef = doc(db, 'kost', data.kostId);
    const kost = (await transaction.get(kostRef)).data();
    if (kost.availableRooms < 1) throw new Error('full');
    transaction.update(kostRef, {
      availableRooms: kost.availableRooms - 1,
      lastReservationId: id, updatedAt: serverTimestamp(),
    });
    transaction.update(reservationRef, { status: 'APPROVED', updatedAt: serverTimestamp() });
  });
}

test('a renter can submit a real reservation with its lock atomically', async () => {
  await seedKost();
  await assertSucceeds(reserve(database('renter-a')));
});

test('pending and rejected rooms cannot be reserved until approved by admin', async () => {
  for (const verificationStatus of ['PROSES', 'TOLAK']) {
    await seedKost({verificationStatus});
    await assertFails(reserve(database('renter-a')));
  }
  await seedKost({verificationStatus: 'PROSES'});
  await updateDoc(doc(database('admin-a'), 'kost', 'listing-a'), roomDecision());
  await assertSucceeds(reserve(database('renter-a')));
});

test('patungan accepts the current server price divided by 3 members', async () => {
  await seedKost({ isSplitBillAvailable: true });
  await assertSucceeds(reserve(database('renter-a'), {
    isSplitBill: true, splitMemberCount: 3, pricePerPerson: 1000000 / 3,
  }));
});

test('owners and unauthenticated visitors cannot submit renter reservations', async () => {
  await seedKost();
  await assertFails(reserve(database('owner-a')));
  await assertFails(reserve(environment.unauthenticatedContext().firestore()));
});

test('renter identity, property owner, name, photo and price cannot be forged', async () => {
  await seedKost();
  for (const changes of [
    { renterId: 'renter-b' }, { renterName: 'Someone Else' },
    { renterEmail: 'stolen@example.com' }, { renterPhone: 'wrong' },
    { ownerId: 'owner-b' }, { kostName: 'Fake' },
    { kostAddress: 'Fake' }, { kostImageUrl: 'https://fake.example/photo.jpg' },
    { totalPrice: 1 }, { kostId: 'missing' },
  ]) {
    await assertFails(reserve(database('renter-a'), changes));
  }
});

test('a full or deleted property cannot receive a new reservation', async () => {
  await seedKost({ availableRooms: 0 });
  await assertFails(reserve(database('renter-a')));
  await environment.withSecurityRulesDisabled(
    async (context) => deleteDoc(doc(context.firestore(), 'kost', 'listing-a')),
  );
  await assertFails(reserve(database('renter-a')));
});

test('a renter cannot preapprove a request, add fields or forge timestamps', async () => {
  await seedKost();
  for (const changes of [
    { status: 'APPROVED' }, { status: 'REJECTED' }, { isAdmin: true },
    { createdAt: Timestamp.fromMillis(1) }, { updatedAt: Timestamp.fromMillis(1) },
  ]) await assertFails(reserve(database('renter-a'), changes));
});

test('invalid dates, notes and patungan details are rejected', async () => {
  await seedKost();
  for (const changes of [
    { checkInDate: Timestamp.fromMillis(Date.now() - 3 * 86400000) },
    { checkInDate: Timestamp.fromMillis(Date.now() + 100 * 86400000) },
    { checkOutDate: Timestamp.now() }, { notes: 'x'.repeat(2001) },
    { splitMemberCount: 2 }, { pricePerPerson: 500000 },
    { isSplitBill: true, splitMemberCount: 2, pricePerPerson: 500000 },
  ]) await assertFails(reserve(database('renter-a'), changes));
  await seedKost({ isSplitBillAvailable: true });
  for (const changes of [
    { isSplitBill: true, splitMemberCount: 1, pricePerPerson: 1000000 },
    { isSplitBill: true, splitMemberCount: 5, pricePerPerson: 200000 },
    { isSplitBill: true, splitMemberCount: 2, pricePerPerson: 1 },
  ]) await assertFails(reserve(database('renter-a'), changes));
});

test('a reservation cannot be submitted without its duplicate prevention lock', async () => {
  await seedKost();
  await assertFails(setDoc(doc(database('renter-a'), 'reservations', 'reservation-a'), reservation()));
});

test('a lock cannot be created without a corresponding new reservation', async () => {
  await seedKost();
  const db = database('renter-a');
  await assertFails(setDoc(doc(db, 'users', 'renter-a', 'reservationLocks', 'listing-a'), {
    renterId: 'renter-a', kostId: 'listing-a', reservationId: 'missing',
  }));
});

test('pending requests prevent duplicate submissions', async () => {
  await seedKost();
  await reserve(database('renter-a'));
  await assertFails(reserve(database('renter-a'), {}, 'duplicate'));
});

test('approved requests also prevent duplicate submissions', async () => {
  await seedKost();
  await reserve(database('renter-a'));
  await approve(database('owner-a'));
  await assertFails(reserve(database('renter-a'), {}, 'duplicate'));
});

test('a rejected request permits a new request while keeping the old history', async () => {
  await seedKost();
  await reserve(database('renter-a'));
  await updateDoc(doc(database('owner-a'), 'reservations', 'reservation-a'), {
    status: 'REJECTED', updatedAt: serverTimestamp(),
  });
  await assertSucceeds(reserve(database('renter-a'), {}, 'retry-a'));
  assert.equal((await getDoc(doc(database('renter-a'), 'reservations', 'reservation-a'))).data().status, 'REJECTED');
});

test('renter history and owner management queries are scoped to their account', async () => {
  await seedKost();
  await reserve(database('renter-a'));
  await assertSucceeds(getDocs(query(collection(database('renter-a'), 'reservations'), where('renterId', '==', 'renter-a'))));
  await assertSucceeds(getDocs(query(collection(database('owner-a'), 'reservations'), where('ownerId', '==', 'owner-a'))));
  await assertFails(getDocs(collection(database('renter-a'), 'reservations')));
  await assertFails(getDocs(collection(database('owner-a'), 'reservations')));
});

test('other accounts and unauthenticated visitors cannot read a private reservation', async () => {
  await seedKost();
  await reserve(database('renter-a'));
  await assertSucceeds(getDoc(doc(database('renter-a'), 'reservations', 'reservation-a')));
  await assertSucceeds(getDoc(doc(database('owner-a'), 'reservations', 'reservation-a')));
  await assertFails(getDoc(doc(database('renter-b'), 'reservations', 'reservation-a')));
  await assertFails(getDoc(doc(database('owner-b'), 'reservations', 'reservation-a')));
  await assertFails(getDoc(doc(environment.unauthenticatedContext().firestore(), 'reservations', 'reservation-a')));
});

test('another owner and the renter cannot approve or reject the reservation', async () => {
  await seedKost();
  await reserve(database('renter-a'));
  for (const uid of ['renter-a', 'owner-b']) {
    await assertFails(updateDoc(doc(database(uid), 'reservations', 'reservation-a'), {
      status: 'REJECTED', updatedAt: serverTimestamp(),
    }));
    await assertFails(approve(database(uid)));
  }
});

test('approval without decrementing inventory is denied', async () => {
  await seedKost();
  await reserve(database('renter-a'));
  await assertFails(updateDoc(doc(database('owner-a'), 'reservations', 'reservation-a'), {
    status: 'APPROVED', updatedAt: serverTimestamp(),
  }));
});

test('inventory cannot be consumed without approving the matching pending reservation', async () => {
  await seedKost();
  await reserve(database('renter-a'));
  await assertFails(updateDoc(doc(database('owner-a'), 'kost', 'listing-a'), {
    availableRooms: 4, lastReservationId: 'reservation-a', updatedAt: serverTimestamp(),
  }));
});

test('owner approval consumes exactly one room and repeat approval is idempotent', async () => {
  await seedKost();
  await reserve(database('renter-a'));
  await assertSucceeds(approve(database('owner-a')));
  await assertSucceeds(approve(database('owner-a')));
  const db = database('owner-a');
  assert.equal((await getDoc(doc(db, 'kost', 'listing-a'))).data().availableRooms, 4);
  assert.equal((await getDoc(doc(db, 'reservations', 'reservation-a'))).data().status, 'APPROVED');
});

test('owner rejection leaves the available room count unchanged', async () => {
  await seedKost();
  await reserve(database('renter-a'));
  await assertSucceeds(updateDoc(doc(database('owner-a'), 'reservations', 'reservation-a'), {
    status: 'REJECTED', updatedAt: serverTimestamp(),
  }));
  assert.equal((await getDoc(doc(database('owner-a'), 'kost', 'listing-a'))).data().availableRooms, 5);
});

test('processed reservations cannot be reversed, edited or deleted', async () => {
  await seedKost();
  await reserve(database('renter-a'));
  await approve(database('owner-a'));
  for (const uid of ['owner-a', 'renter-a']) {
    const ref = doc(database(uid), 'reservations', 'reservation-a');
    await assertFails(updateDoc(ref, { status: 'PENDING', updatedAt: serverTimestamp() }));
    await assertFails(updateDoc(ref, { totalPrice: 1 }));
    await assertFails(deleteDoc(ref));
  }
});

test('an owner cannot change the renter or price while rejecting a request', async () => {
  await seedKost();
  await reserve(database('renter-a'));
  for (const changes of [{ renterId: 'renter-b' }, { totalPrice: 1 }, { ownerId: 'owner-b' }]) {
    await assertFails(updateDoc(doc(database('owner-a'), 'reservations', 'reservation-a'), {
      ...changes, status: 'REJECTED', updatedAt: serverTimestamp(),
    }));
  }
});

test('locks remain private and cannot be removed to bypass duplicate prevention', async () => {
  await seedKost();
  await reserve(database('renter-a'));
  const segments = ['users', 'renter-a', 'reservationLocks', 'listing-a'];
  await assertFails(getDoc(doc(database('renter-b'), ...segments)));
  await assertFails(deleteDoc(doc(database('renter-a'), ...segments)));
});

test('two concurrent approvals cannot consume the same final room', async () => {
  await seedKost({ totalRooms: 1, availableRooms: 1 });
  await reserve(database('renter-a'));
  await reserve(database('renter-b'), {
    renterId: 'renter-b', renterName: 'Renter B', renterEmail: 'Renter B@example.com',
  }, 'reservation-b');
  const db = database('owner-a');
  const results = await Promise.allSettled([approve(db, 'reservation-a'), approve(db, 'reservation-b')]);
  assert.equal(results.filter((item) => item.status === 'fulfilled').length, 1);
  assert.equal((await getDoc(doc(db, 'kost', 'listing-a'))).data().availableRooms, 0);
  const items = (await getDocs(query(collection(db, 'reservations'), where('ownerId', '==', 'owner-a')))).docs;
  assert.equal(items.filter((item) => item.data().status === 'APPROVED').length, 1);
});

test('two approvals cannot be coupled to one inventory decrement in a forged batch', async () => {
  await seedKost();
  await reserve(database('renter-a'));
  await reserve(database('renter-b'), {
    renterId: 'renter-b', renterName: 'Renter B', renterEmail: 'Renter B@example.com',
  }, 'reservation-b');
  const db = database('owner-a');
  const batch = writeBatch(db);
  batch.update(doc(db, 'kost', 'listing-a'), {
    availableRooms: 4, lastReservationId: 'reservation-a', updatedAt: serverTimestamp(),
  });
  for (const id of ['reservation-a', 'reservation-b']) batch.update(doc(db, 'reservations', id), {
    status: 'APPROVED', updatedAt: serverTimestamp(),
  });
  await assertFails(batch.commit());
});

test('a pending request on a removed property can still be rejected', async () => {
  await seedKost();
  await reserve(database('renter-a'));
  await deleteDoc(doc(database('owner-a'), 'kost', 'listing-a'));
  await assertSucceeds(updateDoc(doc(database('owner-a'), 'reservations', 'reservation-a'), {
    status: 'REJECTED', updatedAt: serverTimestamp(),
  }));
});

const ticketData = (overrides = {}) => ({
  title: 'Lampu kamar mati', description: 'Lampu di kamar tidak menyala sejak tadi pagi.',
  category: 'LISTRIK', incidentDate: Timestamp.now(), imageUrls: [],
  reservationId: 'reservation-a', ownerId: 'owner-a',
  kostId: 'listing-a', kostName: 'Kost Melati',
  renterId: 'renter-a', renterName: 'Renter A', status: 'PENDING', ownerNote: null,
  createdAt: serverTimestamp(), updatedAt: serverTimestamp(), ...overrides,
});
const seedApprovedReservation = async (overrides = {}) => environment.withSecurityRulesDisabled(
  async (context) => setDoc(doc(context.firestore(), 'reservations', 'reservation-a'),
    reservation({ status: 'APPROVED', ...overrides })),
);
const createTicket = (db = database('renter-a'), overrides = {}) =>
  setDoc(doc(db, 'tickets', 'ticket-a'), ticketData(overrides));
const progressTicket = (db = database('owner-a')) =>
  updateDoc(doc(db, 'tickets', 'ticket-a'), { status: 'IN_PROGRESS', updatedAt: serverTimestamp() });

test('a renter can report damage after a real approved reservation', async () => {
  await seedKost();
  await reserve(database('renter-a'));
  await approve(database('owner-a'));
  await assertSucceeds(createTicket());
});

test('a ticket can include up to three HTTPS photos', async () => {
  await seedApprovedReservation();
  await assertSucceeds(createTicket(database('renter-a'), {
    imageUrls: ['https://example.com/1.jpg', 'https://example.com/2.jpg', 'https://example.com/3.jpg'],
  }));
});

test('tickets require an approved reservation belonging to the submitting renter', async () => {
  for (const status of ['PENDING', 'REJECTED']) {
    await seedApprovedReservation({ status });
    await assertFails(createTicket());
  }
  await seedApprovedReservation({ renterId: 'renter-b' });
  await assertFails(createTicket());
  await assertFails(createTicket(database('renter-a'), { reservationId: 'missing' }));
});

test('owners and unauthenticated visitors cannot create renter tickets', async () => {
  await seedApprovedReservation();
  await assertFails(createTicket(database('owner-a')));
  await assertFails(createTicket(environment.unauthenticatedContext().firestore()));
});

test('ticket owner, renter, reservation and property snapshots cannot be forged', async () => {
  await seedApprovedReservation();
  for (const changes of [
    { ownerId: 'owner-b' }, { renterId: 'renter-b' }, { renterName: 'Someone Else' },
    { kostId: 'other-kost' }, { kostName: 'Fake Name' }, { reservationId: 'missing' },
  ]) await assertFails(createTicket(database('renter-a'), changes));
});

test('a new ticket cannot start processed, contain owner notes or forge server timestamps', async () => {
  await seedApprovedReservation();
  for (const changes of [
    { status: 'DONE' }, { status: 'IN_PROGRESS' }, { ownerNote: 'Fake approval' },
    { createdAt: Timestamp.fromMillis(1) }, { updatedAt: Timestamp.fromMillis(1) },
    { isAdmin: true },
  ]) await assertFails(createTicket(database('renter-a'), changes));
});

test('ticket validation rejects invalid text, categories, dates and photo paths', async () => {
  await seedApprovedReservation();
  for (const changes of [
    { title: 'abc' }, { title: 'x'.repeat(101) },
    { description: 'too short' }, { description: 'x'.repeat(501) },
    { category: 'UNKNOWN' }, { incidentDate: 'yesterday' },
    { incidentDate: Timestamp.fromMillis(Date.now() + 3 * 86400000) },
    { incidentDate: Timestamp.fromMillis(Date.now() - 400 * 86400000) },
    { imageUrls: ['/data/user/0/photo.jpg'] }, { imageUrls: ['http://example.com/a.jpg'] },
    { imageUrls: ['https://example.com/1', 'https://example.com/2', 'https://example.com/3', 'https://example.com/4'] },
    { imageUrls: [1] },
  ]) await assertFails(createTicket(database('renter-a'), changes));
});

test('ticket queries are private and scoped by the renter or owner UID', async () => {
  await seedApprovedReservation();
  await createTicket();
  await assertSucceeds(getDocs(query(collection(database('renter-a'), 'tickets'), where('renterId', '==', 'renter-a'))));
  await assertSucceeds(getDocs(query(collection(database('owner-a'), 'tickets'), where('ownerId', '==', 'owner-a'))));
  await assertFails(getDocs(collection(database('renter-a'), 'tickets')));
  await assertFails(getDocs(collection(database('owner-a'), 'tickets')));
  for (const uid of ['renter-b', 'owner-b']) {
    await assertFails(getDoc(doc(database(uid), 'tickets', 'ticket-a')));
  }
  await assertFails(getDoc(doc(environment.unauthenticatedContext().firestore(), 'tickets', 'ticket-a')));
});

test('the reporting renter can edit pending ticket content and photos', async () => {
  await seedApprovedReservation();
  await createTicket();
  await assertSucceeds(updateDoc(doc(database('renter-a'), 'tickets', 'ticket-a'), {
    title: 'Lampu kamar rusak', description: 'Lampu kamar putus, perlu diganti dengan yang baru.',
    category: 'LAINNYA', imageUrls: ['https://example.com/new.jpg'],
    incidentDate: Timestamp.now(), updatedAt: serverTimestamp(),
  }));
});

test('a renter cannot change ticket ownership, status, owner notes or linkage while editing', async () => {
  await seedApprovedReservation();
  await createTicket();
  for (const changes of [
    { ownerId: 'owner-b' }, { renterId: 'renter-b' }, { reservationId: 'other' },
    { kostId: 'other' }, { kostName: 'Other' }, { renterName: 'Fake' },
    { status: 'IN_PROGRESS' }, { ownerNote: 'Fake' }, { createdAt: Timestamp.now() },
  ]) await assertFails(updateDoc(doc(database('renter-a'), 'tickets', 'ticket-a'), {
    ...changes, updatedAt: serverTimestamp(),
  }));
});

test('another renter cannot edit or delete a pending ticket', async () => {
  await seedApprovedReservation();
  await createTicket();
  await assertFails(updateDoc(doc(database('renter-b'), 'tickets', 'ticket-a'), {
    title: 'Stolen ticket', updatedAt: serverTimestamp(),
  }));
  await assertFails(deleteDoc(doc(database('renter-b'), 'tickets', 'ticket-a')));
});

test('the reporting renter can delete a pending ticket', async () => {
  await seedApprovedReservation();
  await createTicket();
  await assertSucceeds(deleteDoc(doc(database('renter-a'), 'tickets', 'ticket-a')));
});

test('the owner can process a ticket with a note, then finish it', async () => {
  await seedApprovedReservation();
  await createTicket();
  const ref = doc(database('owner-a'), 'tickets', 'ticket-a');
  await assertSucceeds(updateDoc(ref, {
    status: 'IN_PROGRESS', ownerNote: 'Teknisi akan datang besok.', updatedAt: serverTimestamp(),
  }));
  await assertSucceeds(updateDoc(ref, {
    status: 'DONE', ownerNote: 'Lampu sudah diganti.', updatedAt: serverTimestamp(),
  }));
  const result = (await getDoc(doc(database('renter-a'), 'tickets', 'ticket-a'))).data();
  assert.equal(result.status, 'DONE');
  assert.equal(result.ownerNote, 'Lampu sudah diganti.');
});

test('another owner cannot process someone elses ticket', async () => {
  await seedApprovedReservation();
  await createTicket();
  await assertFails(progressTicket(database('owner-b')));
});

test('an owner cannot skip processing or reverse ticket status', async () => {
  await seedApprovedReservation();
  await createTicket();
  const ref = doc(database('owner-a'), 'tickets', 'ticket-a');
  await assertFails(updateDoc(ref, { status: 'DONE', updatedAt: serverTimestamp() }));
  await progressTicket();
  await assertFails(updateDoc(ref, { status: 'PENDING', updatedAt: serverTimestamp() }));
  await updateDoc(ref, { status: 'DONE', updatedAt: serverTimestamp() });
  await assertFails(updateDoc(ref, { status: 'IN_PROGRESS', updatedAt: serverTimestamp() }));
});

test('owners cannot edit report content, identities or delete the report', async () => {
  await seedApprovedReservation();
  await createTicket();
  const ref = doc(database('owner-a'), 'tickets', 'ticket-a');
  for (const changes of [
    { title: 'Changed content' }, { description: 'Owner is changing the original damage report.' },
    { ownerId: 'owner-b' }, { renterId: 'renter-b' }, { kostId: 'other' }, { reservationId: 'other' },
  ]) await assertFails(updateDoc(ref, {
    ...changes, status: 'IN_PROGRESS', updatedAt: serverTimestamp(),
  }));
  await assertFails(deleteDoc(ref));
});

test('renters cannot edit or delete reports once processing has started', async () => {
  await seedApprovedReservation();
  await createTicket();
  await progressTicket();
  const ref = doc(database('renter-a'), 'tickets', 'ticket-a');
  await assertFails(updateDoc(ref, { title: 'Late content change', updatedAt: serverTimestamp() }));
  await assertFails(deleteDoc(ref));
  await updateDoc(doc(database('owner-a'), 'tickets', 'ticket-a'), { status: 'DONE', updatedAt: serverTimestamp() });
  await assertFails(updateDoc(ref, { title: 'Late content change', updatedAt: serverTimestamp() }));
  await assertFails(deleteDoc(ref));
});

test('oversized notes and forged status update timestamps are denied', async () => {
  await seedApprovedReservation();
  await createTicket();
  const ref = doc(database('owner-a'), 'tickets', 'ticket-a');
  await assertFails(updateDoc(ref, {
    status: 'IN_PROGRESS', ownerNote: 'x'.repeat(2001), updatedAt: serverTimestamp(),
  }));
  await assertFails(updateDoc(ref, { status: 'IN_PROGRESS', updatedAt: Timestamp.fromMillis(1) }));
});

test('creating a ticket cannot approve its reservation in the same client batch', async () => {
  await seedApprovedReservation({ status: 'PENDING' });
  const db = database('renter-a'), batch = writeBatch(db);
  batch.update(doc(db, 'reservations', 'reservation-a'), { status: 'APPROVED', updatedAt: serverTimestamp() });
  batch.set(doc(db, 'tickets', 'ticket-a'), ticketData());
  await assertFails(batch.commit());
});

const verificationData = (overrides = {}) => ({
  ownerId: 'owner-a', name: 'Owner A', email: 'Owner A@example.com', phone: '081234567890',
  ktpNumber: '1234567890123456', propertyName: 'Kost Melati',
  propertyAddress: 'Jalan Melati 10', propertyType: 'CAMPUR',
  ktpImageUrl: 'https://example.com/ktp.jpg',
  sertifikatImageUrl: 'https://example.com/sertifikat.jpg',
  fotoRumahImageUrl: 'https://example.com/kost.jpg',
  status: 'PROSES', rejectionReason: null, reviewedBy: null, reviewedAt: null,
  submittedAt: serverTimestamp(), updatedAt: serverTimestamp(), ...overrides,
});
const submitVerification = (overrides = {}, uid = 'owner-a') => setDoc(
  doc(database(uid), 'ownerVerifications', uid), verificationData(overrides),
);
const reviewData = (approve = true, reviewer = 'admin-a') => ({
  status: approve ? 'ACC' : 'TOLAK',
  rejectionReason: approve ? null : 'Foto KTP tidak terbaca, silakan perbaiki.',
  reviewedBy: reviewer, reviewedAt: serverTimestamp(), updatedAt: serverTimestamp(),
});
function reviewVerification(db, approve = true, overrides = {}) {
  const batch = writeBatch(db);
  batch.update(doc(db, 'ownerVerifications', 'owner-a'), { ...reviewData(approve), ...overrides });
  batch.update(doc(db, 'users', 'owner-a'), { isVerified: approve });
  return batch.commit();
}

test('owner submits a real verification and admin can read the queue and owner profile', async () => {
  await assertSucceeds(submitVerification());
  await assertSucceeds(getDocs(collection(database('admin-a'), 'ownerVerifications')));
  await assertSucceeds(getDoc(doc(database('admin-a'), 'users', 'owner-a')));
  await assertSucceeds(getDoc(doc(database('owner-a'), 'ownerVerifications', 'owner-a')));
});
test('verification documents are private to their owner and admins', async () => {
  await submitVerification();
  for (const uid of ['owner-b', 'renter-a']) {
    await assertFails(getDoc(doc(database(uid), 'ownerVerifications', 'owner-a')));
    await assertFails(getDocs(collection(database(uid), 'ownerVerifications')));
  }
  await assertFails(getDoc(doc(environment.unauthenticatedContext().firestore(), 'ownerVerifications', 'owner-a')));
  await assertSucceeds(getDocs(collection(database('admin-a'), 'users')));
  await assertSucceeds(getDoc(doc(database('admin-a'), 'users', 'renter-a')));
});
test('renter cannot submit and an owner cannot impersonate another owner', async () => {
  await assertFails(submitVerification({ ownerId: 'renter-a' }, 'renter-a'));
  await assertFails(setDoc(doc(database('owner-b'), 'ownerVerifications', 'owner-a'), verificationData()));
  await assertFails(submitVerification({ name: 'Another Name' }));
  await assertFails(submitVerification({ email: 'other@example.com' }));
});
test('invalid verification data and forged review metadata are denied', async () => {
  for (const overrides of [
    { ktpNumber: '123' }, { propertyName: '   ' }, { propertyAddress: '' },
    { propertyType: 'INVALID' }, { ktpImageUrl: '/local/ktp.jpg' },
    { ktpImageUrl: 'verificationDocuments/owner-a/12345678-1234-4234-a234-123456789012/ktp.png' },
    { ktpImageUrl: 'https://user:pass@example.com/ktp.jpg' },
    { ktpImageUrl: 'https://example.com/a\tb.jpg' },
    { ktpImageUrl: 'https://example.com/' + 'a'.repeat(2048) },
    { sertifikatImageUrl: 'http://example.com/file.jpg' },
    { fotoRumahImageUrl: 'https://example.com/a b.jpg' },
    { status: 'ACC' }, { reviewedBy: 'admin-a' }, { reviewedAt: Timestamp.now() },
    { rejectionReason: 'Alasan palsu oleh pemilik' },
    { submittedAt: Timestamp.fromMillis(1) }, { updatedAt: Timestamp.fromMillis(1) },
    { isVerified: true },
  ]) await assertFails(submitVerification(overrides));
});
test('pending verification cannot be overwritten by owner or reviewed by other roles', async () => {
  await submitVerification();
  await assertFails(submitVerification({ propertyName: 'Changed' }));
  for (const uid of ['owner-a', 'owner-b', 'renter-a']) {
    await assertFails(reviewVerification(database(uid), true, { reviewedBy: uid }));
  }
});
test('admin approval atomically updates the verification and owner flag', async () => {
  await submitVerification();
  await assertSucceeds(reviewVerification(database('admin-a')));
  assert.equal((await getDoc(doc(database('owner-a'), 'users', 'owner-a'))).data().isVerified, true);
  const data = (await getDoc(doc(database('owner-a'), 'ownerVerifications', 'owner-a'))).data();
  assert.equal(data.status, 'ACC');
  assert.equal(data.reviewedBy, 'admin-a');
  assert.ok(data.reviewedAt instanceof Timestamp);
});
test('approval cannot change only the verification or only the owner flag', async () => {
  await submitVerification();
  const db = database('admin-a');
  await assertFails(updateDoc(doc(db, 'ownerVerifications', 'owner-a'), reviewData()));
  await assertFails(updateDoc(doc(db, 'users', 'owner-a'), { isVerified: true }));
  await assertFails(updateDoc(doc(db, 'users', 'owner-b'), { isVerified: true }));
});
test('approval cannot change owner profile data, role, documents or reviewer identity', async () => {
  await submitVerification();
  const db = database('admin-a');
  for (const extra of [{ role: 'ADMIN' }, { name: 'Altered' }]) {
    const batch = writeBatch(db);
    batch.update(doc(db, 'ownerVerifications', 'owner-a'), reviewData());
    batch.update(doc(db, 'users', 'owner-a'), { isVerified: true, ...extra });
    await assertFails(batch.commit());
  }
  for (const overrides of [
    { reviewedBy: 'admin-b' }, { ktpNumber: '9999999999999999' },
    { reviewedAt: Timestamp.fromMillis(1) }, { updatedAt: Timestamp.fromMillis(1) },
    { rejectionReason: 'Approval cannot contain a rejection reason' },
  ]) await assertFails(reviewVerification(db, true, overrides));
});
test('rejection requires a reason and never verifies the owner', async () => {
  await submitVerification();
  const db = database('admin-a');
  for (const rejectionReason of [null, '', 'short', ' '.repeat(12), 'x'.repeat(301)]) {
    await assertFails(reviewVerification(db, false, { rejectionReason }));
  }
  const batch = writeBatch(db);
  batch.update(doc(db, 'ownerVerifications', 'owner-a'), reviewData(false));
  batch.update(doc(db, 'users', 'owner-a'), { isVerified: true });
  await assertFails(batch.commit());
  await assertSucceeds(reviewVerification(db, false));
  assert.equal((await getDoc(doc(database('owner-a'), 'users', 'owner-a'))).data().isVerified, false);
});
test('rejected owner can correct documents and resubmit with cleared audit fields', async () => {
  await submitVerification();
  await reviewVerification(database('admin-a'), false);
  await assertFails(reviewVerification(database('admin-b'), true, { reviewedBy: 'admin-b' }));
  await assertFails(submitVerification({ reviewedBy: 'admin-a' }));
  await assertSucceeds(submitVerification({ ktpImageUrl: 'https://example.com/clear-ktp.jpg' }));
  await assertSucceeds(reviewVerification(database('admin-a')));
});
test('approved decisions cannot be overwritten, resubmitted, or deleted', async () => {
  await submitVerification();
  await reviewVerification(database('admin-a'));
  await assertFails(reviewVerification(database('admin-b'), false, { reviewedBy: 'admin-b' }));
  await assertFails(submitVerification());
  for (const uid of ['admin-a', 'owner-a']) {
    await assertFails(deleteDoc(doc(database(uid), 'ownerVerifications', 'owner-a')));
  }
});
test('only one of two concurrent admin decisions can commit', async () => {
  await submitVerification();
  const results = await Promise.allSettled([
    reviewVerification(database('admin-a')),
    reviewVerification(database('admin-b'), false, { reviewedBy: 'admin-b' }),
  ]);
  assert.equal(results.filter((result) => result.status === 'fulfilled').length, 1);
  const db = database('owner-a');
  const submission = (await getDoc(doc(db, 'ownerVerifications', 'owner-a'))).data();
  const owner = (await getDoc(doc(db, 'users', 'owner-a'))).data();
  assert.equal(owner.isVerified, submission.status === 'ACC');
});

test('only admins can list all user profiles for user management', async () => {
  const result = await assertSucceeds(getDocs(collection(database('admin-a'), 'users')));
  assert.equal(result.size, 6);
  for (const uid of ['owner-a', 'renter-a']) {
    await assertFails(getDocs(collection(database(uid), 'users')));
  }
  await assertFails(getDocs(collection(environment.unauthenticatedContext().firestore(), 'users')));
});
test('reading user management does not grant account mutation privileges', async () => {
  const db = database('admin-a');
  for (const uid of ['owner-a', 'renter-a', 'admin-b']) {
    await assertFails(updateDoc(doc(db, 'users', uid), { role: 'ADMIN' }));
    await assertFails(updateDoc(doc(db, 'users', uid), { name: 'Changed by admin' }));
    await assertFails(deleteDoc(doc(db, 'users', uid)));
  }
});

test('owner can submit external HTTPS image URLs with access tokens', async () => {
  await assertSucceeds(submitVerification({
    ktpImageUrl: 'https://example.com/ktp%20pemilik.png?token=abc&alt=media',
    sertifikatImageUrl: 'https://example.com/images/certificate?id=123',
    fotoRumahImageUrl: 'https://example.com/property.webp',
  }));
});
test('submission requires HTTPS URLs instead of legacy Storage references', async () => {
  for (const ktpImageUrl of [
    'verificationDocuments/owner-a/12345678-1234-4234-a234-123456789012/ktp.png',
    'verificationDocuments/owner-b/12345678-1234-4234-a234-123456789012/ktp.png',
    'verificationDocuments/owner-a/12345678-1234-4234-a234-123456789012/certificate.png',
    'verificationDocuments/owner-a/short/ktp.png',
    'verificationDocuments/owner-a/12345678-1234-4234-a234-123456789012/ktp.exe',
  ]) await assertFails(submitVerification({ ktpImageUrl }));
});
