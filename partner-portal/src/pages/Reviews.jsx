import { useState } from 'react'
import { deleteReply, listReviews, replyToReview } from '../api/portal'
import { useToast } from '../components/Toasts'
import { Empty, Loading, LoadError, PageHead, Stars } from '../components/ui'
import { formatDate, plural } from '../lib/format'
import { useAsync, useTitle } from '../lib/hooks'

/** P-07: partners reply to reviews. Replies appear under the review in the app. */
export default function Reviews() {
  useTitle('Reviews')
  const { data, loading, error, reload } = useAsync(listReviews, [])
  const [filter, setFilter] = useState('all')
  const [tourId, setTourId] = useState('')
  if (error) return <LoadError error={error} retry={reload} />
  if (loading && !data) return <Loading />

  const tours = [...new Map(data.map((r) => [r.tourId, r.tour])).values()]
  const shown = data.filter((r) => (filter === 'unanswered' ? !r.reply : filter === 'low' ? r.rating <= 3 : true) && (!tourId || r.tourId === tourId))
  const avg = data.length ? data.reduce((n, r) => n + r.rating, 0) / data.length : 0
  const counts = [5, 4, 3, 2, 1].map((s) => [s, data.filter((r) => r.rating === s).length])

  return (
    <>
      <PageHead title="Reviews" subtitle="Guests can review a tour only after they have checked in. Your reply is shown under their review in the Cabo app." />
      <div className="grid grid-main">
        <div className="card">
          <div className="filters">
            <nav className="tabs" aria-label="Filter reviews">
              {[['all', 'All'], ['unanswered', `Not replied (${data.filter((r) => !r.reply).length})`], ['low', '3 stars or fewer']].map(([v, l]) => (
                <button key={v} type="button" aria-selected={filter === v} onClick={() => setFilter(v)}>{l}</button>
              ))}
            </nav>
            <label className="visually-hidden" htmlFor="tour">Tour</label>
            <select id="tour" value={tourId} onChange={(e) => setTourId(e.target.value)}>
              <option value="">All tours</option>
              {tours.map((t) => <option key={t.id} value={t.id}>{t.title}</option>)}
            </select>
          </div>
          {shown.length === 0 ? <Empty>No reviews here.</Empty> : shown.map((r) => <Review key={r.id} review={r} onChange={reload} />)}
        </div>
        <div className="card card-body" style={{ alignSelf: 'start' }}>
          <div className="kpi" style={{ padding: 0 }}>
            <div className="label">Average rating</div>
            <div className="value">{avg ? avg.toFixed(1) : '—'} {avg > 0 && <Stars value={avg} />}</div>
            <div className="hint">{plural(data.length, 'review')}</div>
          </div>
          <div style={{ marginTop: 14 }}>
            {counts.map(([stars, n]) => (
              <div className="row tight small" key={stars} style={{ marginBottom: 6 }}>
                <span style={{ width: 52 }}>{stars} stars</span>
                <div className="capacity-bar" style={{ flex: 1 }} aria-hidden="true"><span style={{ width: `${data.length ? (n / data.length) * 100 : 0}%` }} /></div>
                <span style={{ width: 24 }} className="right">{n}</span>
              </div>
            ))}
          </div>
          <p className="hint" style={{ marginTop: 12 }}>Tip: thank guests by name, and for lower ratings say what you have changed. Do not share guests' personal details in replies.</p>
        </div>
      </div>
    </>
  )
}

function Review({ review: r, onChange }) {
  const toast = useToast()
  const [editing, setEditing] = useState(false)
  const [text, setText] = useState(r.reply?.text || '')
  const [error, setError] = useState(null)
  const [busy, setBusy] = useState(false)
  async function save() {
    setBusy(true)
    try {
      await replyToReview(r.id, text)
      setEditing(false)
      setError(null)
      toast('Reply posted.')
      onChange()
    } catch (e) {
      setError(e.message)
    } finally {
      setBusy(false)
    }
  }
  return (
    <article className="review" aria-labelledby={`review-${r.id}`}>
      <div className="row between">
        <div><Stars value={r.rating} /> <span className="strong" id={`review-${r.id}`}>{r.guestName}</span> <span className="muted small">· {r.guestCountry}</span></div>
        <span className="muted small">{formatDate(r.createdAt)} · {r.tour.title}</span>
      </div>
      <p style={{ marginTop: 6 }}>{r.comment}</p>
      {r.reply && !editing && (
        <div className="reply">
          <div className="small strong">Your reply · {formatDate(r.reply.at)}</div>
          <p>{r.reply.text}</p>
          <div className="row tight">
            <button className="btn-link small" onClick={() => { setText(r.reply.text); setEditing(true) }}>Edit</button>
            <button className="btn-link small" onClick={async () => { await deleteReply(r.id); toast('Reply removed.'); onChange() }}>Remove</button>
          </div>
        </div>
      )}
      {!r.reply && !editing && <button className="btn btn-ghost btn-sm" onClick={() => setEditing(true)}>Reply</button>}
      {editing && (
        <div className="stack-sm" style={{ marginTop: 8 }}>
          <label className="visually-hidden" htmlFor={`reply-${r.id}`}>Reply to {r.guestName}</label>
          <textarea id={`reply-${r.id}`} value={text} onChange={(e) => setText(e.target.value)} maxLength={1000} placeholder={`Thank ${r.guestName.split(' ')[0]} for their review…`} aria-invalid={error ? true : undefined} />
          {error && <div className="error" role="alert">{error}</div>}
          <div className="row tight">
            <button className="btn btn-primary btn-sm" onClick={save} disabled={busy}>Post reply</button>
            <button className="btn btn-ghost btn-sm" onClick={() => { setEditing(false); setError(null) }}>Cancel</button>
            <span className="muted small">{text.length}/1000</span>
          </div>
        </div>
      )}
    </article>
  )
}
