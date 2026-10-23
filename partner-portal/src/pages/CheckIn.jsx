import jsQR from 'jsqr'
import { useCallback, useEffect, useRef, useState } from 'react'
import { Link, useSearchParams } from 'react-router-dom'
import { checkIn, lookUpTicket, todaysGuests } from '../api/portal'
import { useAuth } from '../auth/AuthContext'
import Icon from '../components/Icon'
import { useToast } from '../components/Toasts'
import { Empty, Loading, PageHead, Status } from '../components/ui'
import { formatLongDate, formatTime, lagosDate, plural } from '../lib/format'
import { useAsync, useTitle } from '../lib/hooks'

/** Reads QR codes from the phone's camera with jsQR. */
function Scanner({ onCode }) {
  const video = useRef(null)
  const [state, setState] = useState('starting')
  useEffect(() => {
    let stream
    let frame
    let stopped = false
    const canvas = document.createElement('canvas')
    const ctx = canvas.getContext('2d', { willReadFrequently: true })
    async function start() {
      if (!navigator.mediaDevices?.getUserMedia) return setState('unsupported')
      try {
        stream = await navigator.mediaDevices.getUserMedia({ video: { facingMode: 'environment' }, audio: false })
        if (stopped) return stream.getTracks().forEach((t) => t.stop())
        video.current.srcObject = stream
        await video.current.play()
        setState('scanning')
        const tick = () => {
          const v = video.current
          if (stopped || !v) return
          if (v.readyState === v.HAVE_ENOUGH_DATA) {
            canvas.width = v.videoWidth
            canvas.height = v.videoHeight
            ctx.drawImage(v, 0, 0)
            const result = jsQR(ctx.getImageData(0, 0, canvas.width, canvas.height).data, canvas.width, canvas.height, { inversionAttempts: 'dontInvert' })
            if (result?.data) {
              navigator.vibrate?.(80)
              onCode(result.data)
              return
            }
          }
          frame = requestAnimationFrame(tick)
        }
        frame = requestAnimationFrame(tick)
      } catch (error) {
        setState(error.name === 'NotAllowedError' ? 'denied' : 'unavailable')
      }
    }
    start()
    return () => {
      stopped = true
      cancelAnimationFrame(frame)
      stream?.getTracks().forEach((t) => t.stop())
    }
  }, [onCode])

  const messages = {
    starting: 'Starting the camera…',
    denied: 'Camera access was blocked. Allow the camera for this site in your browser settings, or type the booking reference below.',
    unsupported: 'This browser cannot use the camera. Type the booking reference below.',
    unavailable: 'No camera was found. Type the booking reference below.',
  }
  return (
    <div className="scanner">
      <video ref={video} playsInline muted aria-label="Camera view for scanning tickets" style={{ display: state === 'scanning' ? 'block' : 'none' }} />
      {state === 'scanning' && <div className="frame" aria-hidden="true" />}
      {state !== 'scanning' && <p style={{ padding: 24, textAlign: 'center' }} role="status">{messages[state]}</p>}
    </div>
  )
}

export default function CheckIn() {
  const { partner } = useAuth().account
  const tickets = partner.type === 'attraction'
  useTitle(tickets ? 'Entry check-in' : 'Check-in')
  const toast = useToast()
  const [params] = useSearchParams()
  const [scanning, setScanning] = useState(false)
  const [code, setCode] = useState(params.get('code') || '')
  const [result, setResult] = useState(null)
  const [busy, setBusy] = useState(false)
  const list = useAsync(todaysGuests, [])

  const look = useCallback(async (value) => {
    setScanning(false)
    setBusy(true)
    try {
      setResult(await lookUpTicket(value))
    } catch (e) {
      setResult({ kind: 'error', message: e.message })
    } finally {
      setBusy(false)
    }
  }, [])

  useEffect(() => {
    if (params.get('code')) look(params.get('code'))
  }, [params, look])

  async function confirm() {
    setBusy(true)
    try {
      const id = result.kind === 'entry' ? result.sale.id : result.booking.id
      await checkIn({ kind: result.kind, id })
      toast(result.kind === 'entry' ? `${plural(result.sale.quantity, 'ticket')} admitted.` : `${result.booking.guestName} checked in.`)
      setResult(null)
      setCode('')
      list.reload()
    } catch (e) {
      setResult({ kind: 'error', message: e.message })
    } finally {
      setBusy(false)
    }
  }

  const bookings = list.data?.bookings || []
  const sales = list.data?.tickets || []
  const arrived = tickets ? sales.filter((s) => s.status === 'used').reduce((n, s) => n + s.quantity, 0) : bookings.filter((b) => ['checked_in', 'completed'].includes(b.status)).reduce((n, b) => n + b.guests, 0)
  const expected = tickets ? sales.reduce((n, s) => n + s.quantity, 0) : bookings.reduce((n, b) => n + b.guests, 0)

  return (
    <>
      <PageHead title={tickets ? 'Entry check-in' : 'Check guests in'} subtitle={`${formatLongDate(lagosDate())} · ${arrived} of ${plural(expected, tickets ? 'ticket' : 'guest')} checked in`} />
      <div className="grid grid-2">
        <div className="stack">
          <div className="card card-body stack-sm">
            {scanning ? (
              <>
                <Scanner onCode={look} />
                <button className="btn btn-ghost btn-block" onClick={() => setScanning(false)}>Stop camera</button>
              </>
            ) : (
              <button className="btn btn-primary btn-block" style={{ minHeight: 64, fontSize: 17 }} onClick={() => { setResult(null); setScanning(true) }}>
                <Icon name="camera" size={22} /> Scan a QR ticket
              </button>
            )}
            <form className="input-group" onSubmit={(e) => { e.preventDefault(); look(code) }}>
              <label className="visually-hidden" htmlFor="code">Booking reference or ticket code</label>
              <input id="code" type="text" placeholder={tickets ? 'Ticket reference, e.g. TK-7K2Q9M' : 'Booking reference, e.g. TR-7K2Q9M'} value={code} onChange={(e) => setCode(e.target.value)} autoCapitalize="characters" />
              <button className="btn btn-ghost" disabled={busy || !code.trim()}>Find</button>
            </form>
          </div>

          <div aria-live="assertive">
            {busy && <Loading label="Checking ticket…" />}
            {result && !busy && <Result result={result} onConfirm={confirm} onClear={() => setResult(null)} />}
          </div>
        </div>

        <div className="card">
          <div className="card-head"><h2>{tickets ? "Today's tickets" : "Today's guests"}</h2><button className="btn btn-ghost btn-sm" onClick={list.reload}>Refresh</button></div>
          {list.loading && !list.data && <Loading />}
          {!tickets && list.data && (bookings.length === 0 ? <Empty>No guests booked today.</Empty> : bookings.map((b) => (
            <div className="list-item" key={b.id}>
              <div className="strong" style={{ width: 48 }}>{formatTime(b.slot.startsAt)}</div>
              <div>
                <Link className="strong" to={`/bookings/${b.id}`}>{b.guestName}</Link>
                <div className="muted small">{b.tour.title} · {plural(b.guests, 'guest')}{b.specialRequests ? ' · has a request' : ''}</div>
              </div>
              <div className="end">
                {b.status === 'confirmed'
                  ? <button className="btn btn-yellow btn-sm" onClick={() => { setCode(b.reference); look(b.reference) }}>Check in</button>
                  : <Status value={b.status} />}
              </div>
            </div>
          )))}
          {tickets && list.data && (sales.length === 0 ? <Empty>No tickets for today.</Empty> : sales.map((s) => (
            <div className="list-item" key={s.id}>
              <div>
                <div className="strong">{s.buyerName}</div>
                <div className="muted small"><span className="mono">{s.reference}</span> · {s.quantity} × {s.type.name}</div>
              </div>
              <div className="end">
                {s.status === 'valid'
                  ? <button className="btn btn-yellow btn-sm" onClick={() => { setCode(s.reference); look(s.reference) }}>Admit</button>
                  : <Status value={s.status} />}
              </div>
            </div>
          )))}
        </div>
      </div>
    </>
  )
}

function Result({ result, onConfirm, onClear }) {
  if (result.kind === 'error') {
    return (
      <div className="scan-result bad" role="alert">
        <h2>Not valid</h2>
        <p>{result.message}</p>
        <button className="btn btn-ghost" onClick={onClear}>Scan another</button>
      </div>
    )
  }
  if (result.kind === 'entry') {
    const s = result.sale
    return (
      <div className={`scan-result ${result.problem ? 'bad' : 'ok'}`} role={result.problem ? 'alert' : 'status'}>
        <h2>{result.problem ? 'Cannot admit' : `Admit ${s.quantity}`}</h2>
        <p className="strong">{s.buyerName}</p>
        <p>{s.quantity} × {s.type.name} · <span className="mono">{s.reference}</span></p>
        {result.problem && <p className="strong">{result.problem}</p>}
        <div className="row">
          {!result.problem && <button className="btn btn-primary" onClick={onConfirm}>Admit {plural(s.quantity, 'person', 'people')}</button>}
          <button className="btn btn-ghost" onClick={onClear}>{result.problem ? 'Scan another' : 'Cancel'}</button>
        </div>
      </div>
    )
  }
  const b = result.booking
  return (
    <div className={`scan-result ${result.problem ? 'bad' : 'ok'}`} role={result.problem ? 'alert' : 'status'}>
      <h2>{result.problem ? 'Cannot check in' : 'Valid ticket'}</h2>
      <p className="strong" style={{ fontSize: 18 }}>{b.guestName}</p>
      <p>{b.tour.title} · {formatTime(b.slot.startsAt)} · {plural(b.guests, 'guest')}</p>
      {b.addons.length > 0 && <p className="small">Add-ons: {b.addons.map((a) => a.name).join(', ')}</p>}
      {b.specialRequests && <p className="small"><strong>Request:</strong> {b.specialRequests}</p>}
      {result.problem && <p className="strong">{result.problem}</p>}
      <div className="row">
        {!result.problem && <button className="btn btn-primary" onClick={onConfirm}>Check in {plural(b.guests, 'guest')}</button>}
        <button className="btn btn-ghost" onClick={onClear}>{result.problem ? 'Scan another' : 'Cancel'}</button>
      </div>
    </div>
  )
}
