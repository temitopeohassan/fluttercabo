import { Link, useLocation } from 'react-router-dom'
import { DEMO_ACCOUNTS, DEMO_PASSWORD } from '../api/auth'
import { useAuth } from '../auth/AuthContext'
import { Field, FormMessage } from '../components/ui'
import { useForm, useTitle } from '../lib/hooks'

export function AuthArt() {
  return (
    <div className="auth-art" role="img" aria-label="Lekki–Ikoyi Link Bridge at sunset">
      <div className="copy">
        <h2>Grow with <span>Cabo.</span></h2>
        <p>List your tours and tickets for visitors to Lagos, and get paid every week.</p>
        <ul>
          <li>Bookings with guest details, straight to email and WhatsApp</li>
          <li>Check guests in by scanning their QR ticket</li>
          <li>Weekly payouts to your Nigerian bank account</li>
        </ul>
      </div>
    </div>
  )
}

export default function SignIn() {
  useTitle('Sign in')
  const { signIn } = useAuth()
  const location = useLocation()
  const form = useForm({ email: '', password: '', remember: false })

  async function onSubmit(e) {
    e.preventDefault()
    try {
      // GuestOnly then sends the partner on to location.state.from.
      await form.submit(signIn)
    } catch {
      // Message shown by the form.
    }
  }

  return (
    <div className="auth">
      <AuthArt />
      <div className="auth-form">
        <form className="inner" onSubmit={onSubmit} noValidate>
          <img className="logo" src="/images/brand/logo-wordmark-dark.png" alt="Cabo" width="129" height="48" />
          <h1>Partner portal</h1>
          <p className="muted" style={{ margin: '4px 0 24px' }}>Sign in to manage your tours, tickets and bookings.</p>
          {location.state?.reset && !form.message && <div className="alert ok" role="status">Password changed. Sign in with your new password.</div>}
          <FormMessage message={form.message} />
          <Field label="Email" name="email" error={form.errors.email}>
            <input type="email" autoComplete="username" required autoFocus {...form.bind('email')} />
          </Field>
          <Field label="Password" name="password" error={form.errors.password}>
            <input type="password" autoComplete="current-password" required {...form.bind('password')} />
          </Field>
          <div className="row between field">
            <label className="check">
              <input type="checkbox" checked={form.values.remember} onChange={(e) => form.set('remember', e.target.checked)} /> Keep me signed in
            </label>
            <Link to="/forgot-password">Forgot password?</Link>
          </div>
          <button className="btn btn-primary btn-block" type="submit" disabled={form.busy}>{form.busy ? 'Signing in…' : 'Sign in'}</button>
          <p style={{ marginTop: 20 }}>New to Cabo? <Link to="/apply">Apply to become a partner</Link></p>

          <div className="demo-box">
            <div className="strong">Demo accounts</div>
            <div className="muted small">Password for all: <span className="mono">{DEMO_PASSWORD}</span>. Choose one to fill in the form.</div>
            {DEMO_ACCOUNTS.map((a) => (
              <button type="button" key={a.email} onClick={() => form.setValues((v) => ({ ...v, email: a.email, password: DEMO_PASSWORD }))}>
                <span className="strong">{a.name}</span> <span className="muted small">· {a.label}</span>
                <span className="mono muted" style={{ display: 'block', fontSize: 12 }}>{a.email}</span>
              </button>
            ))}
          </div>
        </form>
      </div>
    </div>
  )
}
