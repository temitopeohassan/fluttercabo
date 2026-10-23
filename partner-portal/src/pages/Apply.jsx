import { useState } from 'react'
import { Link, useNavigate } from 'react-router-dom'
import { useAuth } from '../auth/AuthContext'
import FileInput from '../components/FileInput'
import GuideForm from '../components/GuideForm'
import Icon from '../components/Icon'
import { Field, FormMessage } from '../components/ui'
import { humanize } from '../lib/format'
import { useForm, useTitle } from '../lib/hooks'
import { passwordProblems } from '../lib/password'

const TYPES = [
  { value: 'tour_operator', label: 'Tour operator', text: 'A business running tours with one or more guides.' },
  { value: 'guide', label: 'Independent guide', text: 'You lead tours yourself, registered as a business name.' },
  { value: 'attraction', label: 'Attraction or venue', text: 'Galleries, parks, museums and venues selling entry tickets.' },
  { value: 'hotel', label: 'Hotel or short-let', text: 'Book rides and airport pickups for your guests.' },
]
const AREAS = ['Victoria Island', 'Ikoyi', 'Lekki', 'Yaba', 'Surulere', 'Lagos Island', 'Ikeja', 'Badagry', 'Epe', 'Other']
const BANKS = ['Access Bank', 'Fidelity Bank', 'First Bank', 'FCMB', 'GTBank', 'Kuda', 'Moniepoint', 'Opay', 'Stanbic IBTC', 'Sterling Bank', 'UBA', 'Union Bank', 'Wema Bank', 'Zenith Bank']

const STEP_FIELDS = {
  business: ['businessName', 'type', 'cacNumber', 'address', 'area'],
  guides: ['guides'],
  documents: ['cac', 'insurance', 'insuranceExpiresOn'],
  account: ['name', 'email', 'phone', 'password', 'bankName', 'bankAccountNumber', 'bankAccountName', 'consent'],
}

export default function Apply() {
  useTitle('Apply to become a partner')
  const { apply } = useAuth()
  const navigate = useNavigate()
  const form = useForm({
    businessName: '', type: 'tour_operator', cacNumber: '', address: '', area: '', description: '',
    guides: [], documents: {}, insuranceExpiresOn: '',
    name: '', email: '', phone: '', password: '', bankName: '', bankAccountNumber: '', bankAccountName: '', whatsappUpdates: true, consent: false,
  })
  const [addingGuide, setAddingGuide] = useState(false)
  const { values: v, errors } = form
  const hasGuides = ['tour_operator', 'guide'].includes(v.type)
  const steps = ['business', ...(hasGuides ? ['guides'] : []), 'documents', 'account']
  const [stepIndex, setStepIndex] = useState(0)
  const step = steps[Math.min(stepIndex, steps.length - 1)]

  function check(name) {
    const e = {}
    if (name === 'business') {
      if (!v.businessName.trim()) e.businessName = 'Enter your business name.'
      if (!/^(RC|BN|IT)?\s?\d{5,8}$/i.test(v.cacNumber.trim())) e.cacNumber = 'Enter your CAC number, e.g. RC 1456721 or BN 3390021.'
      if (!v.address.trim()) e.address = 'Enter your business address.'
      if (!v.area) e.area = 'Choose your area.'
    }
    if (name === 'guides' && !v.guides.length) e.guides = 'Add at least one guide.'
    if (name === 'documents') {
      if (!v.documents.cac) e.cac = 'Upload your CAC certificate.'
      if (v.type !== 'hotel') {
        if (!v.documents.insurance) e.insurance = 'Upload your insurance certificate.'
        if (!v.insuranceExpiresOn) e.insuranceExpiresOn = 'Add the date your insurance expires.'
        else if (v.insuranceExpiresOn <= new Date().toISOString().slice(0, 10)) e.insuranceExpiresOn = 'This insurance has expired.'
      }
    }
    if (name === 'account') {
      if (!v.name.trim()) e.name = 'Enter your name.'
      if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(v.email.trim())) e.email = 'Enter a valid email address.'
      if (!/^\+?[0-9 ]{10,16}$/.test(v.phone)) e.phone = 'Enter a phone number, e.g. +234 802 123 4567.'
      const p = passwordProblems(v.password)
      if (p.length) e.password = `Use ${p.join(', ')}.`
      if (!v.bankName) e.bankName = 'Choose your bank.'
      if (!/^\d{10}$/.test(v.bankAccountNumber)) e.bankAccountNumber = 'Nigerian account numbers (NUBAN) have 10 digits.'
      if (!v.bankAccountName.trim()) e.bankAccountName = 'Enter the account name.'
      if (!v.consent) e.consent = 'You need to accept the partner terms and privacy notice.'
    }
    form.setErrors(e)
    form.setMessage(Object.keys(e).length ? 'Please fix the highlighted fields.' : null)
    if (Object.keys(e).length) document.getElementById(Object.keys(e)[0])?.focus()
    return !Object.keys(e).length
  }

  function next(e) {
    e.preventDefault()
    if (!check(step)) return
    setStepIndex((i) => i + 1)
    window.scrollTo(0, 0)
  }

  async function submit(e) {
    e.preventDefault()
    if (!check('account')) return
    try {
      await form.submit(apply)
      navigate('/application', { replace: true })
    } catch (error) {
      const failed = steps.find((s) => STEP_FIELDS[s]?.some((f) => error.fields?.[f]))
      if (failed) setStepIndex(steps.indexOf(failed))
    }
  }

  const docLabel = (k) => (k === 'cac' ? (v.type === 'guide' ? 'Business name registration (BN)' : 'CAC certificate of incorporation') : 'Public liability insurance certificate')

  return (
    <div className="auth-wide">
      <div className="inner">
        <div className="row between" style={{ marginBottom: 20 }}>
          <img src="/images/brand/logo-wordmark-dark.png" alt="Cabo" width="107" height="40" />
          <span className="muted">Already a partner? <Link to="/login">Sign in</Link></span>
        </div>
        <h1>Apply to become a Cabo partner</h1>
        <p className="muted" style={{ margin: '4px 0 20px' }}>It takes about 10 minutes. We review applications within 2 working days, and your tours go live after Cabo checks them.</p>

        <ol className="steps" aria-label="Application steps">
          {steps.map((s, i) => (
            <li key={s} className={i < stepIndex ? 'done' : i === stepIndex ? 'current' : undefined} aria-current={i === stepIndex ? 'step' : undefined}>
              <span className="n">{i < stepIndex ? <Icon name="check" size={14} /> : i + 1}</span>
              {{ business: 'Business', guides: 'Guides', documents: 'Documents', account: 'Account and payouts' }[s]}
            </li>
          ))}
        </ol>

        <form className="card" onSubmit={step === 'account' ? submit : next} noValidate>
          <div className="card-body">
            <FormMessage message={form.message} />

            {step === 'business' && (
              <>
                <fieldset className="field" style={{ border: 0, padding: 0, margin: '0 0 16px' }}>
                  <legend className="label">What kind of partner are you?</legend>
                  <div className="grid grid-2">
                    {TYPES.map((t) => (
                      <label className="option-card" key={t.value}>
                        <input type="radio" name="type" value={t.value} checked={v.type === t.value} onChange={() => form.set('type', t.value)} />
                        <span><span className="strong">{t.label}</span><br /><span className="muted small">{t.text}</span></span>
                      </label>
                    ))}
                  </div>
                </fieldset>
                <div className="form-grid">
                  <Field label="Business name" name="businessName" error={errors.businessName}><input type="text" autoComplete="organization" {...form.bind('businessName')} /></Field>
                  <Field label="CAC registration number" name="cacNumber" error={errors.cacNumber} hint="RC for companies, BN for business names."><input type="text" {...form.bind('cacNumber')} /></Field>
                  <Field label="Business address" name="address" error={errors.address}><input type="text" autoComplete="street-address" {...form.bind('address')} /></Field>
                  <Field label="Area" name="area" error={errors.area}>
                    <select {...form.bind('area')}><option value="">Choose…</option>{AREAS.map((a) => <option key={a}>{a}</option>)}</select>
                  </Field>
                  <div className="full"><Field label="About your business" name="description" optional hint="What you offer and what makes it special."><textarea {...form.bind('description')} maxLength={600} /></Field></div>
                </div>
              </>
            )}

            {step === 'guides' && (
              <>
                <h2>Your guides</h2>
                <p className="muted">Everyone who will lead Cabo guests. Cabo runs a background check on each guide, and guests see their name, languages and bio.</p>
                {errors.guides && <div className="error" id="guides" tabIndex={-1}>{errors.guides}</div>}
                <div className="stack" style={{ marginTop: 12 }}>
                  {v.guides.map((g, i) => (
                    <div className="row between card card-body" key={i}>
                      <div><div className="strong">{g.name}</div><div className="muted small">{g.phone} · {g.languages.join(', ')}</div></div>
                      <button type="button" className="btn btn-danger btn-sm" onClick={() => form.set('guides', v.guides.filter((_, j) => j !== i))}>Remove</button>
                    </div>
                  ))}
                  {addingGuide || !v.guides.length ? (
                    <GuideForm
                      initial={!v.guides.length && v.type === 'guide' ? { name: v.name, phone: v.phone, languages: ['English'], idNumber: '', bio: '' } : undefined}
                      onSave={(g) => { form.set('guides', [...v.guides, g]); setAddingGuide(false) }}
                      onCancel={v.guides.length ? () => setAddingGuide(false) : undefined}
                      saveLabel="Add guide"
                    />
                  ) : (
                    <button type="button" className="btn btn-ghost" onClick={() => setAddingGuide(true)}><Icon name="plus" size={16} /> Add another guide</button>
                  )}
                </div>
              </>
            )}

            {step === 'documents' && (
              <>
                <h2>Documents</h2>
                <p className="muted">PDF, JPG or PNG, up to 10 MB each. Only Cabo's partner team can see these.</p>
                <div style={{ marginTop: 12 }}>
                  <FileInput id="cac" label={docLabel('cac')} file={v.documents.cac} error={errors.cac} onChange={(f, err) => { form.set('documents', { ...v.documents, cac: f }); form.setErrors((e) => ({ ...e, cac: err })) }} />
                  {v.type !== 'hotel' && (
                    <>
                      <FileInput id="insurance" label={docLabel('insurance')} file={v.documents.insurance} error={errors.insurance} hint="Must cover guests on your tours or at your venue." onChange={(f, err) => { form.set('documents', { ...v.documents, insurance: f }); form.setErrors((e) => ({ ...e, insurance: err })) }} />
                      <Field label="Insurance expiry date" name="insuranceExpiresOn" error={errors.insuranceExpiresOn} hint="We remind you 30, 14 and 3 days before it expires.">
                        <input type="date" {...form.bind('insuranceExpiresOn')} style={{ maxWidth: 220 }} />
                      </Field>
                    </>
                  )}
                </div>
              </>
            )}

            {step === 'account' && (
              <>
                <h2>Your account</h2>
                <div className="form-grid" style={{ marginTop: 12 }}>
                  <Field label="Your full name" name="name" error={errors.name}><input type="text" autoComplete="name" {...form.bind('name')} /></Field>
                  <Field label="Phone" name="phone" error={errors.phone}><input type="tel" autoComplete="tel" {...form.bind('phone')} /></Field>
                  <Field label="Email" name="email" error={errors.email} hint="You sign in with this, and booking emails go here."><input type="email" autoComplete="email" {...form.bind('email')} /></Field>
                  <Field label="Password" name="password" error={errors.password} hint="At least 8 characters, with a letter and a number."><input type="password" autoComplete="new-password" {...form.bind('password')} /></Field>
                </div>
                <h2 style={{ marginTop: 8 }}>Payouts</h2>
                <p className="muted">We pay you every Tuesday for the previous week's completed bookings, less Cabo's {v.type === 'hotel' ? '' : '15% '}commission.</p>
                <div className="form-grid" style={{ marginTop: 12 }}>
                  <Field label="Bank" name="bankName" error={errors.bankName}>
                    <select {...form.bind('bankName')}><option value="">Choose…</option>{BANKS.map((b) => <option key={b}>{b}</option>)}</select>
                  </Field>
                  <Field label="Account number" name="bankAccountNumber" error={errors.bankAccountNumber}><input type="text" inputMode="numeric" maxLength={10} {...form.bind('bankAccountNumber')} /></Field>
                  <div className="full"><Field label="Account name" name="bankAccountName" error={errors.bankAccountName} hint="As it appears on your bank statement."><input type="text" {...form.bind('bankAccountName')} /></Field></div>
                </div>
                <div className="field">
                  <label className="check"><input type="checkbox" checked={v.whatsappUpdates} onChange={(e) => form.set('whatsappUpdates', e.target.checked)} /> Send new booking alerts to this phone on WhatsApp</label>
                </div>
                <div className="field">
                  <label className="check">
                    <input id="consent" type="checkbox" checked={v.consent} onChange={(e) => form.set('consent', e.target.checked)} aria-invalid={errors.consent ? true : undefined} />
                    <span>I agree to the Cabo partner terms and have read the privacy notice. Cabo processes my business and guide details under the Nigeria Data Protection Act 2023 to review this application and pay me.</span>
                  </label>
                  {errors.consent && <div className="error">{errors.consent}</div>}
                </div>
                <div className="alert info small">
                  You are applying as a <strong>{humanize(v.type).toLowerCase()}</strong>: {v.businessName}{v.guides.length ? `, with ${v.guides.length} ${v.guides.length === 1 ? 'guide' : 'guides'}` : ''}.
                </div>
              </>
            )}
          </div>
          <div className="card-foot row between">
            {stepIndex > 0 ? <button type="button" className="btn btn-ghost" onClick={() => { form.setErrors({}); form.setMessage(null); setStepIndex((i) => i - 1) }}>Back</button> : <span />}
            <button className="btn btn-primary" type="submit" disabled={form.busy}>{step === 'account' ? (form.busy ? 'Submitting…' : 'Submit application') : 'Continue'}</button>
          </div>
        </form>
      </div>
    </div>
  )
}
