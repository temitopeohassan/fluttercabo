import { Link } from 'react-router-dom'
import { dashboard } from '../api/portal'
import { useAuth } from '../auth/AuthContext'
import { Empty, Loading, LoadError, Stars, Status } from '../components/ui'
import { formatDate, formatDay, formatLongDate, formatTime, lagosDate, naira, plural } from '../lib/format'
import { useAsync, useTitle } from '../lib/hooks'

function greeting() {
  const hour = Number(new Intl.DateTimeFormat('en-GB', { hour: 'numeric', hour12: false, timeZone: 'Africa/Lagos' }).format(new Date()))
  return hour < 12 ? 'Good morning' : hour < 17 ? 'Good afternoon' : 'Good evening'
}

export default function Dashboard() {
  useTitle('Dashboard')
  const { user, partner } = useAuth().account
  const { data, loading, error, reload } = useAsync(dashboard, [])
  const tours = ['tour_operator', 'guide'].includes(partner.type)

  return (
    <>
      <div className="page-head">
        <div>
          <h1>{greeting()}, {user.name.split(' ')[0]}</h1>
          <p>{formatLongDate(lagosDate())} · {partner.name}</p>
        </div>
        {tours && <Link className="btn btn-yellow" to="/check-in">Check guests in</Link>}
        {partner.type === 'attraction' && <Link className="btn btn-yellow" to="/check-in">Scan tickets</Link>}
        {partner.type === 'hotel' && <Link className="btn btn-yellow" to="/concierge?new=ride">Book a ride for a guest</Link>}
      </div>

      {loading && !data && <Loading />}
      {error && <LoadError error={error} retry={reload} />}
      {data && (
        <div className="stack">
          {data.expiringDocuments.map((d) => (
            <div className="alert warn" key={d.id}>
              <strong>{d.label}</strong> expires on {formatDate(d.expiresOn)}. <Link to="/settings/documents">Upload the renewed certificate</Link> so your listings stay live.
            </div>
          ))}
          {data.listings.changesRequested > 0 && (
            <div className="alert info">Cabo asked for changes to {plural(data.listings.changesRequested, 'tour')}. <Link to="/tours">See what to fix</Link>.</div>
          )}

          {tours && <TourStats data={data} />}
          {partner.type === 'attraction' && (
            <div className="grid grid-3">
              <div className="card kpi accent"><div className="label">This month's ticket sales</div><div className="value">{naira(data.stats.netThisMonth)}</div><div className="hint">What you receive after commission</div></div>
              <div className="card kpi"><div className="label">Tickets for today</div><div className="value">{data.stats.ticketsToday}</div><div className="hint">{data.stats.ticketsUsedToday} already scanned</div></div>
              <div className="card kpi"><div className="label">Tickets</div><div className="value"><Link to="/tickets">Manage</Link></div><div className="hint">Prices, daily limits and sales</div></div>
            </div>
          )}
          {partner.type === 'hotel' && (
            <div className="grid grid-3">
              <div className="card kpi accent"><div className="label">Upcoming guest rides</div><div className="value">{data.stats.conciergeUpcoming}</div><div className="hint">Rides and airport transfers</div></div>
              <div className="card kpi"><div className="label">Billed to your account this month</div><div className="value">{naira(data.stats.conciergeMonth)}</div><div className="hint">Invoiced monthly</div></div>
              <div className="card kpi"><div className="label">Concierge</div><div className="value"><Link to="/concierge">Open</Link></div><div className="hint">Book and track guest transport</div></div>
            </div>
          )}

          {tours && (
            <div className="grid grid-main">
              <div className="card">
                <div className="card-head"><h2>Today</h2><Link to="/check-in">Check-in</Link></div>
                {data.todaysSlots.length === 0 ? (
                  <Empty>No tours scheduled today.</Empty>
                ) : (
                  data.todaysSlots.map((s) => (
                    <Link className="list-item" key={s.id} to={`/bookings?date=${lagosDate(s.startsAt)}&tour=${s.tourId}`}>
                      <div className="strong" style={{ width: 56 }}>{formatTime(s.startsAt)}</div>
                      <div>
                        <div className="strong">{s.tour.title}</div>
                        <div className="muted small">{s.blocked ? 'Blocked' : `${plural(s.guests, 'guest')} booked of ${s.capacity}`}</div>
                      </div>
                      <div className="end">{s.guests > 0 && <Status value={s.checkedIn >= s.guests ? 'checked_in' : 'confirmed'} label={`${s.checkedIn}/${s.guests} checked in`} />}</div>
                    </Link>
                  ))
                )}
              </div>
              <div className="card">
                <div className="card-head"><h2>Your listings</h2><Link to="/tours">All tours</Link></div>
                {[
                  ['Live', data.listings.live, 'live'],
                  ['In review by Cabo', data.listings.inReview, 'in_review'],
                  ['Changes requested', data.listings.changesRequested, 'changes_requested'],
                  ['Drafts', data.listings.drafts, 'draft'],
                ].map(([label, n, status]) => (
                  <Link className="list-item" to={`/tours?status=${status}`} key={label}><Status value={status} label={label} /><span className="end strong">{n}</span></Link>
                ))}
              </div>
            </div>
          )}

          {tours && (
            <div className="grid grid-main">
              <div className="card">
                <div className="card-head"><h2>Coming up this week</h2><Link to="/bookings">All bookings</Link></div>
                {data.upcoming.length === 0 ? <Empty>No bookings in the next 7 days.</Empty> : (
                  <div className="table-wrap"><table>
                    <thead><tr><th>When</th><th>Guest</th><th>Tour</th><th className="right">Guests</th></tr></thead>
                    <tbody>
                      {data.upcoming.map((b) => (
                        <tr key={b.id}>
                          <td className="nowrap">{formatDay(b.slot.startsAt)}, {formatTime(b.slot.startsAt)}</td>
                          <td><Link className="strong" to={`/bookings/${b.id}`}>{b.guestName}</Link>{b.specialRequests && <div className="muted small">Has a special request</div>}</td>
                          <td>{b.tour.title}</td>
                          <td className="right">{b.guests}</td>
                        </tr>
                      ))}
                    </tbody>
                  </table></div>
                )}
              </div>
              <div className="card">
                <div className="card-head"><h2>Reviews to answer</h2><Link to="/reviews">All reviews</Link></div>
                {data.awaitingReply.length === 0 ? <Empty>You have replied to every review.</Empty> : data.awaitingReply.map((r) => (
                  <Link className="list-item" to="/reviews" key={r.id} style={{ alignItems: 'flex-start' }}>
                    <div>
                      <Stars value={r.rating} /> <span className="muted small">{r.guestName}</span>
                      <div className="small">{r.comment.length > 90 ? `${r.comment.slice(0, 90)}…` : r.comment}</div>
                    </div>
                  </Link>
                ))}
              </div>
            </div>
          )}
        </div>
      )}
    </>
  )
}

function TourStats({ data }) {
  const { stats } = data
  return (
    <div className="grid grid-4">
      <div className="card kpi accent"><div className="label">This month's bookings</div><div className="value">{naira(stats.netThisMonth)}</div><div className="hint">What you receive after commission</div></div>
      <div className="card kpi"><div className="label">Guests in the next 7 days</div><div className="value">{stats.guestsNext7}</div><div className="hint">{plural(stats.bookingsNext7, 'booking')}</div></div>
      <div className="card kpi"><div className="label">Today</div><div className="value">{data.todaysSlots.reduce((n, s) => n + s.guests, 0)}</div><div className="hint">{data.todaysSlots.reduce((n, s) => n + s.checkedIn, 0)} guests checked in</div></div>
      <div className="card kpi"><div className="label">Rating</div><div className="value">{stats.rating ? stats.rating.toFixed(1) : '—'}</div><div className="hint">{plural(stats.reviews, 'review')} · {stats.unanswered} to answer</div></div>
    </div>
  )
}
