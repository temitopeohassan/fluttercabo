import Icon from './Icon'

const MAX = 10 * 1024 * 1024

/** File picker for business documents. Keeps only the file's name and size in the demo. */
export default function FileInput({ id, label, file, onChange, error, hint, accept = '.pdf,.jpg,.jpeg,.png' }) {
  return (
    <div className="field">
      <span className="label">{label}</span>
      <div className="row">
        <input
          id={id}
          type="file"
          accept={accept}
          className="visually-hidden"
          aria-label={label}
          aria-invalid={error ? true : undefined}
          aria-describedby={error ? `${id}-error` : undefined}
          onChange={(e) => {
            const f = e.target.files?.[0]
            if (!f) return
            if (f.size > MAX) return onChange(null, 'Files must be under 10 MB.')
            onChange({ name: f.name, size: f.size })
          }}
        />
        <label className="btn btn-ghost btn-sm" htmlFor={id} style={{ marginBottom: 0 }}>
          <Icon name="upload" size={16} /> {file ? 'Replace file' : 'Choose file'}
        </label>
        <span className={file ? 'strong' : 'muted'}>{file ? `${file.name} (${Math.max(1, Math.round(file.size / 1024))} KB)` : 'No file chosen'}</span>
      </div>
      {hint && !error && <div className="hint">{hint}</div>}
      {error && <div className="error" id={`${id}-error`}>{error}</div>}
    </div>
  )
}
