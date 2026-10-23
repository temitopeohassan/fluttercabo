import { Link, useSearchParams } from 'react-router-dom'
import { listTours } from '../api/portal'
import { useAuth } from '../auth/AuthContext'
import Icon from '../components/Icon'
import { Empty, Loading, LoadError, PageHead, Status } from '../components/ui'
import { duration, naira, plural } from '../lib/format'
import { useAsync, useTitle } from '../lib/hooks'

const FILTERS = [['', 'All'], ['live', 'Live'], ['in_review', 'In review'], ['changes_requested', 'Changes requested'], ['draft', 'Drafts'], ['paused', 'Paused']]

export default function Tours() {
  useTitle('Tours')
  const { partner } = useAuth().account
  const [params, setParams] = useSearchParams()
  const status = params.get('status') || ''
  const { data, loading, error, reload } = useAsync(listTours, [])
  const tours = (data || []).filter((t) => !status || t.status === status || (status === 'in_review' && t.changesInReview))

  return (
    <>
      <PageHead title="Tours" subtitle="Your listings in the Cabo app. New tours and changes go live after Cabo reviews them, usually within 2 working days.">
        <Link className="btn btn-primary" to="/tours/new"><Icon name="plus" size={16} /> New tour</Link>
      </PageHead>
      {partner.status !== 'approved' && <div className="alert warn">Your application is still in review. You can prepare tours as drafts and send them for review once you are approved.</div>}
      <div className="card">
        <div className="filters">
          <nav className="tabs" aria-label="Filter tours by status">
            {FILTERS.map(([value, label]) => (
              <Link key={value} to={value ? `?status=${value}` : '?'} className={status === value ? 'active' : undefined} aria-current={status === value ? 'page' : undefined} onClick={(e) => { e.preventDefault(); setParams(value ? { status: value } : {}) }}>{label}</Link>
            ))}
          </nav>
        </div>
        <div className="card-body">
          {loading && !data && <Loading />}
          {error && <LoadError error={error} retry={reload} />}
          {data && tours.length === 0 && (
            <Empty title={data.length ? 'No tours here' : 'Create your first tour'} action={!data.length && <Link className="btn btn-primary" to="/tours/new">New tour</Link>}>
              {data.length ? 'Try another filter.' : 'Add photos, an itinerary, prices and add-ons. You can save as a draft at any point.'}
            </Empty>
          )}
          <div className="tour-grid">
            {tours.map((t) => (
              <Link className="card tour-card" key={t.id} to={`/tours/${t.id}`}>
                {t.photos[0] ? <img className="photo" src={t.photos[0]} alt="" /> : <div className="photo none">No photo yet</div>}
                <div className="body">
                  <div className="row tight">
                    <Status value={t.status} />
                    {t.changesInReview && <Status value="in_review" label="Changes in review" />}
                  </div>
                  <h2>{t.title}</h2>
                  <div className="muted small">{t.category || 'No category'} · {t.area || 'No area'}{t.durationMinutes ? ` · ${duration(t.durationMinutes)}` : ''}</div>
                  <div className="row between" style={{ marginTop: 'auto', paddingTop: 6 }}>
                    <span className="strong">{t.price ? `${naira(t.price)} pp` : 'No price'}</span>
                    <span className="muted small">{t.status === 'live' || t.status === 'paused' ? `${plural(t.upcomingBookings, 'upcoming booking')}${t.rating ? ` · ★ ${t.rating.toFixed(1)}` : ''}` : ''}</span>
                  </div>
                </div>
              </Link>
            ))}
          </div>
        </div>
      </div>
    </>
  )
}
