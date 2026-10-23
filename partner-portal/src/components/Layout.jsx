import { useEffect, useState } from 'react'
import { Link, NavLink, Outlet, useLocation, useNavigate } from 'react-router-dom'
import { unreadCount } from '../api/portal'
import { CHANGE_EVENT } from '../api/store'
import { useAuth } from '../auth/AuthContext'
import { humanize } from '../lib/format'
import Icon from './Icon'

const TOURS = ['tour_operator', 'guide']

export function navFor(partner) {
  const approved = partner.status === 'approved'
  const items = []
  if (!approved) items.push({ to: '/application', label: 'Application', icon: 'file' })
  if (approved) items.push({ to: '/', label: 'Dashboard', icon: 'home', end: true })
  if (TOURS.includes(partner.type)) {
    items.push({ to: '/tours', label: 'Tours', icon: 'map' })
    if (approved) {
      items.push({ to: '/availability', label: 'Availability', icon: 'calendar' })
      items.push({ to: '/bookings', label: 'Bookings', icon: 'ticket' })
      items.push({ to: '/check-in', label: 'Check-in', icon: 'scan' })
      items.push({ to: '/reviews', label: 'Reviews', icon: 'star' })
    }
  }
  if (partner.type === 'attraction' && approved) {
    items.push({ to: '/tickets', label: 'Tickets', icon: 'ticket' })
    items.push({ to: '/check-in', label: 'Entry check-in', icon: 'scan' })
  }
  if (partner.type === 'hotel' && approved) items.push({ to: '/concierge', label: 'Concierge', icon: 'car' })
  if (approved && partner.type !== 'hotel') items.push({ to: '/earnings', label: 'Earnings', icon: 'wallet' })
  items.push({ to: '/notifications', label: 'Notifications', icon: 'bell', badge: true })
  items.push({ to: '/settings', label: 'Settings', icon: 'settings' })
  return items
}

export default function Layout() {
  const { account, signOut } = useAuth()
  const { user, partner } = account
  const location = useLocation()
  // The mobile menu is open for the page it was opened on, so navigating closes it.
  const [openOn, setOpenOn] = useState(null)
  const open = openOn === location.pathname
  const setOpen = (value) => setOpenOn((current) => ((typeof value === 'function' ? value(current === location.pathname) : value) ? location.pathname : null))
  const navigate = useNavigate()
  const [unread, setUnread] = useState(unreadCount)

  useEffect(() => {
    const update = () => setUnread(unreadCount())
    window.addEventListener(CHANGE_EVENT, update)
    return () => window.removeEventListener(CHANGE_EVENT, update)
  }, [])

  useEffect(() => {
    const onKey = (e) => e.key === 'Escape' && setOpenOn(null)
    window.addEventListener('keydown', onKey)
    return () => window.removeEventListener('keydown', onKey)
  }, [])

  return (
    <div className={`shell${open ? ' nav-open' : ''}`} onClick={(e) => open && e.target === e.currentTarget && setOpen(false)}>
      <a className="skip-link" href="#main">Skip to content</a>
      <aside className="sidebar" id="sidebar" aria-label="Portal navigation">
        <Link className="brand" to="/"><img src="/images/brand/logo-lockup-light.png" alt="Cabo: Ride, Tour, Travel" width="103" height="44" /></Link>
        <div className="brand-sub">Partner Portal</div>
        <div className="business-card">
          <div className="name">{partner.name}</div>
          <div className="type">{humanize(partner.type)}{partner.status !== 'approved' ? ` · ${partner.status === 'pending' ? 'application in review' : humanize(partner.status)}` : ''}</div>
        </div>
        <nav className="nav">
          {navFor(partner).map((item) => (
            <NavLink key={item.to} to={item.to} end={item.end} className={({ isActive }) => (isActive ? 'active' : undefined)}>
              <Icon name={item.icon} /> {item.label}
              {item.badge && unread > 0 && <span className="count" aria-label={`${unread} unread`}>{unread}</span>}
            </NavLink>
          ))}
        </nav>
        <div className="sidebar-foot">
          Need help? <a href="mailto:partners@caboapp.online">partners@caboapp.online</a>
        </div>
      </aside>

      <div className="main">
        <header className="topbar">
          <button className="icon-button menu-toggle" type="button" aria-label="Open menu" aria-expanded={open} aria-controls="sidebar" onClick={() => setOpen((o) => !o)}>
            <Icon name="menu" size={22} />
          </button>
          <div className="who">
            <Link className="icon-button" to="/notifications" aria-label={unread ? `Notifications, ${unread} unread` : 'Notifications'}>
              <Icon name="bell" />
              {unread > 0 && <span className="dot" aria-hidden="true">{unread > 9 ? '9+' : unread}</span>}
            </Link>
            <div className="right who-name">
              <div className="strong">{user.name}</div>
              <div className="muted small">{user.email}</div>
            </div>
            <span className="avatar" aria-hidden="true">{user.name.charAt(0)}</span>
            <button className="btn btn-ghost btn-sm" type="button" onClick={() => { signOut(); navigate('/login') }}>
              <Icon name="logout" size={16} /> Sign out
            </button>
          </div>
        </header>
        <main className="content" id="main" tabIndex={-1}>
          <Outlet />
        </main>
      </div>
    </div>
  )
}
