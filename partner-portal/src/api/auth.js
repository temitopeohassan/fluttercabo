// Partner sign-in, applications (P-01) and password resets, backed by the
// users in db.json. Sessions are kept in localStorage ("keep me signed in")
// or sessionStorage (until the browser closes).
import { hashPassword, passwordProblems, verifyPassword } from '../lib/password'
import { ApiError, load, newId, read, token, transaction } from './store'

const SESSION_KEY = 'cabo-partner-portal:session'
const ATTEMPTS_KEY = 'cabo-partner-portal:sign-in-attempts'
const MAX_ATTEMPTS = 5
const LOCK_MINUTES = 15
const RESET_CODE_MINUTES = 15
const REMEMBER_DAYS = 30
const SESSION_HOURS = 12

const normaliseEmail = (email) => String(email || '').trim().toLowerCase()

function safeStorage(kind) {
  try {
    return window[kind]
  } catch {
    return null
  }
}

export function getSession() {
  for (const kind of ['localStorage', 'sessionStorage']) {
    const raw = safeStorage(kind)?.getItem(SESSION_KEY)
    if (!raw) continue
    const session = JSON.parse(raw)
    if (new Date(session.expiresAt) > new Date() && load().users.some((u) => u.id === session.userId)) return session
    safeStorage(kind)?.removeItem(SESSION_KEY)
  }
  return null
}

function startSession(user, remember) {
  const hours = remember ? REMEMBER_DAYS * 24 : SESSION_HOURS
  const session = { token: token(32), userId: user.id, partnerId: user.partnerId, expiresAt: new Date(Date.now() + hours * 3600000).toISOString() }
  safeStorage('localStorage')?.removeItem(SESSION_KEY)
  safeStorage('sessionStorage')?.removeItem(SESSION_KEY)
  safeStorage(remember ? 'localStorage' : 'sessionStorage')?.setItem(SESSION_KEY, JSON.stringify(session))
  return session
}

export function signOut() {
  safeStorage('localStorage')?.removeItem(SESSION_KEY)
  safeStorage('sessionStorage')?.removeItem(SESSION_KEY)
}

function attempts() {
  try {
    return JSON.parse(safeStorage('localStorage')?.getItem(ATTEMPTS_KEY) || '{}')
  } catch {
    return {}
  }
}

function recordAttempt(email, failed) {
  const all = attempts()
  if (failed) {
    const entry = all[email] && new Date(all[email].resetAt) > new Date() ? all[email] : { count: 0, resetAt: new Date(Date.now() + LOCK_MINUTES * 60000).toISOString() }
    all[email] = { ...entry, count: entry.count + 1 }
  } else {
    delete all[email]
  }
  safeStorage('localStorage')?.setItem(ATTEMPTS_KEY, JSON.stringify(all))
}

export async function signIn({ email, password, remember }) {
  email = normaliseEmail(email)
  const lock = attempts()[email]
  if (lock && lock.count >= MAX_ATTEMPTS && new Date(lock.resetAt) > new Date()) {
    const minutes = Math.ceil((new Date(lock.resetAt) - new Date()) / 60000)
    throw new ApiError(`Too many attempts. Try again in ${minutes} ${minutes === 1 ? 'minute' : 'minutes'}, or reset your password.`, { status: 429 })
  }
  const user = await read((db) => db.users.find((u) => u.email === email))
  if (!user || !(await verifyPassword(password, user.password))) {
    recordAttempt(email, true)
    throw new ApiError('That email and password do not match a partner account.', { status: 401 })
  }
  recordAttempt(email, false)
  await transaction((db) => {
    db.users.find((u) => u.id === user.id).lastSignInAt = new Date().toISOString()
  })
  return startSession(user, remember)
}

/** The signed-in user and their business, without secrets. */
export async function getAccount() {
  const session = getSession()
  if (!session) return null
  return read((db) => {
    const user = db.users.find((u) => u.id === session.userId)
    const partner = db.partners.find((p) => p.id === user.partnerId)
    const { password: _password, ...safeUser } = user
    return { user: safeUser, partner }
  })
}

/**
 * P-01: a tour operator, guide, attraction or hotel applies to join. Creates
 * the business (pending review) and its owner account, then signs them in.
 */
export async function apply(form) {
  const email = normaliseEmail(form.email)
  const fields = {}
  if (!form.name?.trim()) fields.name = 'Enter your name.'
  if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) fields.email = 'Enter a valid email address.'
  if (!/^\+?[0-9 ]{10,16}$/.test(form.phone || '')) fields.phone = 'Enter a phone number, e.g. +234 802 123 4567.'
  const problems = passwordProblems(form.password || '')
  if (problems.length) fields.password = `Use ${problems.join(', ')}.`
  if (!form.businessName?.trim()) fields.businessName = 'Enter your business name.'
  if (!['tour_operator', 'guide', 'attraction', 'hotel'].includes(form.type)) fields.type = 'Choose what kind of partner you are.'
  if (!form.cacNumber?.trim()) fields.cacNumber = 'Enter your CAC registration number (RC or BN).'
  if (!form.documents?.cac) fields.cac = 'Upload your CAC certificate.'
  if (form.type !== 'hotel' && !form.documents?.insurance) fields.insurance = 'Upload your insurance certificate.'
  if (['tour_operator', 'guide'].includes(form.type) && !form.guides?.length) fields.guides = 'Add at least one guide.'
  if (!form.consent) fields.consent = 'You need to accept the partner terms and privacy notice.'
  if (load().users.some((u) => u.email === email)) fields.email = 'There is already a partner account with this email. Sign in instead.'
  if (Object.keys(fields).length) throw new ApiError('Please check the highlighted fields.', { fields })

  const password = await hashPassword(form.password)
  const now = new Date().toISOString()
  const user = await transaction((db) => {
    const partnerId = newId('p')
    const doc = (type, label, file, expiresOn = null) => file && { id: newId('d'), type, label, fileName: file.name, fileSize: file.size, status: 'pending', expiresOn, uploadedAt: now }
    db.partners.push({
      id: partnerId, name: form.businessName.trim(), type: form.type, status: 'pending',
      contactName: form.name.trim(), email, phone: form.phone.trim(), whatsapp: form.phone.trim(),
      cacNumber: form.cacNumber.trim().toUpperCase(), address: form.address?.trim() || '', area: form.area || '', description: form.description?.trim() || '',
      commissionRate: form.type === 'hotel' ? 0 : db.settings.commissionRate, appliedAt: now, approvedAt: null,
      bank: { name: form.bankName?.trim() || '', accountNumber: form.bankAccountNumber?.trim() || '', accountName: form.bankAccountName?.trim() || '' },
      notifications: { email: true, whatsapp: Boolean(form.whatsappUpdates), whatsappNumber: form.whatsappUpdates ? form.phone.trim() : '', newBooking: true, cancellation: true, review: true, payout: true },
      documents: [
        doc('cac', 'CAC certificate', form.documents.cac),
        doc('insurance', 'Insurance certificate', form.documents.insurance, form.insuranceExpiresOn || null),
      ].filter(Boolean),
      guides: (form.guides || []).map((g) => ({ ...g, id: newId('g') })),
      consentedAt: now,
    })
    const created = { id: newId('u'), partnerId, name: form.name.trim(), email, phone: form.phone.trim(), role: 'owner', password, createdAt: now }
    db.users.push(created)
    db.notifications.push({
      id: newId('n'), partnerId, type: 'application', title: 'Application received',
      body: 'Thanks for applying to Cabo. We review applications within 2 working days and will email you.', link: '/application',
      createdAt: now, read: false, channels: ['email'],
    })
    return created
  })
  return startSession(user, false)
}

/**
 * Starts a password reset. Always succeeds so the form does not reveal which
 * emails have accounts. Returns the code because the demo cannot send email.
 */
export async function requestPasswordReset(email) {
  email = normaliseEmail(email)
  const code = String(crypto.getRandomValues(new Uint32Array(1))[0] % 1000000).padStart(6, '0')
  const exists = await transaction((db) => {
    db.passwordResets = db.passwordResets.filter((r) => r.email !== email)
    if (!db.users.some((u) => u.email === email)) return false
    db.passwordResets.push({ email, code, expiresAt: new Date(Date.now() + RESET_CODE_MINUTES * 60000).toISOString(), attempts: 0 })
    return true
  })
  return { demoCode: exists ? code : null }
}

export async function resetPassword({ email, code, password }) {
  email = normaliseEmail(email)
  const problems = passwordProblems(password || '')
  if (problems.length) throw new ApiError('Choose a stronger password.', { fields: { password: `Use ${problems.join(', ')}.` } })
  const reset = load().passwordResets.find((r) => r.email === email)
  if (!reset || new Date(reset.expiresAt) < new Date() || reset.attempts >= 5) {
    throw new ApiError('That code has expired. Ask for a new one.', { fields: { code: 'Expired code.' } })
  }
  if (reset.code !== String(code).trim()) {
    await transaction((db) => {
      db.passwordResets.find((r) => r.email === email).attempts += 1
    })
    throw new ApiError('That code is not right.', { fields: { code: 'Check the code and try again.' } })
  }
  const hashed = await hashPassword(password)
  await transaction((db) => {
    db.users.find((u) => u.email === email).password = hashed
    db.passwordResets = db.passwordResets.filter((r) => r.email !== email)
  })
  recordAttempt(email, false)
}

export async function changePassword({ current, password }) {
  const session = getSession()
  const user = load().users.find((u) => u.id === session?.userId)
  if (!user || !(await verifyPassword(current, user.password))) {
    throw new ApiError('Your current password is not right.', { fields: { current: 'Incorrect password.' } })
  }
  const problems = passwordProblems(password || '')
  if (problems.length) throw new ApiError('Choose a stronger password.', { fields: { password: `Use ${problems.join(', ')}.` } })
  const hashed = await hashPassword(password)
  await transaction((db) => {
    db.users.find((u) => u.id === user.id).password = hashed
  })
}

/** Checks the signed-in user's password before a sensitive change. */
export async function confirmPassword(password) {
  const session = getSession()
  const user = load().users.find((u) => u.id === session?.userId)
  if (!user || !(await verifyPassword(password, user.password))) {
    throw new ApiError('Your password is not right.', { fields: { confirmPassword: 'Incorrect password.' } })
  }
}

export const DEMO_ACCOUNTS = [
  { email: 'adaeze@ekonaturetrails.ng', label: 'Tour operator', name: 'Eko Nature Trails' },
  { email: 'funmi@funmiisland.ng', label: 'Tour operator', name: 'Funmi Island Tours' },
  { email: 'kunle@badagryroots.ng', label: 'Guide, application pending', name: 'Badagry Roots Guides' },
  { email: 'ifeoma@lekkiartshub.ng', label: 'Attraction (tickets)', name: 'Lekki Arts Hub' },
  { email: 'bisi@lagoonhouse.ng', label: 'Hotel (concierge)', name: 'The Lagoon House' },
]
export const DEMO_PASSWORD = 'password123!'

