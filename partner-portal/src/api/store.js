// The portal's data lives in src/data/db.json. On first load it is copied
// into localStorage so changes survive a reload; resetDemoData() restores it.
// Replace this module and api/*.js with calls to the Cabo backend later.

let seed = null
let KEY = null

/** Loads db.json (a separate download) before the app first renders. */
export async function initStore() {
  if (seed) return
  seed = (await import('../data/db.json')).default
  // A new db.json (new version or regenerated) replaces data saved from the old one.
  KEY = `cabo-partner-portal:db:v${seed.version}:${seed.generatedOn}`
}

const DATE_ONLY = /^\d{4}-\d{2}-\d{2}$/
const INSTANT = /^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(\.\d+)?Z$/

let memory = null

/** Fired on window after every save, so counters such as unread notifications refresh. */
export const CHANGE_EVENT = 'cabo:data-changed'

function storage() {
  try {
    const s = window.localStorage
    s.setItem('cabo-test', '1')
    s.removeItem('cabo-test')
    return s
  } catch {
    return null
  }
}

/** Moves every date in the seed forward so the demo stays current. */
function shiftDates(value, days) {
  if (Array.isArray(value)) return value.map((v) => shiftDates(v, days))
  if (value && typeof value === 'object') {
    return Object.fromEntries(Object.entries(value).map(([k, v]) => [k, k === 'generatedOn' ? v : shiftDates(v, days)]))
  }
  if (typeof value === 'string' && (INSTANT.test(value) || DATE_ONLY.test(value))) {
    const d = new Date(DATE_ONLY.test(value) ? `${value}T12:00:00Z` : value)
    d.setUTCDate(d.getUTCDate() + days)
    return DATE_ONLY.test(value) ? d.toISOString().slice(0, 10) : d.toISOString()
  }
  return value
}

/** Platform settings from db.json: categories, languages, cancellation policies, commission. */
export const settings = () => load().settings

export function freshData() {
  const generated = new Date(`${seed.generatedOn}T00:00:00Z`)
  const today = new Date()
  today.setUTCHours(0, 0, 0, 0)
  const days = Math.round((today - generated) / 86400000)
  const data = shiftDates(structuredClone(seed), days)
  data.loadedOn = today.toISOString().slice(0, 10)
  return data
}

export function load() {
  if (memory) return memory
  if (!seed) throw new Error('Call initStore() before using the data.')
  const s = storage()
  const saved = s?.getItem(KEY)
  memory = saved ? JSON.parse(saved) : freshData()
  return memory
}

export function save(data) {
  memory = data
  try {
    storage()?.setItem(KEY, JSON.stringify(data))
    window.dispatchEvent(new Event(CHANGE_EVENT))
  } catch (error) {
    // Most likely the browser's storage quota (photos are the big items).
    throw new ApiError('Your browser ran out of storage for the demo data. Remove some photos or reset the demo data in Settings.', { cause: error })
  }
}

export function resetDemoData() {
  memory = freshData()
  storage()?.removeItem(KEY)
  save(memory)
}

/** Read-modify-write. The callback mutates the data and may return a result. */
export async function transaction(fn) {
  await latency()
  const data = structuredClone(load())
  const result = await fn(data)
  save(data)
  return result
}

export async function read(fn) {
  await latency()
  return structuredClone(fn(load()))
}

// A short pause so loading states are visible, as they will be with a real API.
const latency = () => new Promise((resolve) => setTimeout(resolve, import.meta.env.MODE === 'test' ? 0 : 120))

export class ApiError extends Error {
  constructor(message, { fields, status, cause } = {}) {
    super(message, { cause })
    this.fields = fields || {}
    this.status = status || 422
  }
}

let counter = 0
export const newId = (prefix) => `${prefix}${Date.now().toString(36)}${(counter++).toString(36)}`

export function reference(prefix) {
  const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'
  const random = crypto.getRandomValues(new Uint8Array(6))
  return `${prefix}-${[...random].map((n) => chars[n % chars.length]).join('')}`
}

export function token(length = 24) {
  const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'
  return [...crypto.getRandomValues(new Uint8Array(length))].map((n) => chars[n % chars.length]).join('')
}
