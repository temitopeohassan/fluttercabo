import { useState } from 'react'
import { useSearchParams } from 'react-router-dom'
import { bookConcierge, cancelConcierge, DESTINATIONS, estimateConcierge, listConcierge, RIDE_TYPES } from '../api/portal'
import { useAuth } from '../auth/AuthContext'
import Icon from '../components/Icon'
import { useToast } from '../components/Toasts'
import { Empty, Field, FormMessage, Loading, PageHead, Status } from '../components/ui'
import { addDays, formatDateTime, humanize, lagosDate, maskPhone, naira } from '../lib/format'
import { useAsync, useForm, useTitle } from '../lib/hooks'

const TYPES = [
  { value: 'ride', label: 'Ride', icon: 'car', text: 'From the hotel to anywhere in the pilot area' },
  { value: 'airport_pickup', label: 'Airport pickup', icon: 'plane', text: 'Meet the guest at arrivals with a name board' },
  { value: 'airport_dropoff', label: 'Airport drop-off', icon: 'plane', text: 'From the hotel to departures' },
]

function nextQuarterHour() {
  const d = new Date(Date.now() + 45 * 60000)
  const parts = new Intl.DateTimeFormat('en-GB', { timeZone: 'Africa/Lagos', hour: '2-digit', minute: '2-digit', hour12: false }).formatToParts(d)
  const h = parts.find((p) => p.type === 'hour').value
  const m = Math.ceil(Number(parts.find((p) => p.type === 'minute').value) / 15) * 15
  return m === 60 ? `${String((Number(h) + 1) % 24).padStart(2, '0')}:00` : `${h}:${String(m).padStart(2, '0')}`
}

/** P-09: a concierge view for hotels to book rides and airport pickups for guests. */
export default function Concierge() {
  useTitle('Concierge')
  const toast = useToast()
  const { partner } = useAuth().account
  const [params] = useSearchParams()
  const list = useAsync(listConcierge, [])
  const [view, setView] = useState('upcoming')
  const form = useForm({
    type: params.get('new') && TYPES.some((t) => t.value === params.get('new')) ? params.get('new') : 'ride',
    guestName: '', guestPhone: '', room: '', pickupDate: lagosDate(), pickupTime: nextQuarterHour(), destination: '', flightNumber: '',
    rideType: 'comfort', passengers: 1, billTo: 'hotel_account', notes: '',
  })
  const v = form.values
  const estimate = estimateConcierge(v, partner)
  const now = new Date().toISOString()
  const bookings = (list.data || []).filter((c) => (view === 'upcoming' ? c.pickupAt >= now && !['completed', 'cancelled'].includes(c.status) : c.pickupAt < now || ['completed', 'cancelled'].includes(c.status)))
  if (view === 'upcoming') bookings.reverse()
  const month = lagosDate().slice(0, 7)
  const billed = (list.data || []).filter((c) => c.billTo === 'hotel_account' && c.status !== 'cancelled' && lagosDate(c.pickupAt).slice(0, 7) === month)

  async function submit(e) {
    e.preventDefault()
    try {
      const b = await form.submit(bookConcierge)
      toast(`Booked ${b.reference}. We will text ${b.guestName.split(' ')[0]} the driver's details.`)
      form.setValues((x) => ({ ...x, guestName: '', guestPhone: '', room: '', flightNumber: '', notes: '' }))
      list.reload()
      setView('upcoming')
    } catch {
      // Shown in the form.
    }
  }

  return (
    <>
      <PageHead title="Concierge" subtitle={`Book Cabo rides and airport transfers for guests of ${partner.name}. Guests get the driver's details by SMS and WhatsApp.`} />
      <div className="grid grid-2">
        <form className="card" onSubmit={submit} noValidate aria-labelledby="new-booking">
          <div className="card-head"><h2 id="new-booking">New booking</h2></div>
          <div className="card-body">
            <FormMessage message={form.message} />
            <div className="stack-sm field" role="radiogroup" aria-label="Type of trip">
              {TYPES.map((t) => (
                <label className="option-card" key={t.value}>
                  <input type="radio" name="type" checked={v.type === t.value} onChange={() => form.set('type', t.value)} />
                  <span><span className="strong"><Icon name={t.icon} size={16} /> {t.label}</span><br /><span className="muted small">{t.text}</span></span>
                </label>
              ))}
            </div>
            <div className="form-grid">
              <Field label="Guest name" name="guestName" error={form.errors.guestName}><input type="text" {...form.bind('guestName')} /></Field>
              <Field label="Room" name="room" optional><input type="text" {...form.bind('room')} /></Field>
              <div className="full"><Field label="Guest's mobile number" name="guestPhone" error={form.errors.guestPhone} hint="Include the country code. The driver contacts the guest on this number."><input type="tel" placeholder="+44 7700 900123" {...form.bind('guestPhone')} /></Field></div>
              {v.type === 'ride' ? (
                <div className="full">
                  <Field label="Going to" name="destination" error={form.errors.destination}>
                    <select {...form.bind('destination')}><option value="">Choose…</option>{DESTINATIONS.map((d) => <option key={d.name}>{d.name}</option>)}</select>
                  </Field>
                </div>
              ) : (
                <div className="full">
                  <Field label="Flight number" name="flightNumber" error={form.errors.flightNumber} hint={v.type === 'airport_pickup' ? 'We track the flight. The driver waits up to 60 minutes after landing at no charge.' : 'Pick up at least 3 hours before an international departure.'}>
                    <input type="text" placeholder="e.g. BA75" autoCapitalize="characters" {...form.bind('flightNumber')} />
                  </Field>
                </div>
              )}
              <Field label={v.type === 'airport_pickup' ? 'Flight lands (date)' : 'Pickup date'} name="pickupDate"><input type="date" min={lagosDate()} max={addDays(lagosDate(), 60)} {...form.bind('pickupDate')} /></Field>
              <Field label={v.type === 'airport_pickup' ? 'Lands at (Lagos time)' : 'Pickup time (Lagos time)'} name="pickupTime" error={form.errors.pickupTime}><input type="time" {...form.bind('pickupTime')} /></Field>
              <Field label="Car" name="rideType" error={form.errors.rideType}>
                <select {...form.bind('rideType')}>{RIDE_TYPES.map((r) => <option key={r.code} value={r.code}>{r.name} · up to {r.seats}</option>)}</select>
              </Field>
              <Field label="Passengers" name="passengers"><input type="number" min="1" max="6" {...form.bind('passengers')} /></Field>
              <div className="full field">
                <span className="label" id="bill-label">Who pays</span>
                <div className="choices" role="radiogroup" aria-labelledby="bill-label">
                  <label className="chip"><input type="radio" name="billTo" checked={v.billTo === 'hotel_account'} onChange={() => form.set('billTo', 'hotel_account')} /> Hotel account (monthly invoice)</label>
                  <label className="chip"><input type="radio" name="billTo" checked={v.billTo === 'guest'} onChange={() => form.set('billTo', 'guest')} /> Guest pays in the Cabo app</label>
                </div>
              </div>
              <div className="full"><Field label="Note for the driver" name="notes" optional><input type="text" placeholder="e.g. Two large suitcases" {...form.bind('notes')} /></Field></div>
            </div>
          </div>
          <div className="card-foot row between">
            <div>
              <div className="muted small">{estimate?.fixed ? 'Fixed airport price' : 'Estimated fare'}</div>
              <div className="strong" style={{ fontSize: 22 }}>{estimate ? naira(estimate.price) : '—'}</div>
              {estimate && !estimate.fixed && <div className="muted small">{estimate.km} km · about {estimate.minutes} min. Final fare can change with stops or traffic surge.</div>}
            </div>
            <button className="btn btn-primary" disabled={form.busy}>{form.busy ? 'Booking…' : 'Book'}</button>
          </div>
        </form>

        <div className="stack">
          <div className="grid grid-2">
            <div className="card kpi"><div className="label">Billed to you this month</div><div className="value">{naira(billed.reduce((n, c) => n + c.price, 0))}</div><div className="hint">{billed.length} trips · invoiced on the 1st</div></div>
            <div className="card kpi"><div className="label">Upcoming</div><div className="value">{(list.data || []).filter((c) => c.pickupAt >= now && !['completed', 'cancelled'].includes(c.status)).length}</div><div className="hint">Rides and transfers</div></div>
          </div>
          <div className="card">
            <div className="filters">
              <nav className="tabs" aria-label="Bookings to show">
                <button type="button" aria-selected={view === 'upcoming'} onClick={() => setView('upcoming')}>Upcoming</button>
                <button type="button" aria-selected={view === 'past'} onClick={() => setView('past')}>Past</button>
              </nav>
            </div>
            {list.loading && !list.data && <Loading />}
            {list.data && bookings.length === 0 && <Empty>No {view} bookings.</Empty>}
            {bookings.map((c) => (
              <div className="list-item" key={c.id} style={{ alignItems: 'flex-start' }}>
                <div style={{ minWidth: 0 }}>
                  <div className="strong">{c.guestName}{c.room ? ` · Room ${c.room}` : ''}</div>
                  <div className="small">{humanize(c.type)}{c.flightNumber ? ` · ${c.flightNumber}` : ''} · {formatDateTime(c.pickupAt)}</div>
                  <div className="muted small">{c.from} → {c.to}</div>
                  <div className="muted small">{maskPhone(c.guestPhone)} · {RIDE_TYPES.find((r) => r.code === c.rideType)?.name} · {naira(c.price)} · {c.billTo === 'guest' ? 'guest pays' : 'hotel account'}</div>
                  {c.driver && <div className="small">Driver: {c.driver.name}, {c.driver.vehicle} <span className="mono">{c.driver.plate}</span></div>}
                </div>
                <div className="end stack-sm">
                  <Status value={c.status} />
                  {['requested', 'driver_assigned'].includes(c.status) && c.pickupAt > now && (
                    <button className="btn btn-danger btn-sm" onClick={async () => { await cancelConcierge(c.id); list.reload(); toast('Booking cancelled.') }}>Cancel</button>
                  )}
                </div>
              </div>
            ))}
          </div>
        </div>
      </div>
    </>
  )
}
