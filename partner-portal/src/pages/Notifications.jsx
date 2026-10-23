import { Link } from 'react-router-dom'
import { listNotifications, markNotificationsRead } from '../api/portal'
import { Empty, Loading, LoadError, PageHead } from '../components/ui'
import { relativeTime } from '../lib/format'
import { useAsync, useTitle } from '../lib/hooks'

const ICONS = { booking: '🎟', cancellation: '✕', review: '★', payout: '₦', listing: '✎', application: '✓', document: '!', account: '🔒' }

export default function Notifications() {
  useTitle('Notifications')
  const { data, loading, error, reload } = useAsync(listNotifications, [])
  const unread = data?.filter((n) => !n.read).length || 0
  return (
    <>
      <PageHead title="Notifications" subtitle="Everything we have sent you. Choose which alerts also go to email and WhatsApp in Settings.">
        <Link className="btn btn-ghost" to="/settings/notifications">Alert settings</Link>
        <button className="btn btn-ghost" disabled={!unread} onClick={async () => { await markNotificationsRead(); reload() }}>Mark all as read</button>
      </PageHead>
      {error && <LoadError error={error} retry={reload} />}
      <div className="card">
        {loading && !data && <Loading />}
        {data?.length === 0 && <Empty>No notifications yet.</Empty>}
        {data?.map((n) => (
          <Link className="list-item" key={n.id} to={n.link || '#'} onClick={() => !n.read && markNotificationsRead([n.id])} style={{ alignItems: 'flex-start', background: n.read ? undefined : '#F7FBF8' }}>
            <span className="avatar" aria-hidden="true">{ICONS[n.type] || '•'}</span>
            <div style={{ minWidth: 0 }}>
              <div className="strong">{n.title} {!n.read && <span className="badge green plain">New</span>}</div>
              <div className="small">{n.body}</div>
              <div className="muted small">{relativeTime(n.createdAt)}{n.channels?.length ? ` · also sent by ${n.channels.join(' and ')}` : ''}</div>
            </div>
          </Link>
        ))}
      </div>
    </>
  )
}
