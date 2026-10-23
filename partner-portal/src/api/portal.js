// Partner portal data access. Every function works on the signed-in
// partner's own records only, the way the backend API will.
import { addDays, lagosDate, lagosInstant, weekday } from '../lib/format'
import { getSession } from './auth'
import { ApiError, load, newId, read, reference, transaction } from './store'

function partnerId() {
  const session = getSession()
  if (!session) throw new ApiError('Your session has ended. Please sign in again.', { status: 401 })
  return session.partnerId
}

const own = (list, id, pid, what = 'record') => {
  const item = list.find((x) => x.id === id && x.partnerId === pid)
  if (!item) throw new ApiError(`That ${what} was not found.`, { status: 404 })
  return item
}

const activeBooking = (b) => !['cancelled'].includes(b.status)
const bookedOn = (db, slotId) => db.bookings.filter((b) => b.slotId === slotId && activeBooking(b)).reduce((n, b) => n + b.guests, 0)
const isBlocked = (db, pid, tourId, date) => db.blockedDates.find((x) => x.partnerId === pid && x.date === date && (!x.tourId || x.tourId === tourId))

function notify(db, pid, n) {
  const partner = db.partners.find((p) => p.id === pid)
  const prefs = partner.notifications
  const channels = [prefs.email && 'email', prefs.whatsapp && prefs.whatsappNumber && 'whatsapp'].filter(Boolean)
  db.notifications.push({ id: newId('n'), partnerId: pid, read: false, createdAt: new Date().toISOString(), channels, ...n })
}

// ---------------------------------------------------------------- Dashboard

export async function dashboard() {
  const pid = partnerId()
  return read((db) => {
    const today = lagosDate()
    const tours = db.tours.filter((t) => t.partnerId === pid)
    const slots = db.slots.filter((s) => tours.some((t) => t.id === s.tourId))
    const bookings = db.bookings.filter((b) => b.partnerId === pid)
    const slotOf = (b) => slots.find((s) => s.id === b.slotId)
    const todaysSlots = slots
      .filter((s) => lagosDate(s.startsAt) === today)
      .map((s) => {
        const list = bookings.filter((b) => b.slotId === s.id && activeBooking(b))
        return {
          ...s,
          tour: tours.find((t) => t.id === s.tourId),
          guests: list.reduce((n, b) => n + b.guests, 0),
          checkedIn: list.filter((b) => b.status === 'checked_in' || b.status === 'completed').reduce((n, b) => n + b.guests, 0),
          blocked: Boolean(isBlocked(db, pid, s.tourId, today)),
        }
      })
      .sort((a, b) => a.startsAt.localeCompare(b.startsAt))
    const month = today.slice(0, 7)
    const monthBookings = bookings.filter((b) => slotOf(b) && lagosDate(slotOf(b).startsAt).slice(0, 7) === month && b.status !== 'cancelled')
    const next7 = bookings.filter((b) => {
      const s = slotOf(b)
      return s && b.status === 'confirmed' && lagosDate(s.startsAt) >= today && lagosDate(s.startsAt) <= addDays(today, 7)
    })
    const reviews = db.reviews.filter((r) => r.partnerId === pid)
    const tickets = db.ticketSales.filter((t) => t.partnerId === pid)
    const concierge = db.conciergeBookings.filter((c) => c.partnerId === pid)
    return {
      todaysSlots,
      upcoming: next7
        .map((b) => ({ ...b, slot: slotOf(b), tour: tours.find((t) => t.id === b.tourId) }))
        .sort((a, b) => a.slot.startsAt.localeCompare(b.slot.startsAt))
        .slice(0, 6),
      stats: {
        guestsNext7: next7.reduce((n, b) => n + b.guests, 0),
        bookingsNext7: next7.length,
        netThisMonth: monthBookings.reduce((n, b) => n + b.net, 0) + tickets.filter((t) => t.visitDate.slice(0, 7) === month).reduce((n, t) => n + t.net, 0),
        rating: reviews.length ? reviews.reduce((n, r) => n + r.rating, 0) / reviews.length : null,
        reviews: reviews.length,
        unanswered: reviews.filter((r) => !r.reply).length,
        ticketsToday: tickets.filter((t) => t.visitDate === today).reduce((n, t) => n + t.quantity, 0),
        ticketsUsedToday: tickets.filter((t) => t.visitDate === today && t.status === 'used').reduce((n, t) => n + t.quantity, 0),
        conciergeUpcoming: concierge.filter((c) => !['completed', 'cancelled'].includes(c.status) && c.pickupAt >= new Date().toISOString()).length,
        conciergeMonth: concierge.filter((c) => c.billTo === 'hotel_account' && c.status !== 'cancelled' && lagosDate(c.pickupAt).slice(0, 7) === month).reduce((n, c) => n + c.price, 0),
      },
      listings: {
        live: tours.filter((t) => t.status === 'live').length,
        inReview: tours.filter((t) => t.status === 'in_review' || t.changesInReview).length,
        changesRequested: tours.filter((t) => t.status === 'changes_requested').length,
        drafts: tours.filter((t) => t.status === 'draft').length,
      },
      awaitingReply: reviews.filter((r) => !r.reply).sort((a, b) => b.createdAt.localeCompare(a.createdAt)).slice(0, 3)
        .map((r) => ({ ...r, tour: tours.find((t) => t.id === r.tourId) })),
      expiringDocuments: db.partners.find((p) => p.id === pid).documents.filter((d) => d.expiresOn && d.expiresOn <= addDays(today, 30)),
    }
  })
}

// ---------------------------------------------------------------- Tours (P-02)

export async function listTours() {
  const pid = partnerId()
  return read((db) =>
    db.tours
      .filter((t) => t.partnerId === pid)
      .map((t) => {
        const upcoming = db.bookings.filter((b) => b.tourId === t.id && b.status === 'confirmed')
        const reviews = db.reviews.filter((r) => r.tourId === t.id)
        return {
          ...t,
          upcomingBookings: upcoming.length,
          rating: reviews.length ? reviews.reduce((n, r) => n + r.rating, 0) / reviews.length : null,
          reviewCount: reviews.length,
        }
      })
      .sort((a, b) => b.updatedAt.localeCompare(a.updatedAt)),
  )
}

export async function getTour(id) {
  const pid = partnerId()
  return read((db) => own(db.tours, id, pid, 'tour'))
}

/** Problems that stop a tour being sent for review. */
export function tourProblems(tour) {
  const problems = {}
  if (!tour.title?.trim()) problems.title = 'Add a title.'
  if (!tour.description || tour.description.trim().length < 40) problems.description = 'Describe the tour in at least 40 characters.'
  if (!tour.category) problems.category = 'Choose a category.'
  if (!tour.area?.trim()) problems.area = 'Add the area.'
  if (!(tour.price > 0)) problems.price = 'Set a price per person.'
  if (!(tour.durationMinutes >= 30)) problems.durationMinutes = 'Duration must be at least 30 minutes.'
  if (!(tour.minGroup >= 1) || !(tour.maxGroup >= tour.minGroup)) problems.maxGroup = 'Maximum group size must be at least the minimum.'
  if (!tour.meetingPoint?.trim()) problems.meetingPoint = 'Add a meeting point.'
  if (!tour.itinerary?.filter(Boolean).length) problems.itinerary = 'Add at least one itinerary step.'
  if (!tour.inclusions?.filter(Boolean).length) problems.inclusions = 'List what is included.'
  if (!tour.photos?.length) problems.photos = 'Add at least one photo.'
  if (!tour.languages?.length) problems.languages = 'Choose at least one language.'
  return problems
}

/**
 * Saves a tour. `submit` sends it for Cabo review (P-02: listings go live
 * after review). Editing a live tour keeps it bookable and flags the
 * changes for review.
 */
export async function saveTour(input, { submit = false } = {}) {
  const pid = partnerId()
  const clean = {
    title: input.title?.trim() || '',
    category: input.category || '',
    area: input.area?.trim() || '',
    description: input.description?.trim() || '',
    durationMinutes: Number(input.durationMinutes) || 0,
    price: Number(input.price) || 0,
    minGroup: Number(input.minGroup) || 1,
    maxGroup: Number(input.maxGroup) || 1,
    languages: input.languages || [],
    meetingPoint: input.meetingPoint?.trim() || '',
    meetingLat: input.meetingLat === '' || input.meetingLat == null ? null : Number(input.meetingLat),
    meetingLng: input.meetingLng === '' || input.meetingLng == null ? null : Number(input.meetingLng),
    itinerary: (input.itinerary || []).map((s) => s.trim()).filter(Boolean),
    inclusions: (input.inclusions || []).map((s) => s.trim()).filter(Boolean),
    exclusions: (input.exclusions || []).map((s) => s.trim()).filter(Boolean),
    addons: (input.addons || []).filter((a) => a.name?.trim()).map((a) => ({ id: a.id || newId('a'), name: a.name.trim(), price: Number(a.price) || 0, per: a.per === 'person' ? 'person' : 'booking' })),
    cancellationPolicy: input.cancellationPolicy || 'flexible',
    photos: input.photos || [],
    guideIds: input.guideIds || [],
    wheelchairAccessible: Boolean(input.wheelchairAccessible),
  }
  if (!clean.title) throw new ApiError('Add a title before saving.', { fields: { title: 'Add a title.' } })
  if (submit) {
    const problems = tourProblems(clean)
    if (Object.keys(problems).length) throw new ApiError('Finish these before sending the tour for review.', { fields: problems })
  }

  return transaction((db) => {
    const partner = db.partners.find((p) => p.id === pid)
    if (submit && partner.status !== 'approved') {
      throw new ApiError('You can send tours for review once your partner application is approved. Save it as a draft for now.', { status: 403 })
    }
    const now = new Date().toISOString()
    let tour = input.id ? own(db.tours, input.id, pid, 'tour') : null
    if (!tour) {
      tour = { id: newId('t'), partnerId: pid, status: 'draft', changesInReview: false, reviewNote: null, schedule: { times: [], days: [], capacity: clean.maxGroup }, createdAt: now }
      db.tours.push(tour)
    }
    Object.assign(tour, clean, { updatedAt: now })
    if (submit) {
      if (tour.status === 'live' || tour.status === 'paused') tour.changesInReview = true
      else tour.status = 'in_review'
      tour.reviewNote = null
      tour.submittedAt = now
    }
    return tour
  })
}

/** Pause or resume a live listing. Paused tours stay visible here but cannot be booked. */
export async function setTourPaused(id, paused) {
  const pid = partnerId()
  return transaction((db) => {
    const tour = own(db.tours, id, pid, 'tour')
    if (!['live', 'paused'].includes(tour.status)) throw new ApiError('Only live tours can be paused.')
    tour.status = paused ? 'paused' : 'live'
    tour.updatedAt = new Date().toISOString()
    return tour
  })
}

export async function deleteTour(id) {
  const pid = partnerId()
  return transaction((db) => {
    const tour = own(db.tours, id, pid, 'tour')
    if (db.bookings.some((b) => b.tourId === id)) throw new ApiError('This tour has bookings, so it cannot be deleted. Pause it instead.')
    db.tours = db.tours.filter((t) => t.id !== tour.id)
    db.slots = db.slots.filter((s) => s.tourId !== tour.id)
  })
}

// ---------------------------------------------------------------- Availability (P-03)

export async function availability({ from, to, tourId }) {
  const pid = partnerId()
  return read((db) => {
    const tours = db.tours.filter((t) => t.partnerId === pid && (!tourId || t.id === tourId))
    const slots = db.slots
      .filter((s) => tours.some((t) => t.id === s.tourId))
      .filter((s) => {
        const d = lagosDate(s.startsAt)
        return d >= from && d <= to
      })
      .map((s) => ({ ...s, date: lagosDate(s.startsAt), booked: bookedOn(db, s.id), blocked: Boolean(isBlocked(db, pid, s.tourId, lagosDate(s.startsAt))) }))
      .sort((a, b) => a.startsAt.localeCompare(b.startsAt))
    const blocked = db.blockedDates.filter((b) => b.partnerId === pid && b.date >= from && b.date <= to && (!tourId || !b.tourId || b.tourId === tourId))
    return { slots, blocked }
  })
}

/** Adds slots at the given Lagos times on the chosen weekdays between two dates. */
export async function addSlots({ tourId, from, to, days, times, capacity }) {
  const pid = partnerId()
  const fields = {}
  if (!tourId) fields.tourId = 'Choose a tour.'
  if (!from || !to || to < from) fields.to = 'The end date must be on or after the start date.'
  if (to && from && to > addDays(from, 180)) fields.to = 'Add up to 6 months at a time.'
  if (!days?.length) fields.days = 'Choose at least one day.'
  if (!times?.filter(Boolean).length) fields.times = 'Add at least one start time.'
  if (!(capacity >= 1)) fields.capacity = 'Capacity must be at least 1.'
  if (Object.keys(fields).length) throw new ApiError('Please check the slot details.', { fields })

  return transaction((db) => {
    const tour = own(db.tours, tourId, pid, 'tour')
    if (capacity > tour.maxGroup * 4) throw new ApiError(`That is more than four times the tour's maximum group of ${tour.maxGroup}.`, { fields: { capacity: 'Too high.' } })
    let added = 0
    let skipped = 0
    const now = new Date().toISOString()
    for (let date = from; date <= to; date = addDays(date, 1)) {
      if (!days.includes(weekday(date))) continue
      for (const time of times.filter(Boolean)) {
        const startsAt = lagosInstant(date, time)
        if (startsAt <= now || db.slots.some((s) => s.tourId === tourId && s.startsAt === startsAt)) {
          skipped++
          continue
        }
        db.slots.push({ id: newId('s'), tourId, startsAt, capacity: Number(capacity) })
        added++
      }
    }
    tour.schedule = { times: [...new Set(times.filter(Boolean))].sort(), days: [...days].sort(), capacity: Number(capacity) }
    return { added, skipped }
  })
}

export async function updateSlotCapacity(slotId, capacity) {
  const pid = partnerId()
  return transaction((db) => {
    const slot = db.slots.find((s) => s.id === slotId)
    own(db.tours, slot?.tourId, pid, 'slot')
    const booked = bookedOn(db, slotId)
    if (capacity < Math.max(1, booked)) throw new ApiError(`${booked} guests are already booked, so capacity cannot go below ${Math.max(1, booked)}.`)
    slot.capacity = Number(capacity)
    return slot
  })
}

export async function deleteSlot(slotId) {
  const pid = partnerId()
  return transaction((db) => {
    const slot = db.slots.find((s) => s.id === slotId)
    own(db.tours, slot?.tourId, pid, 'slot')
    if (bookedOn(db, slotId) > 0) throw new ApiError('This slot has bookings. Block the date instead, which cancels and refunds them.')
    db.slots = db.slots.filter((s) => s.id !== slotId)
  })
}

/** Bookings that blocking a date would cancel, so the partner can confirm first. */
export async function bookingsOnDate({ date, tourId }) {
  const pid = partnerId()
  return read((db) =>
    db.bookings
      .filter((b) => b.partnerId === pid && b.status === 'confirmed' && (!tourId || b.tourId === tourId))
      .filter((b) => lagosDate(db.slots.find((s) => s.id === b.slotId).startsAt) === date)
      .map((b) => ({ ...b, tour: db.tours.find((t) => t.id === b.tourId) })),
  )
}

/** Blocks a date for one tour or all tours. Confirmed bookings on it are cancelled with a full refund. */
export async function blockDate({ date, tourId, reason }) {
  const pid = partnerId()
  if (!date) throw new ApiError('Choose a date.', { fields: { date: 'Choose a date.' } })
  if (date < lagosDate()) throw new ApiError('You cannot block a date in the past.', { fields: { date: 'Past date.' } })
  return transaction((db) => {
    if (tourId) own(db.tours, tourId, pid, 'tour')
    if (db.blockedDates.some((b) => b.partnerId === pid && b.date === date && (b.tourId || null) === (tourId || null))) {
      throw new ApiError('That date is already blocked.')
    }
    const now = new Date().toISOString()
    const cancelled = db.bookings.filter((b) => b.partnerId === pid && b.status === 'confirmed' && (!tourId || b.tourId === tourId) && lagosDate(db.slots.find((s) => s.id === b.slotId).startsAt) === date)
    for (const b of cancelled) {
      Object.assign(b, { status: 'cancelled', cancelledAt: now, cancelledBy: 'partner', refund: b.gross, commission: 0, net: 0 })
    }
    db.blockedDates.push({ id: newId('b'), partnerId: pid, tourId: tourId || null, date, reason: reason?.trim() || '' })
    return { cancelled: cancelled.length, guests: cancelled.reduce((n, b) => n + b.guests, 0) }
  })
}

export async function unblockDate(id) {
  const pid = partnerId()
  return transaction((db) => {
    own(db.blockedDates, id, pid, 'blocked date')
    db.blockedDates = db.blockedDates.filter((b) => b.id !== id)
  })
}

// ---------------------------------------------------------------- Bookings (P-04)

function decorate(db, b) {
  const slot = db.slots.find((s) => s.id === b.slotId)
  const tour = db.tours.find((t) => t.id === b.tourId)
  return { ...b, slot, tour: { id: tour.id, title: tour.title, meetingPoint: tour.meetingPoint, cancellationPolicy: tour.cancellationPolicy, price: tour.price } }
}

export async function listBookings({ view = 'upcoming', tourId, q, date } = {}) {
  const pid = partnerId()
  return read((db) => {
    const now = new Date().toISOString()
    const term = q?.trim().toLowerCase()
    return db.bookings
      .filter((b) => b.partnerId === pid)
      .map((b) => decorate(db, b))
      .filter((b) => (!tourId || b.tourId === tourId) && (!date || lagosDate(b.slot.startsAt) === date))
      .filter((b) => !term || b.reference.toLowerCase().includes(term) || b.guestName.toLowerCase().includes(term))
      .filter((b) => {
        if (view === 'cancelled') return b.status === 'cancelled'
        if (view === 'past') return b.slot.startsAt < now && b.status !== 'cancelled'
        if (view === 'upcoming') return b.slot.startsAt >= now && b.status !== 'cancelled'
        return true
      })
      .sort((a, b) => (view === 'upcoming' ? a.slot.startsAt.localeCompare(b.slot.startsAt) : b.slot.startsAt.localeCompare(a.slot.startsAt)))
  })
}

export async function getBooking(id) {
  const pid = partnerId()
  return read((db) => {
    const b = own(db.bookings, id, pid, 'booking')
    return { ...decorate(db, b), review: db.reviews.find((r) => r.bookingId === id) || null }
  })
}

/** Partner cancels a booking (for example bad weather). The guest gets a full refund. */
export async function cancelBooking(id, reason) {
  const pid = partnerId()
  if (!reason?.trim()) throw new ApiError('Tell the guest why you are cancelling.', { fields: { reason: 'Add a reason.' } })
  return transaction((db) => {
    const b = own(db.bookings, id, pid, 'booking')
    if (b.status !== 'confirmed') throw new ApiError('Only confirmed bookings can be cancelled.')
    Object.assign(b, { status: 'cancelled', cancelledAt: new Date().toISOString(), cancelledBy: 'partner', cancellationReason: reason.trim(), refund: b.gross, commission: 0, net: 0 })
    return b
  })
}

export async function markNoShow(id) {
  const pid = partnerId()
  return transaction((db) => {
    const b = own(db.bookings, id, pid, 'booking')
    const slot = db.slots.find((s) => s.id === b.slotId)
    if (b.status !== 'confirmed' || slot.startsAt > new Date().toISOString()) throw new ApiError('You can mark a no-show once the tour has started.')
    b.status = 'no_show'
    return b
  })
}

// ---------------------------------------------------------------- Check-in (P-05, R-TR-08)

/** Accepts a scanned QR payload (cabo:ticket:<token>), a bare token or a booking reference. */
export async function lookUpTicket(code) {
  const pid = partnerId()
  const raw = String(code || '').trim()
  const value = raw.replace(/^cabo:(ticket|tour|entry):/i, '')
  if (!value) throw new ApiError('Scan a ticket or type its reference.')
  return read((db) => {
    const today = lagosDate()
    const booking = db.bookings.find((b) => b.qrToken === value || b.reference.toUpperCase() === value.toUpperCase())
    if (booking) {
      if (booking.partnerId !== pid) return { kind: 'error', message: 'This ticket is for another partner’s tour.' }
      const b = decorate(db, booking)
      const date = lagosDate(b.slot.startsAt)
      let problem = null
      if (b.status === 'cancelled') problem = 'This booking was cancelled.'
      else if (b.status === 'checked_in' || b.status === 'completed') problem = `Already checked in${b.checkedInAt ? ` at ${new Date(b.checkedInAt).toLocaleTimeString('en-GB', { timeZone: 'Africa/Lagos', hour: '2-digit', minute: '2-digit' })}` : ''}.`
      else if (b.status === 'no_show') problem = 'This booking was marked as a no-show.'
      else if (date !== today) problem = `This ticket is for ${new Date(b.slot.startsAt).toLocaleDateString('en-GB', { timeZone: 'Africa/Lagos', weekday: 'long', day: 'numeric', month: 'long' })}.`
      return { kind: 'tour', booking: b, problem }
    }
    const sale = db.ticketSales.find((t) => t.qrToken === value || t.reference.toUpperCase() === value.toUpperCase())
    if (sale) {
      if (sale.partnerId !== pid) return { kind: 'error', message: 'This ticket is for another venue.' }
      const type = db.ticketTypes.find((t) => t.id === sale.ticketTypeId)
      let problem = null
      if (sale.status === 'used') problem = 'This ticket has already been used.'
      else if (sale.status !== 'valid') problem = `This ticket is ${sale.status}.`
      else if (sale.visitDate !== today) problem = `This ticket is for ${new Date(`${sale.visitDate}T12:00:00Z`).toLocaleDateString('en-GB', { weekday: 'long', day: 'numeric', month: 'long' })}.`
      return { kind: 'entry', sale: { ...sale, type }, problem }
    }
    return { kind: 'error', message: 'No Cabo ticket matches this code.' }
  })
}

export async function checkIn({ kind, id }) {
  const pid = partnerId()
  return transaction((db) => {
    const now = new Date().toISOString()
    if (kind === 'entry') {
      const sale = own(db.ticketSales, id, pid, 'ticket')
      if (sale.status !== 'valid' || sale.visitDate !== lagosDate()) throw new ApiError('This ticket cannot be used now.')
      Object.assign(sale, { status: 'used', usedAt: now })
      return sale
    }
    const b = own(db.bookings, id, pid, 'booking')
    const slot = db.slots.find((s) => s.id === b.slotId)
    if (b.status !== 'confirmed' || lagosDate(slot.startsAt) !== lagosDate()) throw new ApiError('This booking cannot be checked in now.')
    Object.assign(b, { status: 'checked_in', checkedInAt: now })
    return b
  })
}

/** Today's guests for the manual check-in list. */
export async function todaysGuests() {
  const pid = partnerId()
  return read((db) => {
    const today = lagosDate()
    const bookings = db.bookings
      .filter((b) => b.partnerId === pid && b.status !== 'cancelled')
      .map((b) => decorate(db, b))
      .filter((b) => lagosDate(b.slot.startsAt) === today)
      .sort((a, b) => a.slot.startsAt.localeCompare(b.slot.startsAt) || a.guestName.localeCompare(b.guestName))
    const tickets = db.ticketSales
      .filter((t) => t.partnerId === pid && t.visitDate === today && t.status !== 'refunded')
      .map((t) => ({ ...t, type: db.ticketTypes.find((x) => x.id === t.ticketTypeId) }))
    return { bookings, tickets }
  })
}

// ---------------------------------------------------------------- Earnings (P-06)

export async function earnings() {
  const pid = partnerId()
  return read((db) => {
    const partner = db.partners.find((p) => p.id === pid)
    const payouts = db.payouts.filter((p) => p.partnerId === pid).sort((a, b) => b.periodEnd.localeCompare(a.periodEnd))
    const lastPaidThrough = payouts[0]?.periodEnd || '0000-00-00'
    // Earned items: tour bookings once the tour has happened, tickets once the visit date has passed.
    const items = [
      ...db.bookings
        .filter((b) => b.partnerId === pid && (b.status !== 'cancelled' || b.net > 0))
        .map((b) => {
          const slot = db.slots.find((s) => s.id === b.slotId)
          return { id: b.id, kind: 'tour', reference: b.reference, date: lagosDate(slot.startsAt), title: db.tours.find((t) => t.id === b.tourId).title, guest: b.guestName, gross: b.gross - (b.refund || 0), commission: b.commission, net: b.net, status: b.status }
        }),
      ...db.ticketSales
        .filter((t) => t.partnerId === pid)
        .map((t) => ({ id: t.id, kind: 'ticket', reference: t.reference, date: t.visitDate, title: db.ticketTypes.find((x) => x.id === t.ticketTypeId).name, guest: t.buyerName, gross: t.total, commission: t.commission, net: t.net, status: t.status })),
    ].sort((a, b) => b.date.localeCompare(a.date))
    const today = lagosDate()
    const earned = items.filter((i) => i.date < today)
    const unpaid = earned.filter((i) => i.date > lastPaidThrough)
    const months = []
    for (let i = 5; i >= 0; i--) {
      const d = new Date(`${today.slice(0, 7)}-15T12:00:00Z`)
      d.setUTCMonth(d.getUTCMonth() - i)
      const key = d.toISOString().slice(0, 7)
      const inMonth = items.filter((x) => x.date.slice(0, 7) === key)
      months.push({ month: key, gross: inMonth.reduce((n, x) => n + x.gross, 0), net: inMonth.reduce((n, x) => n + x.net, 0) })
    }
    const nextPayout = (() => {
      const d = new Date(`${today}T12:00:00Z`)
      do d.setUTCDate(d.getUTCDate() + 1)
      while (d.getUTCDay() !== 2)
      return d.toISOString().slice(0, 10)
    })()
    return {
      commissionRate: partner.commissionRate,
      bank: partner.bank,
      payouts,
      items,
      months,
      totals: {
        paid: payouts.filter((p) => p.status === 'paid').reduce((n, p) => n + p.amount, 0),
        processing: payouts.filter((p) => p.status === 'processing').reduce((n, p) => n + p.amount, 0),
        unpaid: unpaid.reduce((n, x) => n + x.net, 0),
        upcoming: items.filter((i) => i.date >= today && i.status !== 'cancelled').reduce((n, x) => n + x.net, 0),
        commissionYear: items.filter((i) => i.date.slice(0, 4) === today.slice(0, 4)).reduce((n, x) => n + x.commission, 0),
      },
      nextPayout,
    }
  })
}

export function toCsv(rows, columns) {
  const escape = (v) => {
    const s = v == null ? '' : String(v)
    return /[",\n]/.test(s) ? `"${s.replace(/"/g, '""')}"` : s
  }
  return [columns.map((c) => c.label).join(','), ...rows.map((r) => columns.map((c) => escape(typeof c.value === 'function' ? c.value(r) : r[c.value])).join(','))].join('\n')
}

// ---------------------------------------------------------------- Reviews (P-07)

export async function listReviews() {
  const pid = partnerId()
  return read((db) =>
    db.reviews
      .filter((r) => r.partnerId === pid)
      .map((r) => ({ ...r, tour: db.tours.find((t) => t.id === r.tourId) }))
      .sort((a, b) => b.createdAt.localeCompare(a.createdAt)),
  )
}

export async function replyToReview(id, text) {
  const pid = partnerId()
  const clean = text?.trim()
  if (!clean) throw new ApiError('Write a reply first.', { fields: { reply: 'Write a reply.' } })
  if (clean.length > 1000) throw new ApiError('Keep replies under 1,000 characters.', { fields: { reply: 'Too long.' } })
  return transaction((db) => {
    const r = own(db.reviews, id, pid, 'review')
    r.reply = { text: clean, at: new Date().toISOString() }
    return r
  })
}

export async function deleteReply(id) {
  const pid = partnerId()
  return transaction((db) => {
    own(db.reviews, id, pid, 'review').reply = null
  })
}

// ---------------------------------------------------------------- Tickets (P-08)

export async function listTicketTypes() {
  const pid = partnerId()
  return read((db) => {
    const today = lagosDate()
    return db.ticketTypes
      .filter((t) => t.partnerId === pid)
      .map((t) => {
        const sales = db.ticketSales.filter((s) => s.ticketTypeId === t.id)
        return {
          ...t,
          soldToday: sales.filter((s) => s.visitDate === today).reduce((n, s) => n + s.quantity, 0),
          sold30: sales.filter((s) => s.visitDate > addDays(today, -30) && s.visitDate <= today).reduce((n, s) => n + s.quantity, 0),
        }
      })
  })
}

export async function saveTicketType(input) {
  const pid = partnerId()
  const fields = {}
  if (!input.name?.trim()) fields.name = 'Name the ticket.'
  if (!(Number(input.price) > 0)) fields.price = 'Set a price.'
  if (!(Number(input.dailyCapacity) >= 1)) fields.dailyCapacity = 'Set how many can be sold per day.'
  if (Object.keys(fields).length) throw new ApiError('Please check the ticket details.', { fields })
  return transaction((db) => {
    const now = new Date().toISOString()
    let t = input.id ? own(db.ticketTypes, input.id, pid, 'ticket') : null
    const priceChanged = t && t.price !== Number(input.price)
    if (!t) {
      t = { id: newId('tt'), partnerId: pid, status: 'in_review', createdAt: now }
      db.ticketTypes.push(t)
    }
    Object.assign(t, { name: input.name.trim(), description: input.description?.trim() || '', price: Number(input.price), dailyCapacity: Number(input.dailyCapacity), validFor: input.validFor?.trim() || 'Any one day', updatedAt: now })
    if (priceChanged && t.status === 'live') t.changesInReview = true
    return t
  })
}

export async function setTicketPaused(id, paused) {
  const pid = partnerId()
  return transaction((db) => {
    const t = own(db.ticketTypes, id, pid, 'ticket')
    if (!['live', 'paused'].includes(t.status)) throw new ApiError('Only live tickets can be paused.')
    t.status = paused ? 'paused' : 'live'
    return t
  })
}

export async function listTicketSales({ date, q } = {}) {
  const pid = partnerId()
  return read((db) => {
    const term = q?.trim().toLowerCase()
    return db.ticketSales
      .filter((s) => s.partnerId === pid && (!date || s.visitDate === date))
      .filter((s) => !term || s.reference.toLowerCase().includes(term) || s.buyerName.toLowerCase().includes(term))
      .map((s) => ({ ...s, type: db.ticketTypes.find((t) => t.id === s.ticketTypeId) }))
      .sort((a, b) => b.visitDate.localeCompare(a.visitDate) || b.createdAt.localeCompare(a.createdAt))
  })
}

// ---------------------------------------------------------------- Hotel concierge (P-09)

export const RIDE_TYPES = [
  { code: 'economy', name: 'Economy', seats: 4, base: 700, perKm: 120, perMinute: 20, minimum: 1500, airport: 18000 },
  { code: 'comfort', name: 'Comfort', seats: 4, base: 1000, perKm: 170, perMinute: 28, minimum: 2200, airport: 22000 },
  { code: 'suv', name: 'SUV', seats: 6, base: 1500, perKm: 240, perMinute: 38, minimum: 3200, airport: 30000 },
  { code: 'premium', name: 'Premium', seats: 4, base: 2200, perKm: 360, perMinute: 55, minimum: 4800, airport: 45000 },
]

export const DESTINATIONS = [
  { name: 'Terra Kulture, Victoria Island', lat: 6.4335, lng: 3.4229 },
  { name: 'Nike Art Gallery, Lekki Phase 1', lat: 6.4371, lng: 3.4848 },
  { name: 'Lekki Conservation Centre', lat: 6.4413, lng: 3.5357 },
  { name: 'Freedom Park, Lagos Island', lat: 6.4527, lng: 3.3937 },
  { name: 'Tarzan Jetty (Tarkwa Bay boats), Victoria Island', lat: 6.4268, lng: 3.4291 },
  { name: 'The Palms Shopping Mall, Lekki', lat: 6.4359, lng: 3.451 },
  { name: 'Landmark Beach, Oniru', lat: 6.421, lng: 3.443 },
  { name: 'Eko Atlantic City', lat: 6.4065, lng: 3.4108 },
  { name: 'National Stadium, Surulere', lat: 6.4997, lng: 3.3647 },
]

const AIRPORT = 'Murtala Muhammed International (LOS), Terminal 2'

function distanceKm(a, b) {
  const rad = (d) => (d * Math.PI) / 180
  const dLat = rad(b.lat - a.lat)
  const dLng = rad(b.lng - a.lng)
  const h = Math.sin(dLat / 2) ** 2 + Math.cos(rad(a.lat)) * Math.cos(rad(b.lat)) * Math.sin(dLng / 2) ** 2
  return 6371 * 2 * Math.atan2(Math.sqrt(h), Math.sqrt(1 - h))
}

/** Same upfront formula as the backend's FareCalculator, without surge. Airport trips have fixed prices. */
export function estimateConcierge({ type, destination, rideType }, hotel) {
  const ride = RIDE_TYPES.find((r) => r.code === rideType)
  if (!ride) return null
  if (type !== 'ride') return { price: ride.airport, fixed: true }
  const place = DESTINATIONS.find((d) => d.name === destination)
  if (!place || !hotel?.lat) return null
  const km = Math.max(0.5, distanceKm(hotel, place) * 1.35)
  const minutes = Math.max(3, Math.ceil((km / 22) * 60))
  return { price: Math.max(ride.minimum, Math.round(ride.base + km * ride.perKm + minutes * ride.perMinute)), fixed: false, km: Math.round(km * 10) / 10, minutes }
}

export async function listConcierge() {
  const pid = partnerId()
  return read((db) => db.conciergeBookings.filter((c) => c.partnerId === pid).sort((a, b) => b.pickupAt.localeCompare(a.pickupAt)))
}

export async function bookConcierge(input) {
  const pid = partnerId()
  const fields = {}
  if (!input.guestName?.trim()) fields.guestName = 'Add the guest’s name.'
  if (!/^\+?[0-9 ]{8,16}$/.test(input.guestPhone || '')) fields.guestPhone = 'Add the guest’s phone number so the driver can reach them.'
  if (!input.pickupDate || !input.pickupTime) fields.pickupTime = 'Choose the pickup time.'
  else if (lagosInstant(input.pickupDate, input.pickupTime) < new Date(Date.now() + 10 * 60000).toISOString()) fields.pickupTime = 'Pickup must be at least 10 minutes from now.'
  if (input.type === 'ride' && !input.destination) fields.destination = 'Choose where the guest is going.'
  if (input.type !== 'ride' && !/^[A-Z0-9]{2}\s?\d{1,4}$/i.test(input.flightNumber || '')) fields.flightNumber = 'Add the flight number, e.g. BA75.'
  const ride = RIDE_TYPES.find((r) => r.code === input.rideType)
  if (!ride) fields.rideType = 'Choose a car.'
  else if (Number(input.passengers) > ride.seats) fields.rideType = `${ride.name} seats up to ${ride.seats}.`
  if (Object.keys(fields).length) throw new ApiError('Please check the booking details.', { fields })

  return transaction((db) => {
    const hotel = db.partners.find((p) => p.id === pid)
    if (hotel.type !== 'hotel' || hotel.status !== 'approved') throw new ApiError('Concierge booking is for approved hotel partners.', { status: 403 })
    const estimate = estimateConcierge(input, hotel)
    const here = `${hotel.name}, ${hotel.area}`
    const booking = {
      id: newId('cb'), partnerId: pid, reference: reference(input.type === 'ride' ? 'CB' : 'SH'), type: input.type,
      guestName: input.guestName.trim(), guestPhone: input.guestPhone.trim(), room: input.room?.trim() || '',
      pickupAt: lagosInstant(input.pickupDate, input.pickupTime),
      from: input.type === 'airport_pickup' ? AIRPORT : here,
      to: input.type === 'ride' ? input.destination : input.type === 'airport_pickup' ? here : AIRPORT,
      flightNumber: input.type === 'ride' ? null : input.flightNumber.toUpperCase().replace(/\s/g, ''),
      rideType: input.rideType, passengers: Number(input.passengers) || 1, price: estimate.price, billTo: input.billTo === 'guest' ? 'guest' : 'hotel_account',
      status: 'requested', driver: null, notes: input.notes?.trim() || null, createdAt: new Date().toISOString(), createdBy: getSession().userId,
    }
    db.conciergeBookings.push(booking)
    return booking
  })
}

export async function cancelConcierge(id) {
  const pid = partnerId()
  return transaction((db) => {
    const c = own(db.conciergeBookings, id, pid, 'booking')
    if (!['requested', 'driver_assigned'].includes(c.status)) throw new ApiError('This booking can no longer be cancelled.')
    c.status = 'cancelled'
    return c
  })
}

// ---------------------------------------------------------------- Notifications (P-04)

export async function listNotifications() {
  const pid = partnerId()
  return read((db) => db.notifications.filter((n) => n.partnerId === pid).sort((a, b) => b.createdAt.localeCompare(a.createdAt)))
}

export function unreadCount() {
  const session = getSession()
  if (!session) return 0
  return load().notifications.filter((n) => n.partnerId === session.partnerId && !n.read).length
}

export async function markNotificationsRead(ids) {
  const pid = partnerId()
  return transaction((db) => {
    for (const n of db.notifications) if (n.partnerId === pid && (!ids || ids.includes(n.id))) n.read = true
  })
}

// ---------------------------------------------------------------- Business settings

export async function updatePartner(changes) {
  const pid = partnerId()
  return transaction((db) => {
    const p = db.partners.find((x) => x.id === pid)
    const allowed = ['name', 'contactName', 'phone', 'whatsapp', 'address', 'area', 'description']
    if (changes.name !== undefined && !changes.name.trim()) throw new ApiError('Your business needs a name.', { fields: { name: 'Required.' } })
    for (const key of allowed) if (changes[key] !== undefined) p[key] = String(changes[key]).trim()
    return p
  })
}

export async function updateNotificationSettings(settings) {
  const pid = partnerId()
  if (settings.whatsapp && !/^\+?[0-9 ]{10,16}$/.test(settings.whatsappNumber || '')) {
    throw new ApiError('Add the WhatsApp number to send booking alerts to.', { fields: { whatsappNumber: 'Add a number, e.g. +234 802 123 4567.' } })
  }
  return transaction((db) => {
    const p = db.partners.find((x) => x.id === pid)
    p.notifications = { ...p.notifications, ...settings }
    return p
  })
}

export async function updateBank(bank) {
  const pid = partnerId()
  const fields = {}
  if (!bank.name?.trim()) fields.bankName = 'Choose your bank.'
  if (!/^\d{10}$/.test(bank.accountNumber || '')) fields.accountNumber = 'Nigerian account numbers (NUBAN) have 10 digits.'
  if (!bank.accountName?.trim()) fields.accountName = 'Add the account name.'
  if (Object.keys(fields).length) throw new ApiError('Please check your bank details.', { fields })
  return transaction((db) => {
    const p = db.partners.find((x) => x.id === pid)
    p.bank = { name: bank.name.trim(), accountNumber: bank.accountNumber, accountName: bank.accountName.trim().toUpperCase() }
    notify(db, pid, { type: 'account', title: 'Bank details changed', body: `Payouts will go to ${p.bank.name} ••••${p.bank.accountNumber.slice(-4)}. If this wasn't you, contact Cabo immediately.`, link: '/settings/bank' })
    return p
  })
}

export async function uploadDocument({ type, label, file, expiresOn }) {
  const pid = partnerId()
  if (!file) throw new ApiError('Choose a file.', { fields: { file: 'Choose a file.' } })
  if (file.size > 10 * 1024 * 1024) throw new ApiError('Files must be under 10 MB.', { fields: { file: 'Too large.' } })
  if (type === 'insurance' && !expiresOn) throw new ApiError('Add the insurance expiry date.', { fields: { expiresOn: 'Required for insurance.' } })
  return transaction((db) => {
    const p = db.partners.find((x) => x.id === pid)
    const doc = { id: newId('d'), type, label, fileName: file.name, fileSize: file.size, status: 'pending', expiresOn: expiresOn || null, uploadedAt: new Date().toISOString() }
    // A new upload replaces the earlier document of the same type.
    p.documents = [...p.documents.filter((d) => d.type !== type), doc]
    return doc
  })
}

export async function saveGuide(guide) {
  const pid = partnerId()
  const fields = {}
  if (!guide.name?.trim()) fields.name = 'Add the guide’s name.'
  if (!/^\+?[0-9 ]{10,16}$/.test(guide.phone || '')) fields.phone = 'Add a phone number.'
  if (!guide.languages?.length) fields.languages = 'Choose at least one language.'
  if (Object.keys(fields).length) throw new ApiError('Please check the guide details.', { fields })
  return transaction((db) => {
    const p = db.partners.find((x) => x.id === pid)
    const clean = { name: guide.name.trim(), phone: guide.phone.trim(), languages: guide.languages, bio: guide.bio?.trim() || '', idNumber: guide.idNumber?.trim() || '' }
    if (guide.id) Object.assign(p.guides.find((g) => g.id === guide.id), clean)
    else p.guides.push({ id: newId('g'), ...clean })
    return p.guides
  })
}

export async function removeGuide(id) {
  const pid = partnerId()
  return transaction((db) => {
    const p = db.partners.find((x) => x.id === pid)
    if (db.tours.some((t) => t.partnerId === pid && t.status === 'live' && t.guideIds.includes(id) && t.guideIds.length === 1)) {
      throw new ApiError('This guide is the only guide on a live tour. Add another guide to that tour first.')
    }
    p.guides = p.guides.filter((g) => g.id !== id)
    for (const t of db.tours.filter((x) => x.partnerId === pid)) t.guideIds = t.guideIds.filter((g) => g !== id)
  })
}

// ---------------------------------------------------------------- Privacy (NDPA 2023 / GDPR)

/** Everything Cabo holds about this partner, as a downloadable JSON object. */
export async function exportData() {
  const pid = partnerId()
  return read((db) => ({
    exportedAt: new Date().toISOString(),
    partner: db.partners.find((p) => p.id === pid),
    users: db.users.filter((u) => u.partnerId === pid).map(({ password: _password, ...u }) => u),
    tours: db.tours.filter((t) => t.partnerId === pid),
    slots: db.slots.filter((s) => db.tours.some((t) => t.partnerId === pid && t.id === s.tourId)),
    bookings: db.bookings.filter((b) => b.partnerId === pid),
    reviews: db.reviews.filter((r) => r.partnerId === pid),
    payouts: db.payouts.filter((p) => p.partnerId === pid),
    ticketTypes: db.ticketTypes.filter((t) => t.partnerId === pid),
    ticketSales: db.ticketSales.filter((t) => t.partnerId === pid),
    conciergeBookings: db.conciergeBookings.filter((c) => c.partnerId === pid),
  }))
}

export async function requestDeletion(reason) {
  const pid = partnerId()
  return transaction((db) => {
    const p = db.partners.find((x) => x.id === pid)
    p.deletionRequestedAt = new Date().toISOString()
    p.deletionReason = reason?.trim() || null
    return p
  })
}

export async function cancelDeletion() {
  const pid = partnerId()
  return transaction((db) => {
    const p = db.partners.find((x) => x.id === pid)
    delete p.deletionRequestedAt
    delete p.deletionReason
    return p
  })
}

export const qrPayload = (qrToken) => `cabo:ticket:${qrToken}`
