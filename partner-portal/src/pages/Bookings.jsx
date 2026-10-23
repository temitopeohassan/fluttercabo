import { Link, useSearchParams } from 'react-router-dom'
import { listBookings, listTours, toCsv } from '../api/portal'
import Icon from '../components/Icon'
import { Empty, Loading, LoadError, PageHead, Status } from '../components/ui'
import { formatDate, formatDay, formatTime, lagosDate, naira } from '../lib/format'
import { download, useAsync, useTitle } from '../lib/hooks'

const VIEWS = [['upcoming', 'Upcoming'], ['past', 'Past'], ['cancelled', 'Cancelled'], ['all', 'All']]

export default function Bookings() {
  useTitle('Bookings')
  const [params, setParams] = useSearchParams()
  const date = params.get('date') || ''
  const view = params.get('view') || (date ? 'all' : 'upcoming')
  const tourId = params.get('tour') || ''
  const q = params.get('q') || ''
  const tours = useAsync(listTours, [])
  const { data, loading, error, reload } = useAsync(() => listBookings({ view, tourId, q, date }), [view, tourId, q, date])
  const update = (changes) => {
    const next = Object.fromEntries(Object.entries({ view, tour: tourId, q, date, ...changes }).filter(([, val]) => val))
    setParams(next)
  }

  function exportCsv() {
    const csv = toCsv(data, [
      { label: 'Reference', value: 'reference' },
      { label: 'Date', value: (b) => lagosDate(b.slot.startsAt) },
      { label: 'Time', value: (b) => formatTime(b.slot.startsAt) },
      { label: 'Tour', value: (b) => b.tour.title },
      { label: 'Guest', value: 'guestName' },
      { label: 'Country', value: 'guestCountry' },
      { label: 'Guests', value: 'guests' },
      { label: 'Add-ons', value: (b) => b.addons.map((a) => a.name).join('; ') },
      { label: 'Special requests', value: 'specialRequests' },
      { label: 'Status', value: 'status' },
      { label: 'You receive (NGN)', value: 'net' },
    ])
    download(`cabo-bookings-${view}${date ? `-${date}` : ''}.csv`, csv)
  }

  const guests = data?.filter((b) => b.status !== 'cancelled').reduce((n, b) => n + b.guests, 0) || 0

  return (
    <>
      <PageHead title="Bookings" subtitle="Every booking made through Cabo. New bookings also reach you by email and WhatsApp (see Settings).">
        <button className="btn btn-ghost" onClick={exportCsv} disabled={!data?.length}><Icon name="download" size={16} /> Export guest list</button>
      </PageHead>
      <div className="card">
        <div className="filters">
          <nav className="tabs" aria-label="Bookings to show">
            {VIEWS.map(([value, label]) => (
              <button key={value} type="button" aria-selected={view === value} onClick={() => update({ view: value })}>{label}</button>
            ))}
          </nav>
          <form className="row" style={{ flex: 1 }} role="search" onSubmit={(e) => { e.preventDefault(); update({ q: new FormData(e.currentTarget).get('q') }) }}>
            <label className="visually-hidden" htmlFor="q">Search by guest name or reference</label>
            <input id="q" name="q" type="search" placeholder="Guest name or reference" defaultValue={q} />
          </form>
          <label className="visually-hidden" htmlFor="tour">Tour</label>
          <select id="tour" value={tourId} onChange={(e) => update({ tour: e.target.value })}>
            <option value="">All tours</option>
            {tours.data?.map((t) => <option key={t.id} value={t.id}>{t.title}</option>)}
          </select>
          <label className="visually-hidden" htmlFor="date">Date</label>
          <input id="date" type="date" value={date} onChange={(e) => update({ date: e.target.value, view: e.target.value ? 'all' : 'upcoming' })} />
          {(date || tourId || q) && <button className="btn-link" type="button" onClick={() => setParams({ view })}>Clear filters</button>}
        </div>
        {loading && !data && <Loading />}
        {error && <div className="card-body"><LoadError error={error} retry={reload} /></div>}
        {data && data.length === 0 && <Empty title="No bookings">{view === 'upcoming' ? 'New bookings will appear here as soon as guests book.' : 'Nothing matches these filters.'}</Empty>}
        {data && data.length > 0 && (
          <>
            <div className="table-wrap"><table>
              <thead><tr><th>When</th><th>Guest</th><th>Tour</th><th className="right">Guests</th><th>Extras</th><th className="right">You receive</th><th>Status</th></tr></thead>
              <tbody>
                {data.map((b) => (
                  <tr key={b.id}>
                    <td className="nowrap">{formatDay(b.slot.startsAt)}<div className="muted small">{formatTime(b.slot.startsAt)} · {new Date(b.slot.startsAt).getUTCFullYear()}</div></td>
                    <td><Link className="strong" to={`/bookings/${b.id}`}>{b.guestName}</Link><div className="muted small"><span className="mono">{b.reference}</span> · {b.guestCountry}</div></td>
                    <td>{b.tour.title}</td>
                    <td className="right">{b.guests}</td>
                    <td className="small">
                      {b.addons.map((a) => <div key={a.name}>{a.name}</div>)}
                      {b.rideAddon && <div className="muted">Cabo ride to meeting point</div>}
                      {b.specialRequests && <div><span className="badge yellow plain">Request</span></div>}
                    </td>
                    <td className="right nowrap">{naira(b.net)}</td>
                    <td><Status value={b.status} /></td>
                  </tr>
                ))}
              </tbody>
            </table></div>
            <div className="card-foot small muted">{data.length} bookings · {guests} guests{date ? ` on ${formatDate(date)}` : ''}</div>
          </>
        )}
      </div>
    </>
  )
}
