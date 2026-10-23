import { useState } from 'react'
import { Link, Navigate, useParams } from 'react-router-dom'
import { changePassword, confirmPassword, signOut } from '../api/auth'
import { cancelDeletion, exportData, removeGuide, requestDeletion, saveGuide, updateBank, updateNotificationSettings, updatePartner, uploadDocument } from '../api/portal'
import { resetDemoData } from '../api/store'
import { useAuth } from '../auth/AuthContext'
import FileInput from '../components/FileInput'
import GuideForm from '../components/GuideForm'
import Icon from '../components/Icon'
import { useToast } from '../components/Toasts'
import { Dialog, Field, FormMessage, PageHead, Status } from '../components/ui'
import { addDays, formatDate, formatDateTime, humanize, lagosDate } from '../lib/format'
import { download, useForm, useTitle } from '../lib/hooks'

const BANKS = ['Access Bank', 'Fidelity Bank', 'First Bank', 'FCMB', 'GTBank', 'Kuda', 'Moniepoint', 'Opay', 'Stanbic IBTC', 'Sterling Bank', 'UBA', 'Union Bank', 'Wema Bank', 'Zenith Bank']

export default function Settings() {
  const { tab } = useParams()
  const { account, refresh } = useAuth()
  const { partner } = account
  const tabs = [
    ['business', 'Business'],
    ...(['tour_operator', 'guide'].includes(partner.type) ? [['guides', 'Guides']] : []),
    ['documents', 'Documents'],
    ['bank', 'Bank details'],
    ['notifications', 'Alerts'],
    ['security', 'Password'],
    ['privacy', 'Privacy and data'],
  ]
  const current = tabs.find(([k]) => k === tab)
  useTitle(current ? `Settings: ${current[1]}` : 'Settings')
  if (!current) return <Navigate to="/settings/business" replace />

  const panels = { business: Business, guides: Guides, documents: Documents, bank: Bank, notifications: Alerts, security: Security, privacy: Privacy }
  const Panel = panels[tab]
  return (
    <>
      <PageHead title="Settings" subtitle={partner.name} />
      <div className="card">
        <div className="filters">
          <nav className="tabs" aria-label="Settings sections">
            {tabs.map(([key, label]) => <Link key={key} to={`/settings/${key}`} className={key === tab ? 'active' : undefined} aria-current={key === tab ? 'page' : undefined}>{label}</Link>)}
          </nav>
        </div>
        <div className="card-body">
          <Panel partner={partner} user={account.user} refresh={refresh} />
        </div>
      </div>
    </>
  )
}

function Business({ partner, refresh }) {
  const toast = useToast()
  const form = useForm({ name: partner.name, contactName: partner.contactName, phone: partner.phone, address: partner.address, area: partner.area, description: partner.description })
  async function save(e) {
    e.preventDefault()
    try { await form.submit(updatePartner); await refresh(); toast('Business details saved.') } catch { /* shown */ }
  }
  return (
    <form onSubmit={save} style={{ maxWidth: 720 }} noValidate>
      <FormMessage message={form.message} />
      <div className="form-grid">
        <Field label="Business name" name="name" error={form.errors.name}><input type="text" {...form.bind('name')} /></Field>
        <Field label="Contact person" name="contactName"><input type="text" {...form.bind('contactName')} /></Field>
        <Field label="Phone" name="phone"><input type="tel" {...form.bind('phone')} /></Field>
        <Field label="Area" name="area"><input type="text" {...form.bind('area')} /></Field>
        <div className="full"><Field label="Address" name="address"><input type="text" {...form.bind('address')} /></Field></div>
        <div className="full"><Field label="About your business" name="description" hint="Shown on your partner profile in the app."><textarea maxLength={600} {...form.bind('description')} /></Field></div>
      </div>
      <dl className="dl" style={{ marginBottom: 16 }}>
        <dt>Email</dt><dd>{partner.email}</dd>
        <dt>Partner type</dt><dd>{humanize(partner.type)}</dd>
        <dt>CAC number</dt><dd>{partner.cacNumber}</dd>
        <dt>Status</dt><dd><Status value={partner.status} /></dd>
        {partner.type !== 'hotel' && <><dt>Commission</dt><dd>{partner.commissionRate}% of each booking</dd></>}
      </dl>
      <p className="hint">To change your email, CAC number or partner type, contact partners@caboapp.online.</p>
      <button className="btn btn-primary" disabled={form.busy}>Save</button>
    </form>
  )
}

function Guides({ partner, refresh }) {
  const toast = useToast()
  const [editing, setEditing] = useState(null)
  const [error, setError] = useState(null)
  return (
    <div className="stack" style={{ maxWidth: 760 }}>
      <p className="muted">Everyone who leads Cabo guests. Cabo background-checks new guides before they lead tours.</p>
      {error && <div className="alert err" role="alert">{error}</div>}
      {partner.guides.map((g) => (editing?.id === g.id ? (
        <GuideForm key={g.id} initial={g} onCancel={() => setEditing(null)} onSave={async (x) => { await saveGuide({ ...x, id: g.id }); await refresh(); setEditing(null); toast('Guide saved.') }} />
      ) : (
        <div className="card card-body row between" key={g.id}>
          <div style={{ minWidth: 0 }}>
            <div className="strong">{g.name}</div>
            <div className="muted small">{g.phone} · {g.languages.join(', ')}</div>
            {g.bio && <div className="small">{g.bio}</div>}
          </div>
          <div className="row tight">
            <button className="btn btn-ghost btn-sm" onClick={() => setEditing(g)}>Edit</button>
            <button className="btn btn-danger btn-sm" onClick={async () => { try { await removeGuide(g.id); await refresh(); toast('Guide removed.') } catch (e) { setError(e.message) } }}>Remove</button>
          </div>
        </div>
      )))}
      {editing === 'new' ? (
        <GuideForm onCancel={() => setEditing(null)} saveLabel="Add guide" onSave={async (x) => { await saveGuide(x); await refresh(); setEditing(null); toast('Guide added.') }} />
      ) : (
        <button className="btn btn-ghost" onClick={() => setEditing('new')}><Icon name="plus" size={16} /> Add a guide</button>
      )}
    </div>
  )
}

function Documents({ partner, refresh }) {
  const toast = useToast()
  const [replacing, setReplacing] = useState(null)
  const [file, setFile] = useState(null)
  const [expiresOn, setExpiresOn] = useState('')
  const [error, setError] = useState(null)
  const soon = addDays(lagosDate(), 30)
  const types = [['cac', 'CAC certificate'], ...(partner.type !== 'hotel' ? [['insurance', 'Insurance certificate']] : [])]
  return (
    <div className="stack" style={{ maxWidth: 760 }}>
      <p className="muted">Only Cabo's partner team can see these. We remind you 30, 14 and 3 days before a document expires; tours are paused if insurance lapses.</p>
      {types.map(([type, label]) => {
        const doc = partner.documents.find((d) => d.type === type)
        const state = !doc ? 'missing' : doc.expiresOn && doc.expiresOn < lagosDate() ? 'expired' : doc.expiresOn && doc.expiresOn <= soon ? 'expiring' : doc.status
        return (
          <div className="card card-body" key={type}>
            <div className="row between">
              <div>
                <div className="strong">{doc?.label || label}</div>
                <div className="muted small">{doc ? `${doc.fileName} · uploaded ${formatDate(doc.uploadedAt)}${doc.expiresOn ? ` · expires ${formatDate(doc.expiresOn)}` : ''}` : 'Not uploaded'}</div>
              </div>
              <div className="row tight">
                <Status value={state} label={state === 'expiring' ? 'Expires soon' : state === 'missing' ? 'Missing' : undefined} />
                <button className="btn btn-ghost btn-sm" onClick={() => { setReplacing(type); setFile(null); setExpiresOn(''); setError(null) }}>{doc ? 'Upload new' : 'Upload'}</button>
              </div>
            </div>
            {replacing === type && (
              <div style={{ marginTop: 14 }}>
                <FileInput id={`file-${type}`} label={`New ${label.toLowerCase()}`} file={file} onChange={(f, err) => { setFile(f); setError(err || null) }} />
                {type === 'insurance' && <Field label="Expiry date" name="expiresOn"><input id="expiresOn" type="date" min={lagosDate()} value={expiresOn} onChange={(e) => setExpiresOn(e.target.value)} style={{ maxWidth: 220 }} /></Field>}
                {error && <div className="error" role="alert">{error}</div>}
                <div className="row tight">
                  <button className="btn btn-primary btn-sm" onClick={async () => {
                    try { await uploadDocument({ type, label, file, expiresOn }); await refresh(); setReplacing(null); toast('Uploaded. Cabo will review it within 2 working days.') } catch (e) { setError(e.message) }
                  }}>Upload</button>
                  <button className="btn btn-ghost btn-sm" onClick={() => setReplacing(null)}>Cancel</button>
                </div>
              </div>
            )}
          </div>
        )
      })}
    </div>
  )
}

function Bank({ partner, refresh }) {
  const toast = useToast()
  const [confirming, setConfirming] = useState(false)
  const [password, setPassword] = useState('')
  const [pwError, setPwError] = useState(null)
  const form = useForm({ name: partner.bank.name, accountNumber: partner.bank.accountNumber, accountName: partner.bank.accountName })
  async function save() {
    try {
      await confirmPassword(password)
    } catch (e) {
      setPwError(e.message)
      return
    }
    setConfirming(false)
    setPassword('')
    try { await form.submit(updateBank); await refresh(); toast('Bank details updated.') } catch { /* shown */ }
  }
  return (
    <div style={{ maxWidth: 560 }}>
      <p className="muted">Payouts go here every Tuesday. For your security we ask for your password before changing them, and email you when they change.</p>
      <FormMessage message={form.message} />
      <Field label="Bank" name="name" error={form.errors.bankName}>
        <select {...form.bind('name')}><option value="">Choose…</option>{BANKS.map((b) => <option key={b}>{b}</option>)}</select>
      </Field>
      <Field label="Account number" name="accountNumber" error={form.errors.accountNumber}><input type="text" inputMode="numeric" maxLength={10} {...form.bind('accountNumber')} /></Field>
      <Field label="Account name" name="accountName" error={form.errors.accountName}><input type="text" {...form.bind('accountName')} /></Field>
      <button className="btn btn-primary" onClick={() => { setPwError(null); setConfirming(true) }}>Save bank details</button>
      <Dialog open={confirming} onClose={() => setConfirming(false)} title="Confirm it's you" footer={<><button className="btn btn-ghost" onClick={() => setConfirming(false)}>Cancel</button><button className="btn btn-primary" onClick={save}>Confirm</button></>}>
        <Field label="Your password" name="confirmPassword" error={pwError}>
          <input id="confirmPassword" type="password" autoComplete="current-password" value={password} onChange={(e) => setPassword(e.target.value)} onKeyDown={(e) => e.key === 'Enter' && save()} autoFocus />
        </Field>
      </Dialog>
    </div>
  )
}

function Alerts({ partner, refresh }) {
  const toast = useToast()
  const form = useForm({ ...partner.notifications })
  const v = form.values
  const toggle = (k) => <input type="checkbox" checked={Boolean(v[k])} onChange={(e) => form.set(k, e.target.checked)} />
  async function save(e) {
    e.preventDefault()
    try { await form.submit(updateNotificationSettings); await refresh(); toast('Alert settings saved.') } catch { /* shown */ }
  }
  return (
    <form onSubmit={save} style={{ maxWidth: 620 }} noValidate>
      <FormMessage message={form.message} />
      <h2>Where to send alerts</h2>
      <div className="stack-sm" style={{ margin: '12px 0 20px' }}>
        <label className="check">{toggle('email')} <span>Email to {partner.email}</span></label>
        <label className="check">{toggle('whatsapp')} <span>WhatsApp</span></label>
        {v.whatsapp && <Field label="WhatsApp number" name="whatsappNumber" error={form.errors.whatsappNumber}><input type="tel" {...form.bind('whatsappNumber')} style={{ maxWidth: 280 }} /></Field>}
      </div>
      <h2>What to send</h2>
      <div className="stack-sm" style={{ margin: '12px 0 20px' }}>
        <label className="check">{toggle('newBooking')} <span>New bookings, with guest details and special requests</span></label>
        <label className="check">{toggle('cancellation')} <span>Cancellations</span></label>
        <label className="check">{toggle('review')} <span>New reviews</span></label>
        <label className="check">{toggle('payout')} <span>Payouts sent</span></label>
      </div>
      <p className="hint">Messages about your account, documents and listings are always sent by email.</p>
      <button className="btn btn-primary" disabled={form.busy}>Save</button>
    </form>
  )
}

function Security({ user }) {
  const toast = useToast()
  const form = useForm({ current: '', password: '', confirm: '' })
  async function save(e) {
    e.preventDefault()
    if (form.values.password !== form.values.confirm) {
      form.setErrors({ confirm: 'The passwords do not match.' })
      return
    }
    try { await form.submit(changePassword); form.setValues({ current: '', password: '', confirm: '' }); toast('Password changed.') } catch { /* shown */ }
  }
  return (
    <form onSubmit={save} style={{ maxWidth: 420 }} noValidate>
      <p className="muted">Signed in as {user.email}{user.lastSignInAt ? `. Last sign-in ${formatDateTime(user.lastSignInAt)}.` : '.'}</p>
      <FormMessage message={form.message} />
      <Field label="Current password" name="current" error={form.errors.current}><input type="password" autoComplete="current-password" {...form.bind('current')} /></Field>
      <Field label="New password" name="password" error={form.errors.password} hint="At least 8 characters, with a letter and a number."><input type="password" autoComplete="new-password" {...form.bind('password')} /></Field>
      <Field label="Confirm new password" name="confirm" error={form.errors.confirm}><input type="password" autoComplete="new-password" {...form.bind('confirm')} /></Field>
      <button className="btn btn-primary" disabled={form.busy}>Change password</button>
    </form>
  )
}

function Privacy({ partner, refresh }) {
  const toast = useToast()
  const [asking, setAsking] = useState(false)
  const [reason, setReason] = useState('')
  const [resetting, setResetting] = useState(false)
  return (
    <div className="stack" style={{ maxWidth: 680 }}>
      <section>
        <h2>Download your data</h2>
        <p className="muted">A copy of your business details, listings, bookings, reviews and payouts as a JSON file. Under the Nigeria Data Protection Act 2023 and the GDPR you can ask for this at any time.</p>
        <button className="btn btn-ghost" onClick={async () => download(`cabo-partner-data-${lagosDate()}.json`, JSON.stringify(await exportData(), null, 2), 'application/json')}><Icon name="download" size={16} /> Download my data</button>
      </section>
      <section>
        <h2>Close your partner account</h2>
        {partner.deletionRequestedAt ? (
          <div className="alert warn">
            <p>You asked us to close this account on {formatDate(partner.deletionRequestedAt)}. Cabo's partner team will contact you to settle any remaining bookings and payouts, then delete your data except what the law requires us to keep (such as payment records).</p>
            <button className="btn btn-ghost btn-sm" onClick={async () => { await cancelDeletion(); await refresh(); toast('Request withdrawn.') }}>Withdraw request</button>
          </div>
        ) : (
          <>
            <p className="muted">Upcoming bookings are honoured or refunded first, and your final payout is sent before the account is closed.</p>
            <button className="btn btn-danger" onClick={() => setAsking(true)}>Ask to close my account</button>
          </>
        )}
      </section>
      <section>
        <h2>Demo data</h2>
        <p className="muted">This portal runs on sample data from <span className="mono">src/data/db.json</span>. Changes you make are kept in this browser. Resetting restores the original data and signs you out.</p>
        <button className="btn btn-ghost" onClick={() => setResetting(true)}>Reset demo data</button>
      </section>

      <Dialog open={asking} onClose={() => setAsking(false)} title="Close your partner account?" footer={<><button className="btn btn-ghost" onClick={() => setAsking(false)}>Cancel</button><button className="btn btn-danger" onClick={async () => { await requestDeletion(reason); await refresh(); setAsking(false); toast('Request sent to Cabo.') }}>Send request</button></>}>
        <Field label="Anything we should know?" name="reason" optional><textarea id="reason" value={reason} onChange={(e) => setReason(e.target.value)} /></Field>
      </Dialog>
      <Dialog open={resetting} onClose={() => setResetting(false)} title="Reset the demo data?" footer={<><button className="btn btn-ghost" onClick={() => setResetting(false)}>Cancel</button><button className="btn btn-danger" onClick={() => { resetDemoData(); signOut(); window.location.assign('/login') }}>Reset</button></>}>
        <p>All changes made in this browser are lost, including new accounts and tours.</p>
      </Dialog>
    </div>
  )
}
