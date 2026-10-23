import { useState } from 'react'
import { settings } from '../api/store'
import { Field } from './ui'


/** Guide details for applications and settings (P-01). */
export default function GuideForm({ initial, onSave, onCancel, errors: outerErrors = {}, saveLabel = 'Save guide' }) {
  const [guide, setGuide] = useState(initial || { name: '', phone: '', languages: ['English'], idNumber: '', bio: '' })
  const [errors, setErrors] = useState({})
  const set = (k, v) => setGuide((g) => ({ ...g, [k]: v }))
  const all = { ...outerErrors, ...errors }
  const LANGUAGES = settings().languages

  async function save() {
    const e = {}
    if (!guide.name.trim()) e.name = 'Add the guide’s name.'
    if (!/^\+?[0-9 ]{10,16}$/.test(guide.phone)) e.phone = 'Add a phone number, e.g. +234 802 123 4567.'
    if (!guide.languages.length) e.languages = 'Choose at least one language.'
    setErrors(e)
    if (Object.keys(e).length) return
    try {
      await onSave(guide)
    } catch (error) {
      setErrors(error.fields || {})
    }
  }

  return (
    <div className="card card-body" role="group" aria-label="Guide details">
      <div className="form-grid">
        <Field label="Full name" name="guide-name" error={all.name}>
          <input id="guide-name" type="text" value={guide.name} onChange={(e) => set('name', e.target.value)} aria-invalid={all.name ? true : undefined} />
        </Field>
        <Field label="Phone" name="guide-phone" error={all.phone}>
          <input id="guide-phone" type="tel" value={guide.phone} onChange={(e) => set('phone', e.target.value)} aria-invalid={all.phone ? true : undefined} />
        </Field>
        <Field label="NIN or guide licence number" name="guide-id" optional hint="Used for Cabo's background check. Never shown to guests.">
          <input id="guide-id" type="text" value={guide.idNumber} onChange={(e) => set('idNumber', e.target.value)} />
        </Field>
        <div className="field full">
          <span className="label" id="guide-languages">Languages</span>
          <div className="choices" role="group" aria-labelledby="guide-languages">
            {LANGUAGES.map((l) => (
              <label className="chip" key={l}>
                <input type="checkbox" checked={guide.languages.includes(l)} onChange={(e) => set('languages', e.target.checked ? [...guide.languages, l] : guide.languages.filter((x) => x !== l))} /> {l}
              </label>
            ))}
          </div>
          {all.languages && <div className="error">{all.languages}</div>}
        </div>
        <Field label="Short bio shown to guests" name="guide-bio" optional>
          <textarea id="guide-bio" value={guide.bio} onChange={(e) => set('bio', e.target.value)} maxLength={300} style={{ minHeight: 80 }} />
        </Field>
      </div>
      <div className="row">
        <button type="button" className="btn btn-primary btn-sm" onClick={save}>{saveLabel}</button>
        {onCancel && <button type="button" className="btn btn-ghost btn-sm" onClick={onCancel}>Cancel</button>}
      </div>
    </div>
  )
}
