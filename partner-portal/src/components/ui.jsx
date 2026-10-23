import { useEffect, useRef } from 'react'
import { humanize } from '../lib/format'
import Icon from './Icon'

const COLOURS = {
  live: 'green', approved: 'green', confirmed: 'blue', completed: 'green', checked_in: 'green', paid: 'green', valid: 'blue', used: 'green', driver_assigned: 'blue',
  in_review: 'yellow', pending: 'yellow', processing: 'yellow', requested: 'yellow', scheduled: 'yellow',
  changes_requested: 'orange', paused: 'orange', no_show: 'orange', expiring: 'orange',
  cancelled: 'red', rejected: 'red', suspended: 'red', expired: 'red', refunded: 'red', blocked: 'red',
  draft: '',
}
const LABELS = { in_review: 'In review', changes_requested: 'Changes requested', no_show: 'No-show', checked_in: 'Checked in', driver_assigned: 'Driver assigned', pending: 'Pending review' }

export function Status({ value, label }) {
  return <span className={`badge ${COLOURS[value] ?? ''}`}>{label || LABELS[value] || humanize(value)}</span>
}

export function Field({ label, name, error, hint, children, optional }) {
  return (
    <div className="field">
      {label && (
        <label htmlFor={name}>
          {label} {optional && <span className="muted">(optional)</span>}
        </label>
      )}
      {children}
      {hint && !error && <div className="hint" id={`${name}-hint`}>{hint}</div>}
      {error && <div className="error" id={`${name}-error`}>{error}</div>}
    </div>
  )
}

export function FormMessage({ message }) {
  if (!message) return null
  return <div className="alert err" role="alert">{message}</div>
}

export function Loading({ label = 'Loading…' }) {
  return <div className="empty" role="status" aria-live="polite">{label}</div>
}

export function LoadError({ error, retry }) {
  return (
    <div className="alert err" role="alert">
      <p>{error?.message || 'Something went wrong loading this page.'}</p>
      {retry && <button className="btn btn-ghost btn-sm" onClick={retry}>Try again</button>}
    </div>
  )
}

export function Empty({ title, children, action }) {
  return (
    <div className="empty">
      {title && <h2>{title}</h2>}
      {children && <p>{children}</p>}
      {action}
    </div>
  )
}

export function PageHead({ title, subtitle, children, crumbs }) {
  return (
    <>
      {crumbs && <nav className="breadcrumb" aria-label="Breadcrumb">{crumbs}</nav>}
      <div className="page-head">
        <div>
          <h1>{title}</h1>
          {subtitle && <p>{subtitle}</p>}
        </div>
        {children && <div className="row">{children}</div>}
      </div>
    </>
  )
}

export function Stars({ value }) {
  const n = Math.round(value)
  return <span className="stars" role="img" aria-label={`${value.toFixed ? value.toFixed(1) : value} out of 5 stars`}>{'★'.repeat(n)}{'☆'.repeat(5 - n)}</span>
}

/** A native <dialog> used as a modal. */
export function Dialog({ open, onClose, title, children, footer }) {
  const ref = useRef(null)
  useEffect(() => {
    const d = ref.current
    if (!d) return
    if (open && !d.open) {
      if (d.showModal) d.showModal()
      else d.setAttribute('open', '')
    }
    if (!open && d.open) {
      if (d.close) d.close()
      else d.removeAttribute('open')
    }
  }, [open])
  return (
    <dialog ref={ref} onClose={onClose} aria-labelledby="dialog-title" onCancel={onClose}>
      {open && (
        <>
          <div className="dialog-head"><h2 id="dialog-title">{title}</h2></div>
          <div className="dialog-body">{children}</div>
          {footer && <div className="dialog-foot">{footer}</div>}
        </>
      )}
    </dialog>
  )
}

/** Editable list of strings, e.g. itinerary steps or inclusions. */
export function ListEditor({ id, items, onChange, placeholder, numbered, addLabel = 'Add', error }) {
  const update = (i, value) => onChange(items.map((x, j) => (j === i ? value : x)))
  const move = (i, d) => {
    const next = [...items]
    ;[next[i], next[i + d]] = [next[i + d], next[i]]
    onChange(next)
  }
  const List = numbered ? 'ol' : 'ul'
  return (
    <div className="list-editor" id={id}>
      <List>
        {items.map((item, i) => (
          <li key={i}>
            {numbered && <span className="num" aria-hidden="true">{i + 1}</span>}
            <input type="text" value={item} placeholder={placeholder} onChange={(e) => update(i, e.target.value)} aria-label={`${placeholder || 'Item'} ${i + 1}`} aria-invalid={error && !item ? true : undefined} />
            {numbered && (
              <>
                <button type="button" className="icon-button" onClick={() => move(i, -1)} disabled={i === 0} aria-label={`Move step ${i + 1} up`}><Icon name="up" /></button>
                <button type="button" className="icon-button" onClick={() => move(i, 1)} disabled={i === items.length - 1} aria-label={`Move step ${i + 1} down`}><Icon name="down" /></button>
              </>
            )}
            <button type="button" className="icon-button" onClick={() => onChange(items.filter((_, j) => j !== i))} aria-label={`Remove ${item || 'item'}`}><Icon name="x" /></button>
          </li>
        ))}
      </List>
      <button type="button" className="btn btn-ghost btn-sm" onClick={() => onChange([...items, ''])}><Icon name="plus" size={16} /> {addLabel}</button>
    </div>
  )
}
