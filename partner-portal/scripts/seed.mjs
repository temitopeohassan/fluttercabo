// Generates src/data/db.json, the demo data for the partner portal.
//
//   node scripts/seed.mjs
//
// Dates are written relative to today. When the portal loads the file it
// moves every date forward by the days since `generatedOn`, so the demo
// always has bookings today and in the coming weeks.
import { pbkdf2Sync, randomBytes } from 'node:crypto'
import { writeFileSync } from 'node:fs'
import { fileURLToPath } from 'node:url'

const OUT = fileURLToPath(new URL('../src/data/db.json', import.meta.url))
const DEMO_PASSWORD = 'password123!'
const ITERATIONS = 100000

// Small seeded random generator so the file only changes when this script does.
let seed = 2026
const rand = () => ((seed = (seed * 1103515245 + 12345) % 2147483648) / 2147483648)
const pick = (list) => list[Math.floor(rand() * list.length)]
const int = (min, max) => min + Math.floor(rand() * (max - min + 1))
const token = (n = 24) => Array.from({ length: n }, () => 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'[Math.floor(rand() * 32)]).join('')

const today = new Date()
today.setUTCHours(0, 0, 0, 0)
const day = (offset, hour = 0, minute = 0) => {
  const d = new Date(today)
  d.setUTCDate(d.getUTCDate() + offset)
  d.setUTCHours(hour, minute, 0, 0)
  return d.toISOString()
}
const dateOnly = (offset) => day(offset).slice(0, 10)

function hashPassword(password) {
  const salt = randomBytes(16).toString('hex')
  const hash = pbkdf2Sync(password, salt, ITERATIONS, 32, 'sha256').toString('hex')
  return { salt, hash, iterations: ITERATIONS }
}

const COMMISSION = 15

const partners = [
  {
    id: 'p1', name: 'Eko Nature Trails', type: 'tour_operator', status: 'approved',
    contactName: 'Adaeze Nwankwo', email: 'bookings@ekonaturetrails.ng', phone: '+2348021234501', whatsapp: '+2348021234501',
    cacNumber: 'RC 1456721', address: '14 Admiralty Way, Lekki Phase 1, Lagos', area: 'Lekki',
    description: 'Small-group nature walks and wildlife trips around the Lekki peninsula, led by trained naturalists.',
    commissionRate: COMMISSION, appliedAt: day(-120, 9), approvedAt: day(-116, 15),
    bank: { name: 'GTBank', accountNumber: '0123456781', accountName: 'EKO NATURE TRAILS LTD' },
    notifications: { email: true, whatsapp: true, whatsappNumber: '+2348021234501', newBooking: true, cancellation: true, review: true, payout: true },
    documents: [
      { id: 'd1', type: 'cac', label: 'CAC certificate', fileName: 'cac-certificate.pdf', status: 'approved', expiresOn: null, uploadedAt: day(-120, 9) },
      { id: 'd2', type: 'insurance', label: 'Public liability insurance', fileName: 'insurance-2026.pdf', status: 'approved', expiresOn: dateOnly(24), uploadedAt: day(-120, 9) },
    ],
    guides: [
      { id: 'g1', name: 'Adaeze Nwankwo', phone: '+2348021234501', languages: ['English', 'Igbo'], bio: 'Naturalist with nine years leading walks at the conservation centre.', idNumber: 'NIN 4402 1189 330' },
      { id: 'g2', name: 'Samuel Ade', phone: '+2348021234511', languages: ['English', 'Yoruba', 'French'], bio: 'Birding specialist and former park ranger.', idNumber: 'NIN 5521 0093 117' },
    ],
  },
  {
    id: 'p2', name: 'Funmi Island Tours', type: 'tour_operator', status: 'approved',
    contactName: 'Funmi Ogunleye', email: 'hello@funmiisland.ng', phone: '+2348021234502', whatsapp: '+2348021234502',
    cacNumber: 'RC 1622093', address: 'Tarzan Jetty, Maroko Road, Victoria Island, Lagos', area: 'Victoria Island',
    description: 'Boat trips to the beaches across Lagos Harbour, with life jackets, umbrellas and lunch.',
    commissionRate: COMMISSION, appliedAt: day(-100, 11), approvedAt: day(-97, 10),
    bank: { name: 'Access Bank', accountNumber: '0698800211', accountName: 'FUNMI ISLAND TOURS' },
    notifications: { email: true, whatsapp: false, whatsappNumber: '', newBooking: true, cancellation: true, review: true, payout: true },
    documents: [
      { id: 'd3', type: 'cac', label: 'CAC certificate', fileName: 'cac.pdf', status: 'approved', expiresOn: null, uploadedAt: day(-100, 11) },
      { id: 'd4', type: 'insurance', label: 'Boat and passenger insurance', fileName: 'marine-insurance.pdf', status: 'approved', expiresOn: dateOnly(210), uploadedAt: day(-100, 11) },
    ],
    guides: [{ id: 'g3', name: 'Funmi Ogunleye', phone: '+2348021234502', languages: ['English', 'Yoruba'], bio: 'Grew up on the harbour and has run boat trips since 2015.', idNumber: 'NIN 3318 7720 954' }],
  },
  {
    id: 'p3', name: 'Badagry Roots Guides', type: 'guide', status: 'pending',
    contactName: 'Kunle Mobolaji', email: 'kunle@badagryroots.ng', phone: '+2348021234506', whatsapp: '+2348021234506',
    cacNumber: 'BN 3390021', address: '5 Marina Road, Badagry, Lagos', area: 'Badagry',
    description: 'Heritage day trips to Badagry led by a local historian.',
    commissionRate: COMMISSION, appliedAt: day(-1, 16), approvedAt: null,
    bank: { name: 'First Bank', accountNumber: '3012299001', accountName: 'KUNLE MOBOLAJI' },
    notifications: { email: true, whatsapp: true, whatsappNumber: '+2348021234506', newBooking: true, cancellation: true, review: true, payout: true },
    documents: [
      { id: 'd5', type: 'cac', label: 'Business name registration', fileName: 'bn-registration.jpg', status: 'pending', expiresOn: null, uploadedAt: day(-1, 16) },
      { id: 'd6', type: 'insurance', label: 'Public liability insurance', fileName: 'insurance.pdf', status: 'pending', expiresOn: dateOnly(300), uploadedAt: day(-1, 16) },
    ],
    guides: [{ id: 'g4', name: 'Kunle Mobolaji', phone: '+2348021234506', languages: ['English', 'Yoruba', 'Egun'], bio: 'Historian and Badagry native.', idNumber: 'NIN 7790 1123 448' }],
  },
  {
    id: 'p4', name: 'Lekki Arts Hub', type: 'attraction', status: 'approved',
    contactName: 'Ifeoma Chukwu', email: 'tickets@lekkiartshub.ng', phone: '+2348021234507', whatsapp: '+2348021234507',
    cacNumber: 'RC 1803344', address: '22 Admiralty Road, Lekki Phase 1, Lagos', area: 'Lekki',
    description: 'Galleries, a sculpture garden and live music on Saturday nights.',
    commissionRate: COMMISSION, appliedAt: day(-80, 10), approvedAt: day(-76, 12),
    bank: { name: 'Zenith Bank', accountNumber: '1014455667', accountName: 'LEKKI ARTS HUB LTD' },
    notifications: { email: true, whatsapp: true, whatsappNumber: '+2348021234507', newBooking: true, cancellation: true, review: true, payout: true },
    documents: [
      { id: 'd7', type: 'cac', label: 'CAC certificate', fileName: 'cac.pdf', status: 'approved', expiresOn: null, uploadedAt: day(-80, 10) },
      { id: 'd8', type: 'insurance', label: 'Public liability insurance', fileName: 'insurance.pdf', status: 'approved', expiresOn: dateOnly(150), uploadedAt: day(-80, 10) },
    ],
    guides: [],
  },
  {
    id: 'p5', name: 'The Lagoon House', type: 'hotel', status: 'approved',
    contactName: 'Bisi Lawal', email: 'concierge@lagoonhouse.ng', phone: '+2348021234508', whatsapp: '+2348021234508',
    cacNumber: 'RC 1288190', address: '9 Bourdillon Road, Ikoyi, Lagos', area: 'Ikoyi', lat: 6.4512, lng: 3.4321,
    description: 'Boutique hotel in Ikoyi.',
    commissionRate: 0, appliedAt: day(-60, 10), approvedAt: day(-58, 9),
    bank: { name: 'UBA', accountNumber: '2099911223', accountName: 'THE LAGOON HOUSE LTD' },
    notifications: { email: true, whatsapp: false, whatsappNumber: '', newBooking: true, cancellation: true, review: false, payout: true },
    documents: [{ id: 'd9', type: 'cac', label: 'CAC certificate', fileName: 'cac.pdf', status: 'approved', expiresOn: null, uploadedAt: day(-60, 10) }],
    guides: [],
  },
]

const users = [
  ['u1', 'p1', 'Adaeze Nwankwo', 'adaeze@ekonaturetrails.ng', '+2348021234501'],
  ['u2', 'p2', 'Funmi Ogunleye', 'funmi@funmiisland.ng', '+2348021234502'],
  ['u3', 'p3', 'Kunle Mobolaji', 'kunle@badagryroots.ng', '+2348021234506'],
  ['u4', 'p4', 'Ifeoma Chukwu', 'ifeoma@lekkiartshub.ng', '+2348021234507'],
  ['u5', 'p5', 'Bisi Lawal', 'bisi@lagoonhouse.ng', '+2348021234508'],
].map(([id, partnerId, name, email, phone]) => ({ id, partnerId, name, email, phone, role: 'owner', password: hashPassword(DEMO_PASSWORD), createdAt: partners.find((p) => p.id === partnerId).appliedAt }))

const policy = {
  flexible: 'Full refund up to 24 hours before the start. No refund after that.',
  moderate: 'Full refund up to 72 hours before the start. 50% refund up to 24 hours before. No refund after that.',
  strict: '50% refund up to 7 days before the start. No refund after that.',
}

const tours = [
  {
    id: 't1', partnerId: 'p1', title: 'Lekki Conservation Centre', category: 'Nature & Wildlife', area: 'Lekki',
    description: 'Walk the longest canopy walkway in Africa, spot mona monkeys and crocodiles, and learn how the reserve protects Lagos wetlands with a naturalist guide.',
    durationMinutes: 240, price: 15000, minGroup: 1, maxGroup: 10, languages: ['English', 'Yoruba'],
    meetingPoint: 'Lekki Conservation Centre main gate, Km 19 Lekki–Epe Expressway', meetingLat: 6.4413, meetingLng: 3.5357,
    itinerary: ['Meet your guide at the main gate', 'Nature trail and tree house', 'Canopy walkway (401 m)', 'Family park and picnic stop'],
    inclusions: ['Entry ticket', 'Canopy walkway ticket', 'Bottled water', 'Naturalist guide'], exclusions: ['Lunch', 'Hotel transfers'],
    addons: [{ id: 'a1', name: 'Photo pack (20 edited photos)', price: 5000, per: 'booking' }, { id: 'a2', name: 'Picnic lunch', price: 6000, per: 'person' }],
    cancellationPolicy: 'flexible', photos: ['/images/tours/lekki-conservation-centre.jpg'], guideIds: ['g1', 'g2'],
    wheelchairAccessible: false, status: 'live', changesInReview: false, reviewNote: null, schedule: { times: ['09:00', '14:00'], days: [0, 1, 2, 3, 4, 5, 6], capacity: 10 },
    createdAt: day(-115, 10), updatedAt: day(-20, 10),
  },
  {
    id: 't2', partnerId: 'p1', title: 'Lekki Lagoon Kayak at Sunrise', category: 'Nature & Wildlife', area: 'Lekki',
    description: 'Paddle the calm lagoon at first light past fishing villages and mangroves, then share breakfast on the shore.',
    durationMinutes: 180, price: 22000, minGroup: 2, maxGroup: 8, languages: ['English'],
    meetingPoint: 'Lekki Leisure Lake jetty', meetingLat: 6.4436, meetingLng: 3.5701,
    itinerary: ['Safety briefing and kit', 'Guided paddle through the mangroves', 'Breakfast on the shore'],
    inclusions: ['Kayak, paddle and life jacket', 'Breakfast', 'Guide'], exclusions: ['Transport to the jetty'],
    addons: [{ id: 'a3', name: 'Waterproof phone pouch', price: 2500, per: 'person' }],
    cancellationPolicy: 'moderate', photos: [], guideIds: ['g2'],
    wheelchairAccessible: false, status: 'in_review', changesInReview: false, reviewNote: null, schedule: { times: ['06:30'], days: [0, 6], capacity: 8 },
    createdAt: day(-3, 14), updatedAt: day(-2, 9),
  },
  {
    id: 't3', partnerId: 'p1', title: 'Omu Resort Wildlife Day', category: 'Nature & Wildlife', area: 'Ibeju-Lekki',
    description: 'A full day at a family wildlife park with a zoo, quad bikes and a pool.',
    durationMinutes: 420, price: 30000, minGroup: 2, maxGroup: 12, languages: ['English'],
    meetingPoint: '', meetingLat: null, meetingLng: null, itinerary: [], inclusions: [], exclusions: [], addons: [],
    cancellationPolicy: 'moderate', photos: [], guideIds: [], wheelchairAccessible: false, status: 'draft', changesInReview: false, reviewNote: null,
    schedule: { times: [], days: [], capacity: 12 }, createdAt: day(-1, 17), updatedAt: day(-1, 17),
  },
  {
    id: 't4', partnerId: 'p2', title: 'Tarkwa Bay Boat Trip', category: 'Island Tours', area: 'Lagos Harbour',
    description: 'Cross the harbour by speedboat to a sheltered beach for swimming and grilled fish, with life jackets and a beach umbrella waiting for you.',
    durationMinutes: 360, price: 25000, minGroup: 2, maxGroup: 12, languages: ['English', 'Yoruba'],
    meetingPoint: 'Tarzan Jetty, Maroko Road, Victoria Island', meetingLat: 6.4268, meetingLng: 3.4291,
    itinerary: ['Board at Tarzan Jetty', 'Speedboat across Lagos Harbour', 'Free time on Tarkwa Bay', 'Grilled fish lunch', 'Return boat'],
    inclusions: ['Return boat ride', 'Life jackets', 'Beach umbrella and chairs', 'Lunch'], exclusions: ['Drinks', 'Water sports'],
    addons: [{ id: 'a4', name: 'Jet ski (20 minutes)', price: 15000, per: 'person' }],
    cancellationPolicy: 'moderate', photos: ['/images/tours/tarkwa-bay.jpg'], guideIds: ['g3'],
    wheelchairAccessible: false, status: 'live', changesInReview: false, reviewNote: null, schedule: { times: ['09:00'], days: [0, 3, 5, 6], capacity: 12 },
    createdAt: day(-95, 10), updatedAt: day(-30, 10),
  },
  {
    id: 't5', partnerId: 'p2', title: 'Ilashe Beach Day', category: 'Island Tours', area: 'Lagos Harbour',
    description: 'A quieter beach west of Tarkwa with a private beach house for the day.',
    durationMinutes: 420, price: 35000, minGroup: 4, maxGroup: 10, languages: ['English'],
    meetingPoint: 'Tarzan Jetty, Maroko Road, Victoria Island', meetingLat: 6.4268, meetingLng: 3.4291,
    itinerary: ['Boat to Ilashe', 'Beach house and lunch', 'Return boat'], inclusions: ['Boat', 'Lunch', 'Beach house'], exclusions: ['Drinks'],
    addons: [], cancellationPolicy: 'strict', photos: [], guideIds: ['g3'], wheelchairAccessible: false,
    status: 'changes_requested', changesInReview: false,
    reviewNote: 'Please add at least two photos of the beach house and the boat operator\'s passenger insurance before we publish this tour.',
    schedule: { times: ['09:30'], days: [6], capacity: 10 }, createdAt: day(-9, 10), updatedAt: day(-6, 12),
  },
  {
    id: 't6', partnerId: 'p3', title: 'Badagry Slave Route Day Trip', category: 'Cultural Experiences', area: 'Badagry',
    description: 'A full day in Badagry: the Point of No Return, the Seriki Abass slave barracoon and the first storey building in Nigeria.',
    durationMinutes: 540, price: 45000, minGroup: 2, maxGroup: 12, languages: ['English', 'Yoruba'],
    meetingPoint: 'Cabo pickup point, Ozumba Mbadiwe Avenue, Victoria Island', meetingLat: 6.4321, meetingLng: 3.419,
    itinerary: ['Drive to Badagry', 'Seriki Abass barracoon', 'Point of No Return', 'First storey building', 'Return drive'],
    inclusions: ['Transport', 'Entry fees', 'Lunch', 'Guide'], exclusions: [], addons: [], cancellationPolicy: 'moderate', photos: [], guideIds: ['g4'],
    wheelchairAccessible: false, status: 'draft', changesInReview: false, reviewNote: null, schedule: { times: ['07:00'], days: [6], capacity: 12 },
    createdAt: day(-1, 16), updatedAt: day(-1, 16),
  },
]

// Slots: from shortly after each partner was approved to 28 days ahead, following each live tour's schedule.
const slots = []
for (const tour of tours.filter((t) => t.status === 'live')) {
  const firstDay = Math.ceil((new Date(partners.find((p) => p.id === tour.partnerId).approvedAt) - today) / 86400000) + 3
  for (let offset = firstDay; offset <= 28; offset++) {
    const weekday = new Date(day(offset)).getUTCDay()
    if (!tour.schedule.days.includes(weekday)) continue
    for (const time of tour.schedule.times) {
      const [h, m] = time.split(':').map(Number)
      // Times are Lagos local (UTC+1); stored in UTC.
      slots.push({ id: `s${slots.length + 1}`, tourId: tour.id, startsAt: day(offset, h - 1, m), capacity: tour.schedule.capacity })
    }
  }
}

const blockedDates = [{ id: 'b1', partnerId: 'p1', tourId: null, date: dateOnly(12), reason: 'Team training day' }]

const guests = [
  ['Tunde Bakare', 'tunde.bakare@example.co.uk', '+447700900123', 'United Kingdom'],
  ['Sarah Mitchell', 'sarah.mitchell@example.com', '+14155550142', 'United States'],
  ['Kwame Mensah', 'kwame.mensah@example.com.gh', '+233244123456', 'Ghana'],
  ['Oliver Hughes', 'oliver.hughes@example.co.uk', '+447700900456', 'United Kingdom'],
  ['Marie Dubois', 'marie.dubois@example.fr', '+33612345678', 'France'],
  ['Grace Achieng', 'grace.achieng@example.co.ke', '+254722987654', 'Kenya'],
  ['Emily Carter', 'emily.carter@example.ca', '+16475550199', 'Canada'],
  ['Amara Okafor', 'amara.okafor@example.com', '+2348031234567', 'Nigeria'],
  ['Daniel Kamau', 'daniel.kamau@example.co.ke', '+254712345678', 'Kenya'],
  ['Hannah Schmidt', 'hannah.schmidt@example.de', '+491701234567', 'Germany'],
  ['Lucas Silva', 'lucas.silva@example.com.br', '+5511987654321', 'Brazil'],
  ['Chiamaka Eze', 'chiamaka.eze@example.com', '+2348055512345', 'Nigeria'],
]
const requests = [null, null, null, 'Vegetarian lunch for one guest, please.', 'Travelling with a 7-year-old.', null, 'One guest uses a walking stick.', null, 'Celebrating a birthday!', null]

const bookings = []
const reviews = []
const comments = [
  [5, 'Our guide knew every tree and monkey by name. The canopy walk is not for the faint-hearted!'],
  [5, 'Brilliant day out. Well organised and the Cabo driver was waiting when we finished.'],
  [4, 'Loved it. Bring sunscreen and more water than you think.'],
  [5, 'The highlight of my trip to Lagos.'],
  [3, 'Good tour but it started 20 minutes late.'],
  [5, 'Great value and a really friendly group.'],
]
const replies = [
  'Thank you so much! We hope to see you on the lagoon kayak next time.',
  'Sorry about the late start. We have moved the briefing earlier so it does not happen again.',
]

for (const slot of slots) {
  const tour = tours.find((t) => t.id === slot.tourId)
  const offset = Math.round((new Date(slot.startsAt) - today) / 86400000)
  const isToday = offset === 0
  // Busier near today, and always some guests today so check-in can be tried.
  const count = isToday ? 3 : rand() < (offset < -45 ? 0.35 : offset < 0 ? 0.55 : 0.4) ? int(1, 2) : 0
  for (let n = 0; n < count; n++) {
    const taken = bookings.filter((b) => b.slotId === slot.id).map((b) => b.guestName)
    const [name, email, phone, country] = pick(guests.filter((g) => !taken.includes(g[0])))
    const booked = bookings.filter((b) => b.slotId === slot.id && b.status !== 'cancelled').reduce((a, b) => a + b.guests, 0)
    const groupSize = Math.min(int(tour.minGroup, Math.min(4, tour.maxGroup)), slot.capacity - booked)
    if (groupSize < tour.minGroup) break
    const addons = tour.addons.length && rand() < 0.35 ? [tour.addons[0]] : []
    const addonsTotal = addons.reduce((a, x) => a + (x.per === 'person' ? x.price * groupSize : x.price), 0)
    const gross = tour.price * groupSize + addonsTotal
    const past = offset < 0
    let status = past ? 'completed' : 'confirmed'
    if (rand() < 0.07) status = 'cancelled'
    if (past && status === 'completed' && rand() < 0.05) status = 'no_show'
    const refund = status === 'cancelled' ? gross : 0
    const kept = gross - refund
    const commission = Math.round((kept * COMMISSION) / 100)
    const createdOffset = offset - int(2, 12)
    const booking = {
      id: `bk${bookings.length + 1}`, reference: `TR-${token(6)}`, partnerId: tour.partnerId, tourId: tour.id, slotId: slot.id,
      guestName: name, guestEmail: email, guestPhone: phone, guestCountry: country, guests: groupSize,
      addons: addons.map((a) => ({ name: a.name, price: a.price, per: a.per })), specialRequests: pick(requests),
      rideAddon: rand() < 0.4, subtotal: tour.price * groupSize, addonsTotal, gross, refund, commission, net: kept - commission,
      status, qrToken: token(24), createdAt: day(createdOffset, int(7, 21), int(0, 59)),
      checkedInAt: past && status === 'completed' ? new Date(new Date(slot.startsAt).getTime() - 10 * 60000).toISOString() : null,
      cancelledAt: status === 'cancelled' ? day(Math.min(createdOffset + 1, offset - 2), 10) : null,
      cancelledBy: status === 'cancelled' ? 'guest' : null,
    }
    bookings.push(booking)
    if (status === 'completed' && rand() < 0.5) {
      const [rating, comment] = pick(comments)
      const replied = rand() < 0.5
      reviews.push({
        id: `r${reviews.length + 1}`, partnerId: tour.partnerId, tourId: tour.id, bookingId: booking.id, guestName: name, guestCountry: country,
        rating, comment, createdAt: day(offset + 1, 18), reply: replied ? { text: rating < 4 ? replies[1] : replies[0], at: day(offset + 2, 9) } : null,
      })
    }
  }
}

// Weekly payouts every Tuesday for the previous Monday–Sunday.
const payouts = []
for (const partner of partners.filter((p) => p.type !== 'hotel' && p.status === 'approved')) {
  for (let w = 15; w >= 0; w--) {
    const end = new Date(today)
    end.setUTCDate(end.getUTCDate() - ((end.getUTCDay() + 6) % 7) - 1 - 7 * w)
    const start = new Date(end)
    start.setUTCDate(start.getUTCDate() - 6)
    if (start < new Date(partner.approvedAt)) continue
    const inWeek = bookings.filter((b) => b.partnerId === partner.id && ['completed', 'no_show'].includes(b.status) && (() => {
      const s = new Date(slots.find((x) => x.id === b.slotId).startsAt)
      return s >= start && s <= new Date(end.getTime() + 86399000)
    })())
    let gross = inWeek.reduce((a, b) => a + b.gross, 0)
    if (partner.type === 'attraction') gross = int(60, 140) * 1000
    if (!gross) continue
    const commission = Math.round((gross * COMMISSION) / 100)
    const paidOn = new Date(end)
    paidOn.setUTCDate(paidOn.getUTCDate() + 2)
    payouts.push({
      id: `po${payouts.length + 1}`, partnerId: partner.id, reference: `PP-${token(6)}`,
      periodStart: start.toISOString().slice(0, 10), periodEnd: end.toISOString().slice(0, 10),
      bookings: partner.type === 'attraction' ? int(20, 50) : inWeek.length, gross, commission, amount: gross - commission,
      status: paidOn <= today ? 'paid' : 'processing', paidAt: paidOn <= today ? new Date(paidOn.getTime() + 10 * 3600000).toISOString() : null,
      bankName: partner.bank.name, bankAccountNumber: partner.bank.accountNumber,
    })
  }
}

const ticketTypes = [
  { id: 'tt1', partnerId: 'p4', name: 'General admission', description: 'All galleries and the sculpture garden.', price: 3000, dailyCapacity: 300, validFor: 'Any one day', status: 'live', createdAt: day(-75, 10) },
  { id: 'tt2', partnerId: 'p4', name: 'Student', description: 'With a valid student ID, shown at the door.', price: 1500, dailyCapacity: 100, validFor: 'Any one day', status: 'live', createdAt: day(-75, 10) },
  { id: 'tt3', partnerId: 'p4', name: 'Saturday live music', description: 'Entry after 18:00 on Saturdays, with a welcome drink.', price: 8000, dailyCapacity: 150, validFor: 'Saturday evening', status: 'live', createdAt: day(-60, 10) },
  { id: 'tt4', partnerId: 'p4', name: 'Family pass (2 adults, 2 children)', description: 'Saves ₦3,000 on four tickets.', price: 9000, dailyCapacity: 40, validFor: 'Any one day', status: 'in_review', createdAt: day(-2, 11) },
]
const ticketSales = []
for (let offset = -20; offset <= 10; offset++) {
  const n = offset === 0 ? 4 : int(0, 3)
  for (let i = 0; i < n; i++) {
    const type = pick(ticketTypes.filter((t) => t.status === 'live'))
    const quantity = int(1, 4)
    const [name, email, , country] = pick(guests)
    const total = type.price * quantity
    const commission = Math.round((total * COMMISSION) / 100)
    ticketSales.push({
      id: `ts${ticketSales.length + 1}`, partnerId: 'p4', ticketTypeId: type.id, reference: `TK-${token(6)}`, visitDate: dateOnly(offset),
      quantity, buyerName: name, buyerEmail: email, buyerCountry: country, total, commission, net: total - commission,
      status: offset < 0 ? (rand() < 0.9 ? 'used' : 'expired') : 'valid', qrToken: token(24), createdAt: day(offset - int(0, 5), int(8, 20)),
      usedAt: offset < 0 ? day(offset, int(10, 17)) : null,
    })
  }
}

const conciergeBookings = [
  ['airport_pickup', 'Hannah Schmidt', '+491701234567', '204', 1, 16, 'Murtala Muhammed International (LOS), Terminal 2', 'The Lagoon House, Ikoyi', 'LH568', 'comfort', 22000, 'hotel_account', 'driver_assigned'],
  ['ride', 'Oliver Hughes', '+447700900456', '311', 0, 19, 'The Lagoon House, Ikoyi', 'Terra Kulture, Victoria Island', null, 'comfort', 4200, 'guest', 'requested'],
  ['airport_dropoff', 'Marie Dubois', '+33612345678', '108', 2, 5, 'The Lagoon House, Ikoyi', 'Murtala Muhammed International (LOS), Terminal 2', 'AF149', 'suv', 30000, 'hotel_account', 'requested'],
  ['ride', 'Daniel Kamau', '+254712345678', '215', -1, 11, 'The Lagoon House, Ikoyi', 'Nike Art Gallery, Lekki Phase 1', null, 'economy', 3600, 'hotel_account', 'completed'],
  ['airport_pickup', 'Lucas Silva', '+5511987654321', '402', -3, 21, 'Murtala Muhammed International (LOS), Terminal 2', 'The Lagoon House, Ikoyi', 'EK783', 'premium', 45000, 'hotel_account', 'completed'],
  ['ride', 'Emily Carter', '+16475550199', '119', -5, 13, 'The Lagoon House, Ikoyi', 'Lekki Conservation Centre', null, 'comfort', 7800, 'guest', 'cancelled'],
].map(([type, guestName, guestPhone, room, offset, hour, from, to, flightNumber, rideType, price, billTo, status], i) => ({
  id: `cb${i + 1}`, partnerId: 'p5', reference: type === 'ride' ? `CB-${token(6)}` : `SH-${token(6)}`, type, guestName, guestPhone, room,
  pickupAt: day(offset, hour - 1, type === 'airport_dropoff' ? 0 : 30), from, to, flightNumber, rideType, passengers: type === 'ride' ? 1 : 2, price, billTo, status,
  driver: status === 'requested' || status === 'cancelled' ? null : { name: 'Emeka Nwosu', vehicle: 'Silver Toyota Corolla 2019', plate: 'LND 482 KJ', phone: '+2348012345678' },
  notes: null, createdAt: day(offset - 1, 15), createdBy: 'u5',
}))

const notifications = []
for (const b of bookings.filter((x) => new Date(x.createdAt) > new Date(day(-6)) && new Date(x.createdAt) <= new Date()).slice(-12)) {
  const tour = tours.find((t) => t.id === b.tourId)
  const slot = slots.find((s) => s.id === b.slotId)
  notifications.push({
    id: `n${notifications.length + 1}`, partnerId: b.partnerId, type: b.status === 'cancelled' ? 'cancellation' : 'booking',
    title: b.status === 'cancelled' ? `Booking cancelled: ${tour.title}` : `New booking: ${tour.title}`,
    body: `${b.guestName} · ${b.guests} ${b.guests === 1 ? 'guest' : 'guests'} · ${new Date(slot.startsAt).toUTCString().slice(0, 16)}`,
    link: `/bookings/${b.id}`, createdAt: b.createdAt, read: false, channels: ['email', 'whatsapp'],
  })
}
for (const r of reviews.filter((x) => !x.reply).slice(-3)) {
  notifications.push({ id: `n${notifications.length + 1}`, partnerId: r.partnerId, type: 'review', title: `New ${r.rating}-star review`, body: r.comment, link: '/reviews', createdAt: r.createdAt, read: false, channels: ['email'] })
}
for (const p of payouts.filter((x) => x.status === 'paid').slice(-4)) {
  notifications.push({ id: `n${notifications.length + 1}`, partnerId: p.partnerId, type: 'payout', title: `Payout sent: ₦${p.amount.toLocaleString('en-NG')}`, body: `Week of ${p.periodStart} to ${p.bankName}`, link: '/earnings', createdAt: p.paidAt, read: true, channels: ['email'] })
}
notifications.push({ id: `n${notifications.length + 1}`, partnerId: 'p2', type: 'listing', title: 'Changes requested: Ilashe Beach Day', body: tours[4].reviewNote, link: '/tours/t5', createdAt: day(-6, 12), read: false, channels: ['email'] })
notifications.push({ id: `n${notifications.length + 1}`, partnerId: 'p3', type: 'application', title: 'Application received', body: 'Thanks for applying. We review applications within 2 working days.', link: '/application', createdAt: day(-1, 16), read: false, channels: ['email'] })
notifications.push({ id: `n${notifications.length + 1}`, partnerId: 'p1', type: 'document', title: 'Insurance expires soon', body: 'Your public liability insurance expires in 24 days. Upload the renewed certificate to keep your tours live.', link: '/settings/documents', createdAt: day(0, 6), read: false, channels: ['email', 'whatsapp'] })
notifications.sort((a, b) => a.createdAt.localeCompare(b.createdAt))

const db = {
  version: 1,
  generatedOn: today.toISOString().slice(0, 10),
  settings: { commissionRate: COMMISSION, payoutDay: 'Tuesday', supportEmail: 'partners@caboapp.online', supportPhone: '+234 201 330 2226', categories: ['Island Tours', 'Cultural Experiences', 'City Tours', 'Nightlife', 'Nature & Wildlife', 'Food'], languages: ['English', 'Yoruba', 'Igbo', 'Hausa', 'Pidgin', 'French', 'Spanish', 'German', 'Portuguese', 'Egun'], policies: policy },
  partners, users, tours, slots, blockedDates, bookings, reviews, payouts, ticketTypes, ticketSales, conciergeBookings, notifications, passwordResets: [],
}

writeFileSync(OUT, JSON.stringify(db, null, 2) + '\n')
console.log(`Wrote ${OUT}: ${tours.length} tours, ${slots.length} slots, ${bookings.length} bookings, ${reviews.length} reviews, ${payouts.length} payouts, ${ticketSales.length} ticket sales`)
console.log(`Demo password for every account: ${DEMO_PASSWORD}`)
