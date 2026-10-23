import { useState } from 'react'
import { Link, useSearchParams } from 'react-router-dom'
import { addSlots, availability, blockDate, bookingsOnDate, deleteSlot, listTours, unblockDate, updateSlotCapacity } from '../api/portal'
import Icon from '../components/Icon'
import { useToast } from '../components/Toasts'
import { Dialog, Empty, Field, FormMessage, Loading, LoadError, PageHead } from '../components/ui'
import { addDays, formatLongDate, formatMonth, formatTime, lagosDate, plural, weekday } from '../lib/format'
import { useAsync, useForm, useTitle } from '../lib/hooks'

const DAYS = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat']
const WEEK = [1, 2, 3, 4, 5, 6, 0] // Calendar weeks start on Monday.

function monthGrid(month) {
  const first = `${month}-01`
  const start = addDays(first, -((weekday(first) + 6) % 7))
  return Array.from({ length: 42 }, (_, i) => addDays(start, i))
}

export default function Availability() {
  useTitle('Availability')
  const toast = useToast()
  const [params, setParams] = useSearchParams()
  const tourId = params.get('tour') || ''
  const today = lagosDate()
  const [month, setMonth] = useState(today.slice(0, 7))
  const [selected, setSelected] = useState(today)
  const [adding, setAdding] = useState(false)
  const [blocking, setBlocking] = useState(false)
  const days = monthGrid(month)
  const tours = useAsync(async () => (await listTours()).filter((t) => ['live', 'paused'].includes(t.status) || t.changesInReview), [])
  const cal = useAsync(() => availability({ from: days[0], to: days[41], tourId }), [month, tourId])

  const shiftMonth = (n) => {
    const d = new Date(`${month}-15T12:00:00Z`)
    d.setUTCMonth(d.getUTCMonth() + n)
    setMonth(d.toISOString().slice(0, 7))
  }
  const tourName = (id) => tours.data?.find((t) => t.id === id)?.title || 'Tour'
  const slotsOn = (date) => cal.data?.slots.filter((s) => s.date === date) || []
  const blockOn = (date) => cal.data?.blocked.filter((b) => b.date === date) || []
  const daySlots = slotsOn(selected)

  return (
    <>
      <PageHead title="Availability" subtitle="Time slots guests can book, with capacity. Block dates when you cannot run tours.">
        <button className="btn btn-ghost" onClick={() => setBlocking(true)} disabled={!tours.data?.length}>Block a date</button>
        <button className="btn btn-primary" onClick={() => setAdding(true)} disabled={!tours.data?.length}><Icon name="plus" size={16} /> Add time slots</button>
      </PageHead>

      {tours.data && tours.data.length === 0 && (
        <div className="card"><Empty title="No live tours yet" action={<Link className="btn btn-primary" to="/tours">Go to tours</Link>}>Availability can be set once Cabo has approved a tour.</Empty></div>
      )}

      {tours.data?.length > 0 && (
        <div className="grid grid-main">
          <div className="card">
            <div className="filters">
              <button className="icon-button" onClick={() => shiftMonth(-1)} aria-label="Previous month"><Icon name="chevronLeft" /></button>
              <h2 style={{ minWidth: 170, textAlign: 'center' }} aria-live="polite">{formatMonth(`${month}-15T12:00:00Z`)}</h2>
              <button className="icon-button" onClick={() => shiftMonth(1)} aria-label="Next month"><Icon name="chevronRight" /></button>
              <button className="btn btn-ghost btn-sm" onClick={() => { setMonth(today.slice(0, 7)); setSelected(today) }}>Today</button>
              <span className="spacer" />
              <label className="visually-hidden" htmlFor="tour-filter">Tour</label>
              <select id="tour-filter" value={tourId} onChange={(e) => setParams(e.target.value ? { tour: e.target.value } : {})}>
                <option value="">All tours</option>
                {tours.data.map((t) => <option key={t.id} value={t.id}>{t.title}</option>)}
              </select>
            </div>
            <div className="card-body">
              {cal.error && <LoadError error={cal.error} retry={cal.reload} />}
              <div className="calendar" aria-label="Availability calendar" role="group">
                {WEEK.map((d) => <div className="dow" key={d} aria-hidden="true">{DAYS[d]}</div>)}
                {days.map((date) => {
                  const slots = slotsOn(date)
                  const blocks = blockOn(date)
                  const booked = slots.reduce((n, s) => n + s.booked, 0)
                  const label = `${formatLongDate(date)}: ${blocks.length ? 'blocked' : `${plural(slots.length, 'slot')}, ${plural(booked, 'guest')} booked`}`
                  return (
                    <button
                      key={date}
                      type="button"
                      aria-label={label}
                      aria-pressed={selected === date}
                      className={['cal-day', date.slice(0, 7) !== month && 'outside', date === today && 'today', selected === date && 'selected', blocks.length && 'blocked'].filter(Boolean).join(' ')}
                      onClick={() => setSelected(date)}
                    >
                      <span className="date">{Number(date.slice(8))}</span>
                      {slots.slice(0, 3).map((s) => (
                        <span key={s.id} className={`cal-slot${s.blocked ? ' off' : s.booked >= s.capacity ? ' full' : ''}`}>{formatTime(s.startsAt)} · {s.booked}/{s.capacity}</span>
                      ))}
                      {slots.length > 3 && <span className="muted small">+{slots.length - 3} more</span>}
                    </button>
                  )
                })}
              </div>
              <div className="row small muted" style={{ marginTop: 12 }}>
                <span><span className="cal-slot">09:00 · 3/10</span> booked of capacity</span>
                <span><span className="cal-slot full">Full</span></span>
                <span><span className="cal-slot off">Blocked</span></span>
              </div>
            </div>
          </div>

          <div className="card" aria-live="polite">
            <div className="card-head"><h2>{formatLongDate(selected)}</h2></div>
            <div className="card-body stack-sm">
              {cal.loading && !cal.data && <Loading />}
              {blockOn(selected).map((b) => (
                <div className="alert err" key={b.id}>
                  <p className="strong">Blocked{b.tourId ? `: ${tourName(b.tourId)}` : ' for all tours'}</p>
                  {b.reason && <p>{b.reason}</p>}
                  <button className="btn btn-ghost btn-sm" onClick={async () => { await unblockDate(b.id); cal.reload(); toast('Date unblocked.') }}>Unblock</button>
                </div>
              ))}
              {daySlots.length === 0 && !blockOn(selected).length && <p className="muted">No time slots on this day.</p>}
              {daySlots.map((s) => <SlotRow key={s.id} slot={s} tourName={tourName(s.tourId)} past={s.startsAt < new Date().toISOString()} onChange={cal.reload} />)}
              {selected >= today && !blockOn(selected).some((b) => !b.tourId) && (
                <button className="btn btn-ghost btn-sm" onClick={() => setBlocking(true)}>Block this date</button>
              )}
            </div>
          </div>
        </div>
      )}

      {adding && <AddSlotsDialog tours={tours.data} tourId={tourId} onClose={() => setAdding(false)} onDone={(r) => { setAdding(false); cal.reload(); toast(`${plural(r.added, 'slot')} added${r.skipped ? `, ${r.skipped} skipped (already there or in the past)` : ''}.`) }} />}
      {blocking && <BlockDialog tours={tours.data} tourId={tourId} date={selected >= today ? selected : today} onClose={() => setBlocking(false)} onDone={(r) => { setBlocking(false); cal.reload(); toast(r.cancelled ? `Date blocked. ${plural(r.cancelled, 'booking')} cancelled and refunded in full.` : 'Date blocked.') }} />}
    </>
  )
}

function SlotRow({ slot, tourName, past, onChange }) {
  const toast = useToast()
  const [capacity, setCapacity] = useState(slot.capacity)
  const [error, setError] = useState(null)
  const pct = Math.min(100, Math.round((slot.booked / slot.capacity) * 100))
  return (
    <div className="card card-body" style={{ padding: 14 }}>
      <div className="row between">
        <div>
          <div className="strong">{formatTime(slot.startsAt)} · {tourName}</div>
          <div className="muted small">{slot.blocked ? 'Blocked' : `${slot.booked} of ${slot.capacity} places booked`}</div>
        </div>
        {slot.booked > 0 && <Link className="small" to={`/bookings?date=${slot.date}&tour=${slot.tourId}`}>Guest list</Link>}
      </div>
      <div className="capacity-bar" style={{ margin: '8px 0' }} aria-hidden="true"><span style={{ width: `${pct}%` }} /></div>
      {!past && !slot.blocked && (
        <div className="row tight">
          <label className="small" htmlFor={`cap-${slot.id}`}>Capacity</label>
          <input id={`cap-${slot.id}`} type="number" min={Math.max(1, slot.booked)} value={capacity} onChange={(e) => setCapacity(e.target.value)} style={{ width: 80, minHeight: 36 }} />
          <button className="btn btn-ghost btn-sm" disabled={Number(capacity) === slot.capacity} onClick={async () => {
            try { await updateSlotCapacity(slot.id, Number(capacity)); setError(null); onChange(); toast('Capacity updated.') } catch (e) { setError(e.message) }
          }}>Save</button>
          {slot.booked === 0 && <button className="btn btn-danger btn-sm" onClick={async () => {
            try { await deleteSlot(slot.id); onChange(); toast('Slot removed.') } catch (e) { setError(e.message) }
          }}>Remove</button>}
        </div>
      )}
      {error && <div className="error" role="alert">{error}</div>}
    </div>
  )
}

function AddSlotsDialog({ tours, tourId, onClose, onDone }) {
  const today = lagosDate()
  const initialTour = tours.find((t) => t.id === tourId) || tours[0]
  const form = useForm({
    tourId: initialTour.id, from: today, to: addDays(today, 27),
    days: initialTour.schedule?.days?.length ? initialTour.schedule.days : [0, 1, 2, 3, 4, 5, 6],
    times: initialTour.schedule?.times?.length ? initialTour.schedule.times : ['09:00'],
    capacity: initialTour.schedule?.capacity || initialTour.maxGroup,
  })
  const v = form.values
  const submit = async () => {
    try { onDone(await form.submit((x) => addSlots({ ...x, capacity: Number(x.capacity) }))) } catch { /* shown */ }
  }
  return (
    <Dialog open onClose={onClose} title="Add time slots" footer={<><button className="btn btn-ghost" onClick={onClose}>Cancel</button><button className="btn btn-primary" onClick={submit} disabled={form.busy}>Add slots</button></>}>
      <FormMessage message={form.message} />
      <Field label="Tour" name="tourId" error={form.errors.tourId}>
        <select {...form.bind('tourId')} onChange={(e) => {
          const t = tours.find((x) => x.id === e.target.value)
          form.setValues((x) => ({ ...x, tourId: t.id, capacity: t.schedule?.capacity || t.maxGroup }))
        }}>{tours.map((t) => <option key={t.id} value={t.id}>{t.title}</option>)}</select>
      </Field>
      <div className="form-grid">
        <Field label="From" name="from"><input type="date" min={today} {...form.bind('from')} /></Field>
        <Field label="To" name="to" error={form.errors.to}><input type="date" min={v.from} {...form.bind('to')} /></Field>
      </div>
      <div className="field">
        <span className="label" id="days-label">On these days</span>
        <div className="choices" role="group" aria-labelledby="days-label">
          {WEEK.map((d) => <label className="chip" key={d}><input type="checkbox" checked={v.days.includes(d)} onChange={(e) => form.set('days', e.target.checked ? [...v.days, d] : v.days.filter((x) => x !== d))} /> {DAYS[d]}</label>)}
        </div>
        {form.errors.days && <div className="error">{form.errors.days}</div>}
      </div>
      <div className="field">
        <span className="label" id="times-label">Start times (Lagos time)</span>
        <div className="stack-sm" role="group" aria-labelledby="times-label">
          {v.times.map((t, i) => (
            <div className="row tight" key={i}>
              <input type="time" value={t} aria-label={`Start time ${i + 1}`} onChange={(e) => form.set('times', v.times.map((x, j) => (j === i ? e.target.value : x)))} style={{ width: 140 }} />
              {v.times.length > 1 && <button type="button" className="icon-button" aria-label={`Remove ${t}`} onClick={() => form.set('times', v.times.filter((_, j) => j !== i))}><Icon name="x" /></button>}
            </div>
          ))}
          <button type="button" className="btn btn-ghost btn-sm" onClick={() => form.set('times', [...v.times, '14:00'])}><Icon name="plus" size={16} /> Add a time</button>
        </div>
        {form.errors.times && <div className="error">{form.errors.times}</div>}
      </div>
      <Field label="Places per slot" name="capacity" error={form.errors.capacity}><input type="number" min="1" {...form.bind('capacity')} style={{ maxWidth: 120 }} /></Field>
    </Dialog>
  )
}

function BlockDialog({ tours, tourId, date, onClose, onDone }) {
  const form = useForm({ date, tourId, reason: '' })
  const affected = useAsync(() => bookingsOnDate({ date: form.values.date, tourId: form.values.tourId }), [form.values.date, form.values.tourId])
  const guests = affected.data?.reduce((n, b) => n + b.guests, 0) || 0
  const submit = async () => {
    try { onDone(await form.submit(blockDate)) } catch { /* shown */ }
  }
  return (
    <Dialog open onClose={onClose} title="Block a date" footer={<><button className="btn btn-ghost" onClick={onClose}>Cancel</button><button className={`btn ${affected.data?.length ? 'btn-danger' : 'btn-primary'}`} onClick={submit} disabled={form.busy}>{affected.data?.length ? `Block and cancel ${plural(affected.data.length, 'booking')}` : 'Block date'}</button></>}>
      <FormMessage message={form.message} />
      <div className="form-grid">
        <Field label="Date" name="date" error={form.errors.date}><input type="date" min={lagosDate()} {...form.bind('date')} /></Field>
        <Field label="Tours" name="tourId">
          <select {...form.bind('tourId')}><option value="">All tours</option>{tours.map((t) => <option key={t.id} value={t.id}>{t.title}</option>)}</select>
        </Field>
      </div>
      <Field label="Reason" name="reason" optional hint="Shown to guests whose bookings are cancelled."><input type="text" placeholder="e.g. Public holiday, bad weather" {...form.bind('reason')} /></Field>
      {affected.data?.length > 0 && (
        <div className="alert warn">
          <p className="strong">{plural(affected.data.length, 'booking')} ({plural(guests, 'guest')}) on this date will be cancelled.</p>
          <p className="small">Cabo refunds them in full and tells them by email and in the app.</p>
          <ul className="small" style={{ margin: 0, paddingLeft: 18 }}>{affected.data.map((b) => <li key={b.id}>{b.guestName} · {b.tour.title} · {b.guests}</li>)}</ul>
        </div>
      )}
    </Dialog>
  )
}
