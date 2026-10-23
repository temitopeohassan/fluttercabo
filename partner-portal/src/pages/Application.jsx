import { Link } from 'react-router-dom'
import { useAuth } from '../auth/AuthContext'
import { PageHead, Status } from '../components/ui'
import { formatDate, humanize } from '../lib/format'
import { useTitle } from '../lib/hooks'

/** P-01: where a new partner follows their application. */
export default function Application() {
  useTitle('Application')
  const { partner } = useAuth().account
  const tours = ['tour_operator', 'guide'].includes(partner.type)
  const doc = (type) => partner.documents.find((d) => d.type === type)
  const items = [
    ['Business details', Boolean(partner.name && partner.cacNumber && partner.address), `${partner.name} · ${partner.cacNumber}`],
    ['CAC registration', Boolean(doc('cac')), doc('cac')?.fileName],
    ...(partner.type !== 'hotel' ? [['Insurance certificate', Boolean(doc('insurance')), doc('insurance') && `${doc('insurance').fileName} · expires ${formatDate(doc('insurance').expiresOn)}`]] : []),
    ...(tours ? [['Guides', partner.guides.length > 0, partner.guides.map((g) => g.name).join(', ')]] : []),
    ['Bank details for payouts', Boolean(partner.bank.accountNumber), partner.bank.accountNumber && `${partner.bank.name} ••••${partner.bank.accountNumber.slice(-4)}`],
  ]

  if (partner.status === 'approved') {
    return (
      <>
        <PageHead title="Application" subtitle={`Approved on ${formatDate(partner.approvedAt)}.`} />
        <div className="alert ok">Your business is approved. <Link to="/">Go to your dashboard</Link>.</div>
      </>
    )
  }

  return (
    <>
      <PageHead title="Your application" subtitle={`Submitted ${formatDate(partner.appliedAt)} as a ${humanize(partner.type).toLowerCase()}.`} />
      <div className="grid grid-main">
        <div className="stack">
          {partner.status === 'pending' && (
            <div className="alert warn">
              <p className="strong">We are reviewing your application.</p>
              <p>Cabo's partner team checks your registration, insurance and guides, usually within 2 working days. We will email {partner.email} when it is done.</p>
            </div>
          )}
          {partner.status === 'rejected' && <div className="alert err">Your application was not approved. Contact partners@caboapp.online for details.</div>}
          <div className="card">
            <div className="card-head"><h2>What we have</h2><Status value={partner.status} /></div>
            <div className="card-body">
              <ul className="checklist">
                {items.map(([label, done, detail]) => (
                  <li key={label}>
                    <span className={`tick${done ? ' on' : ''}`} aria-hidden="true">{done ? '✓' : '!'}</span>
                    <span><span className="strong">{label}</span>{done ? <span className="visually-hidden"> (provided)</span> : <span className="visually-hidden"> (missing)</span>}<br /><span className="muted small">{detail || 'Not provided yet'}</span></span>
                  </li>
                ))}
              </ul>
              <p className="small muted" style={{ marginTop: 8 }}>Need to change something? Update it under <Link to="/settings/business">Settings</Link>.</p>
            </div>
          </div>
        </div>
        <div className="card">
          <div className="card-head"><h2>While you wait</h2></div>
          <div className="card-body stack-sm">
            {tours ? (
              <>
                <p>Start preparing your tours. You can save them as drafts now and send them for review once you are approved.</p>
                <Link className="btn btn-primary" to="/tours/new">Create a tour</Link>
              </>
            ) : (
              <p>Once you are approved you can {partner.type === 'hotel' ? 'book rides and airport pickups for your guests' : 'list tickets for sale'} from this portal.</p>
            )}
            <p className="small muted">Questions? Email partners@caboapp.online or call +234 201 330 2226.</p>
          </div>
        </div>
      </div>
    </>
  )
}
