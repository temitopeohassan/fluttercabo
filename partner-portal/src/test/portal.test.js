import { describe, expect, it } from 'vitest'
import { DEMO_PASSWORD, signIn } from '../api/auth'
import * as portal from '../api/portal'
import { freshData, load } from '../api/store'
import { addDays, lagosDate } from '../lib/format'

const as = (email) => signIn({ email, password: DEMO_PASSWORD })
const ADAEZE = 'adaeze@ekonaturetrails.ng'
const today = () => lagosDate()

const completeTour = {
  title: 'Lagos Lagoon Sunset Cruise', category: 'Island Tours', area: 'Victoria Island',
  description: 'Watch the sun set over the lagoon from a private boat with drinks and a guide.',
  durationMinutes: 120, price: 20000, minGroup: 1, maxGroup: 8, languages: ['English'], meetingPoint: 'Tarzan Jetty',
  itinerary: ['Board', 'Cruise', 'Return'], inclusions: ['Drinks'], photos: ['/images/tours/tarkwa-bay.jpg'],
}

describe('demo data', () => {
  it('moves seeded dates forward so there are bookings today', () => {
    const data = freshData()
    const todays = data.slots.filter((s) => lagosDate(s.startsAt) === today())
    expect(todays.length).toBeGreaterThan(0)
  })
})

describe('tours (P-02)', () => {
  it('saves a draft and only sends a complete tour for review', async () => {
    await as(ADAEZE)
    const draft = await portal.saveTour({ title: 'Half-finished tour' })
    expect(draft.status).toBe('draft')
    const error = await portal.saveTour({ id: draft.id, title: 'Half-finished tour' }, { submit: true }).catch((e) => e)
    expect(Object.keys(error.fields)).toEqual(expect.arrayContaining(['description', 'price', 'photos', 'itinerary']))
    const sent = await portal.saveTour({ ...completeTour, id: draft.id }, { submit: true })
    expect(sent.status).toBe('in_review')
  })

  it('keeps a live tour bookable while its changes are reviewed', async () => {
    await as(ADAEZE)
    const tour = await portal.getTour('t1')
    const saved = await portal.saveTour({ ...tour, price: 16000 }, { submit: true })
    expect(saved).toMatchObject({ status: 'live', changesInReview: true, price: 16000 })
  })

  it('does not let a pending partner send tours for review', async () => {
    await as('kunle@badagryroots.ng')
    await expect(portal.saveTour(completeTour, { submit: true })).rejects.toThrow('once your partner application is approved')
  })

  it('will not delete a tour with bookings', async () => {
    await as(ADAEZE)
    await expect(portal.deleteTour('t1')).rejects.toThrow('has bookings')
  })
})

describe('availability (P-03)', () => {
  it('adds slots on chosen days and skips ones that already exist', async () => {
    await as(ADAEZE)
    const from = addDays(today(), 40)
    const first = await portal.addSlots({ tourId: 't1', from, to: addDays(from, 6), days: [6], times: ['08:00', '16:00'], capacity: 6 })
    expect(first).toEqual({ added: 2, skipped: 0 })
    const again = await portal.addSlots({ tourId: 't1', from, to: addDays(from, 6), days: [6], times: ['08:00'], capacity: 6 })
    expect(again).toEqual({ added: 0, skipped: 1 })
  })

  it('blocks a date and refunds the bookings on it in full', async () => {
    await as(ADAEZE)
    const booking = load().bookings.find((b) => b.partnerId === 'p1' && b.status === 'confirmed' && lagosDate(load().slots.find((s) => s.id === b.slotId).startsAt) > today())
    const date = lagosDate(load().slots.find((s) => s.id === booking.slotId).startsAt)
    const preview = await portal.bookingsOnDate({ date, tourId: 't1' })
    expect(preview.map((b) => b.id)).toContain(booking.id)
    const result = await portal.blockDate({ date, tourId: 't1', reason: 'Storm warning' })
    expect(result.cancelled).toBe(preview.length)
    expect((await portal.getBooking(booking.id)).status).toBe('cancelled')
    expect((await portal.getBooking(booking.id)).refund).toBe(booking.gross)
    const cal = await portal.availability({ from: date, to: date, tourId: 't1' })
    expect(cal.slots.every((s) => s.blocked)).toBe(true)
  })

  it('will not drop capacity below the guests already booked', async () => {
    await as(ADAEZE)
    const { slots } = await portal.availability({ from: today(), to: addDays(today(), 28), tourId: 't1' })
    const slot = slots.find((s) => s.booked > 1)
    await expect(portal.updateSlotCapacity(slot.id, slot.booked - 1)).rejects.toThrow('already booked')
  })
})

describe('bookings and check-in (P-04, P-05)', () => {
  it('checks in today’s guest by QR and refuses a second scan', async () => {
    await as(ADAEZE)
    const { bookings } = await portal.todaysGuests()
    const b = bookings.find((x) => x.status === 'confirmed')
    const first = await portal.lookUpTicket(portal.qrPayload(b.qrToken))
    expect(first).toMatchObject({ kind: 'tour', problem: null })
    await portal.checkIn({ kind: 'tour', id: b.id })
    const second = await portal.lookUpTicket(b.reference.toLowerCase())
    expect(second.problem).toMatch(/Already checked in/)
  })

  it('refuses tickets for another day or another partner', async () => {
    await as(ADAEZE)
    const future = (await portal.listBookings({ view: 'upcoming' })).find((b) => lagosDate(b.slot.startsAt) > today())
    expect((await portal.lookUpTicket(future.reference)).problem).toMatch(/This ticket is for/)
    const other = load().bookings.find((b) => b.partnerId === 'p2')
    expect((await portal.lookUpTicket(other.qrToken)).message).toMatch(/another partner/)
    expect((await portal.lookUpTicket('cabo:ticket:NOTREAL')).kind).toBe('error')
  })

  it('never shows one partner another partner’s booking', async () => {
    await as('funmi@funmiisland.ng')
    const adaezes = load().bookings.find((b) => b.partnerId === 'p1')
    await expect(portal.getBooking(adaezes.id)).rejects.toThrow('not found')
    expect((await portal.listBookings({ view: 'all' })).every((b) => b.partnerId === 'p2')).toBe(true)
  })

  it('cancels a booking with a reason and a full refund', async () => {
    await as(ADAEZE)
    const b = (await portal.listBookings({ view: 'upcoming' })).find((x) => x.status === 'confirmed' && lagosDate(x.slot.startsAt) > today())
    await expect(portal.cancelBooking(b.id, '')).rejects.toThrow('why')
    const cancelled = await portal.cancelBooking(b.id, 'Rough seas')
    expect(cancelled).toMatchObject({ status: 'cancelled', cancelledBy: 'partner', refund: b.gross, net: 0 })
  })
})

describe('earnings, reviews, tickets and concierge (P-06 to P-09)', () => {
  it('splits commission at 15% and lists payouts', async () => {
    await as(ADAEZE)
    const e = await portal.earnings()
    expect(e.commissionRate).toBe(15)
    for (const p of e.payouts) expect(p.amount).toBe(p.gross - p.commission)
    expect(e.payouts.length).toBeGreaterThan(4)
    expect(new Date(`${e.nextPayout}T12:00:00Z`).getUTCDay()).toBe(2)
  })

  it('posts and edits a reply to a review', async () => {
    await as(ADAEZE)
    const r = (await portal.listReviews()).find((x) => !x.reply)
    await expect(portal.replyToReview(r.id, '  ')).rejects.toThrow()
    expect((await portal.replyToReview(r.id, 'Thank you!')).reply.text).toBe('Thank you!')
  })

  it('lets a venue admit a ticket for today once', async () => {
    await as('ifeoma@lekkiartshub.ng')
    const { tickets } = await portal.todaysGuests()
    const t = tickets.find((x) => x.status === 'valid')
    expect((await portal.lookUpTicket(t.reference)).kind).toBe('entry')
    await portal.checkIn({ kind: 'entry', id: t.id })
    expect((await portal.lookUpTicket(t.reference)).problem).toMatch(/already been used/)
  })

  it('sends new ticket types for review', async () => {
    await as('ifeoma@lekkiartshub.ng')
    const t = await portal.saveTicketType({ name: 'Night tour', price: 5000, dailyCapacity: 40 })
    expect(t.status).toBe('in_review')
  })

  it('books a hotel guest an airport pickup at the fixed price', async () => {
    await as('bisi@lagoonhouse.ng')
    const bad = await portal.bookConcierge({ type: 'airport_pickup', rideType: 'suv', passengers: 7 }).catch((e) => e)
    expect(Object.keys(bad.fields)).toEqual(expect.arrayContaining(['guestName', 'guestPhone', 'flightNumber', 'rideType']))
    const b = await portal.bookConcierge({
      type: 'airport_pickup', guestName: 'Ada Guest', guestPhone: '+447700900999', pickupDate: addDays(today(), 2), pickupTime: '15:30',
      flightNumber: 'ba 75', rideType: 'comfort', passengers: 2, billTo: 'hotel_account',
    })
    expect(b).toMatchObject({ price: 22000, flightNumber: 'BA75', status: 'requested', to: 'The Lagoon House, Ikoyi' })
  })

  it('estimates a ride from the hotel with the backend fare formula', () => {
    const hotel = { lat: 6.4512, lng: 3.4321 }
    const est = portal.estimateConcierge({ type: 'ride', rideType: 'economy', destination: 'Lekki Conservation Centre' }, hotel)
    expect(est.price).toBeGreaterThan(1500)
    expect(est.fixed).toBe(false)
  })
})

describe('settings', () => {
  it('needs a 10-digit account number and logs bank changes', async () => {
    await as(ADAEZE)
    await expect(portal.updateBank({ name: 'GTBank', accountNumber: '123', accountName: 'X' })).rejects.toThrow()
    await portal.updateBank({ name: 'Kuda', accountNumber: '2000000001', accountName: 'Eko Nature Trails' })
    expect((await portal.listNotifications())[0].title).toBe('Bank details changed')
  })

  it('exports the partner’s data without password hashes', async () => {
    await as(ADAEZE)
    const data = await portal.exportData()
    expect(data.partner.id).toBe('p1')
    expect(JSON.stringify(data)).not.toContain('"hash"')
    expect(data.bookings.every((b) => b.partnerId === 'p1')).toBe(true)
  })
})
