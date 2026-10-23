import { useCallback, useEffect, useRef, useState } from 'react'

/** Runs an async loader and tracks loading, error and data. `reload` runs it again. */
export function useAsync(loader, deps = []) {
  const [state, setState] = useState({ loading: true, error: null, data: null })
  const latest = useRef(0)
  // eslint-disable-next-line react-hooks/exhaustive-deps
  const run = useCallback(loader, deps)
  const reload = useCallback(() => {
    const id = ++latest.current
    setState((s) => ({ ...s, loading: true }))
    return run().then(
      (data) => id === latest.current && setState({ loading: false, error: null, data }),
      (error) => id === latest.current && setState({ loading: false, error, data: null }),
    )
  }, [run])
  useEffect(() => {
    reload()
  }, [reload])
  return { ...state, reload, setData: (data) => setState((s) => ({ ...s, data })) }
}

/** Form state with field errors from ApiError. */
export function useForm(initial) {
  const [values, setValues] = useState(initial)
  const [errors, setErrors] = useState({})
  const [message, setMessage] = useState(null)
  const [busy, setBusy] = useState(false)
  const set = (name, value) => {
    setValues((v) => ({ ...v, [name]: value }))
    setErrors((e) => (e[name] ? { ...e, [name]: undefined } : e))
  }
  const bind = (name, { type } = {}) => ({
    name,
    id: name,
    value: values[name] ?? '',
    onChange: (e) => set(name, type === 'number' ? e.target.value : e.target.value),
    'aria-invalid': errors[name] ? true : undefined,
    'aria-describedby': errors[name] ? `${name}-error` : undefined,
  })
  async function submit(action) {
    setBusy(true)
    setMessage(null)
    try {
      const result = await action(values)
      setErrors({})
      return result
    } catch (error) {
      setErrors(error.fields || {})
      setMessage(error.message || 'Something went wrong. Please try again.')
      throw error
    } finally {
      setBusy(false)
    }
  }
  return { values, setValues, set, bind, errors, setErrors, message, setMessage, busy, submit }
}

export function useTitle(title) {
  useEffect(() => {
    document.title = title ? `${title} · Cabo Partner Portal` : 'Cabo Partner Portal'
  }, [title])
}

export function download(filename, content, type = 'text/csv') {
  const url = URL.createObjectURL(new Blob([content], { type }))
  const a = Object.assign(document.createElement('a'), { href: url, download: filename })
  document.body.appendChild(a)
  a.click()
  a.remove()
  setTimeout(() => URL.revokeObjectURL(url), 1000)
}
