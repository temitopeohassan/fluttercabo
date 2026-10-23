// Formatting helpers. Lagos is UTC+1 all year, and every time in the portal
// is shown in Lagos time whatever the browser's time zone.
export const TIME_ZONE = 'Africa/Lagos'
const LOCALE = 'en-GB'

const nairaFormat = new Intl.NumberFormat('en-NG', { style: 'currency', currency: 'NGN', maximumFractionDigits: 0 })

export const naira = (amount) => nairaFormat.format(Math.round(amount || 0))

const fmt = (options) => new Intl.DateTimeFormat(LOCALE, { timeZone: TIME_ZONE, ...options })
const dayMonth = fmt({ weekday: 'short', day: 'numeric', month: 'short' })
const fullDate = fmt({ day: 'numeric', month: 'short', year: 'numeric' })
const longDate = fmt({ weekday: 'long', day: 'numeric', month: 'long', year: 'numeric' })
const time = fmt({ hour: '2-digit', minute: '2-digit', hour12: false })
const monthYear = fmt({ month: 'long', year: 'numeric' })

export const formatDay = (iso) => dayMonth.format(new Date(iso))
export const formatDate = (iso) => (iso ? fullDate.format(new Date(iso.length === 10 ? `${iso}T12:00:00Z` : iso)) : '—')
export const formatLongDate = (iso) => longDate.format(new Date(iso.length === 10 ? `${iso}T12:00:00Z` : iso))
export const formatTime = (iso) => time.format(new Date(iso))
export const formatDateTime = (iso) => `${formatDay(iso)}, ${formatTime(iso)}`
export const formatMonth = (iso) => monthYear.format(new Date(iso))

/** YYYY-MM-DD of an instant in Lagos time. */
const isoDay = new Intl.DateTimeFormat('en-CA', { timeZone: TIME_ZONE, year: 'numeric', month: '2-digit', day: '2-digit' })

export function lagosDate(value = new Date()) {
  const parts = isoDay.formatToParts(new Date(value))
  const get = (type) => parts.find((p) => p.type === type).value
  return `${get('year')}-${get('month')}-${get('day')}`
}

/** ISO instant for a Lagos date (YYYY-MM-DD) and time (HH:MM). */
export const lagosInstant = (date, hhmm) => new Date(`${date}T${hhmm}:00+01:00`).toISOString()

export function addDays(date, days) {
  const d = new Date(`${date}T12:00:00Z`)
  d.setUTCDate(d.getUTCDate() + days)
  return d.toISOString().slice(0, 10)
}

export const weekday = (date) => new Date(`${date}T12:00:00Z`).getUTCDay()

export function relativeTime(iso) {
  const seconds = Math.round((Date.now() - new Date(iso)) / 1000)
  if (seconds < 60) return 'just now'
  const minutes = Math.round(seconds / 60)
  if (minutes < 60) return `${minutes} min ago`
  const hours = Math.round(minutes / 60)
  if (hours < 24) return `${hours} h ago`
  const days = Math.round(hours / 24)
  return days < 30 ? `${days} ${days === 1 ? 'day' : 'days'} ago` : formatDate(iso)
}

export const humanize = (value) => (value ? value.charAt(0).toUpperCase() + value.slice(1).replace(/_/g, ' ') : '')

export const plural = (n, word, many = `${word}s`) => `${n} ${n === 1 ? word : many}`

export function duration(minutes) {
  const h = Math.floor(minutes / 60)
  const m = minutes % 60
  return [h && `${h} h`, m && `${m} min`].filter(Boolean).join(' ')
}

/** +2348021234501 → +234 ••• 4501. The PRD asks for phone numbers to be masked. */
export function maskPhone(phone) {
  if (!phone || phone.length < 8) return phone
  return `${phone.slice(0, 4)} ••• ${phone.slice(-4)}`
}
