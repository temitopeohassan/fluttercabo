import { useState } from 'react'
import { Link, useNavigate } from 'react-router-dom'
import { requestPasswordReset, resetPassword } from '../api/auth'
import { Field, FormMessage } from '../components/ui'
import { useForm, useTitle } from '../lib/hooks'
import { AuthArt } from './SignIn'

export default function ForgotPassword() {
  useTitle('Reset password')
  const navigate = useNavigate()
  const [step, setStep] = useState('email')
  const [demoCode, setDemoCode] = useState(null)
  const form = useForm({ email: '', code: '', password: '' })

  async function sendCode(e) {
    e.preventDefault()
    if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(form.values.email.trim())) {
      form.setErrors({ email: 'Enter the email you sign in with.' })
      return
    }
    const result = await form.submit((v) => requestPasswordReset(v.email))
    setDemoCode(result.demoCode)
    setStep('code')
  }

  async function reset(e) {
    e.preventDefault()
    try {
      await form.submit(resetPassword)
      navigate('/login', { replace: true, state: { reset: true } })
    } catch {
      // Shown in the form.
    }
  }

  return (
    <div className="auth">
      <AuthArt />
      <div className="auth-form">
        <div className="inner">
          <img className="logo" src="/images/brand/logo-wordmark-dark.png" alt="Cabo" width="129" height="48" />
          {step === 'email' ? (
            <form onSubmit={sendCode} noValidate>
              <h1>Reset your password</h1>
              <p className="muted" style={{ margin: '4px 0 24px' }}>Enter your email and we will send you a 6-digit code.</p>
              <FormMessage message={form.message} />
              <Field label="Email" name="email" error={form.errors.email}>
                <input type="email" autoComplete="username" required autoFocus {...form.bind('email')} />
              </Field>
              <button className="btn btn-primary btn-block" disabled={form.busy}>Send code</button>
            </form>
          ) : (
            <form onSubmit={reset} noValidate>
              <h1>Check your email</h1>
              <p className="muted" style={{ margin: '4px 0 16px' }}>If {form.values.email} has a partner account, we sent a code to it. It expires in 15 minutes.</p>
              {demoCode && (
                <div className="alert info">
                  <p className="small">This demo cannot send email. Your code is:</p>
                  <p className="code-display">{demoCode}</p>
                </div>
              )}
              <FormMessage message={form.message} />
              <Field label="6-digit code" name="code" error={form.errors.code}>
                <input type="text" inputMode="numeric" autoComplete="one-time-code" maxLength={6} required autoFocus {...form.bind('code')} />
              </Field>
              <Field label="New password" name="password" error={form.errors.password} hint="At least 8 characters, with a letter and a number.">
                <input type="password" autoComplete="new-password" required {...form.bind('password')} />
              </Field>
              <button className="btn btn-primary btn-block" disabled={form.busy}>Set new password</button>
              <p style={{ marginTop: 12 }}><button type="button" className="btn-link" onClick={() => setStep('email')}>Use a different email</button></p>
            </form>
          )}
          <p style={{ marginTop: 20 }}><Link to="/login">Back to sign in</Link></p>
        </div>
      </div>
    </div>
  )
}
