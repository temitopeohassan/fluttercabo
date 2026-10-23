import QRCode from 'qrcode'
import { useEffect, useState } from 'react'
import { Link, useParams } from 'react-router-dom'
import { cancelBooking, getBooking, markNoShow, qrPayload } from '../api/portal'
import { settings } from '../api/store'
import { useToast } from '../components/Toasts'
import { Dialog, Field, Loading, LoadError, PageHead, Stars, Status } from '../components/ui'
import { formatDateTime, formatLongDate, formatTime, lagosDate, maskPhone, naira } from '../lib/format'
import { useAsync, useTitle } from '../lib/hooks'

export default function BookingDetail() {
  const { id } = useParams()
  const toast = useToast()
  const { data: b, loading, error, reload, setData } = useAsync(() => getBooking(id), [id])
  const [qr, setQr] = useState(null)
  const [cancelling, setCancelling] = useState(false)
  const [reason, setReason] = useState('')
  const [actionError, setActionError] = useState(null)
  useTitle(b ? `Booking ${b.reference}` : 'Booking')

  useEffect(() => {
    if (b?.qrToken) QRCode.toDataURL(qrPayload(b.qrToken), { margin: 1, width: 180, color: { dark: '#12261B' } }).then(setQr)
  }, [b?.qrToken])

  if (error) return <LoadError error={error} retry={reload} />
  if (loading && !b) return <Loading />

  const started = b.slot.startsAt <= new Date().toISOString()
  const today = lagosDate(b.slot.startsAt) === lagosDate()

  return (
    <>
      <PageHead crumbs={<><Link to="/bookings">Bookings</Link> / {b.reference}</>} title={b.guestName} subtitle={`${b.tour.title} · ${formatLongDate(b.slot.startsAt)} at ${formatTime(b.slot.startsAt)}`}>
        <Status value={b.status} />
        {b.status === 'confirmed' && today && <Link className="btn btn-yellow" to={`/check-in?code=${b.reference}`}>Check in</Link>}
      </PageHead>
      {actionError && <div className="alert err" role="alert">{actionError}</div>}

      <div className="grid grid-main">
        <div className="stack">
          <div className="card">
            <div className="card-head"><h2>Guest</h2></div>
            <div className="card-body">
              <dl className="dl">
                <dt>Name</dt><dd>{b.guestName}</dd>
                <dt>From</dt><dd>{b.guestCountry}</dd>
                <dt>Party</dt><dd>{b.guests} {b.guests === 1 ? 'guest' : 'guests'}</dd>
                <dt>Phone</dt><dd>{maskPhone(b.guestPhone)} <span className="muted small">· call or message through the Cabo app on the day</span></dd>
                <dt>Email</dt><dd>Hidden. Cabo sends booking messages for you.</dd>
              </dl>
              {b.specialRequests && <div className="alert warn" style={{ marginTop: 16, marginBottom: 0 }}><p className="strong">Special request</p><p>{b.specialRequests}</p></div>}
            </div>
          </div>
          <div className="card">
            <div className="card-head"><h2>Booking</h2><span className="mono muted">{b.reference}</span></div>
            <div className="card-body">
              <dl className="dl">
                <dt>Tour</dt><dd><Link to={`/tours/${b.tourId}`}>{b.tour.title}</Link></dd>
                <dt>Date</dt><dd>{formatLongDate(b.slot.startsAt)}, {formatTime(b.slot.startsAt)}</dd>
                <dt>Meeting point</dt><dd>{b.tour.meetingPoint}</dd>
                <dt>Add-ons</dt><dd>{b.addons.length ? b.addons.map((a) => `${a.name} (${naira(a.per === 'person' ? a.price * b.guests : a.price)})`).join(', ') : 'None'}</dd>
                <dt>Cabo ride</dt><dd>{b.rideAddon ? 'Yes. A Cabo driver brings the guest to the meeting point.' : 'No'}</dd>
                <dt>Booked</dt><dd>{formatDateTime(b.createdAt)}</dd>
                {b.checkedInAt && <><dt>Checked in</dt><dd>{formatDateTime(b.checkedInAt)}</dd></>}
                {b.cancelledAt && <><dt>Cancelled</dt><dd>{formatDateTime(b.cancelledAt)} by {b.cancelledBy}{b.cancellationReason ? `: ${b.cancellationReason}` : ''}</dd></>}
                <dt>Policy</dt><dd className="small">{settings().policies[b.tour.cancellationPolicy]}</dd>
              </dl>
            </div>
          </div>
          {b.review && (
            <div className="card">
              <div className="card-head"><h2>Review</h2><Link to="/reviews">Reply</Link></div>
              <div className="card-body"><Stars value={b.review.rating} /><p>{b.review.comment}</p></div>
            </div>
          )}
        </div>

        <div className="stack">
          <div className="card">
            <div className="card-head"><h2>Money</h2></div>
            <div className="card-body">
              <dl className="dl">
                <dt>Tickets</dt><dd>{b.guests} × {naira(b.subtotal / b.guests)} = {naira(b.subtotal)}</dd>
                {b.addonsTotal > 0 && <><dt>Add-ons</dt><dd>{naira(b.addonsTotal)}</dd></>}
                {b.refund > 0 && <><dt>Refunded</dt><dd>−{naira(b.refund)}</dd></>}
                <dt>Cabo commission</dt><dd>−{naira(b.commission)}</dd>
                <dt className="strong">You receive</dt><dd className="strong">{naira(b.net)}</dd>
              </dl>
              <p className="hint">Paid in the weekly payout after the tour date.</p>
            </div>
          </div>
          <div className="card">
            <div className="card-head"><h2>Guest's ticket</h2></div>
            <div className="card-body">
              {qr && <span className="qr-box"><img src={qr} width="180" height="180" alt={`QR ticket for booking ${b.reference}`} /></span>}
              <p className="hint">The guest shows this QR code in the Cabo app. Scan it on the Check-in page, or type the reference {b.reference}.</p>
            </div>
          </div>
          {b.status === 'confirmed' && (
            <div className="card">
              <div className="card-head"><h2>Problems</h2></div>
              <div className="card-body stack-sm">
                {started && <button className="btn btn-ghost btn-block" onClick={async () => { try { setData({ ...b, ...(await markNoShow(b.id)) }); toast('Marked as a no-show.') } catch (e) { setActionError(e.message) } }}>Mark as no-show</button>}
                {!started && <button className="btn btn-danger btn-block" onClick={() => setCancelling(true)}>Cancel this booking</button>}
                <p className="hint">If you cancel, the guest gets a full refund and you are not paid for it. To cancel a whole day, block the date in Availability.</p>
              </div>
            </div>
          )}
        </div>
      </div>

      <Dialog open={cancelling} onClose={() => setCancelling(false)} title="Cancel this booking?" footer={<>
        <button className="btn btn-ghost" onClick={() => setCancelling(false)}>Keep booking</button>
        <button className="btn btn-danger" disabled={!reason.trim()} onClick={async () => {
          try {
            setData({ ...b, ...(await cancelBooking(b.id, reason)) })
            setCancelling(false)
            toast('Booking cancelled. The guest has been refunded in full.')
          } catch (e) { setActionError(e.message); setCancelling(false) }
        }}>Cancel and refund {naira(b.gross)}</button>
      </>}>
        <p>{b.guestName} will get a full refund of {naira(b.gross)} and a message with your reason.</p>
        <Field label="Reason for the guest" name="reason"><textarea id="reason" value={reason} onChange={(e) => setReason(e.target.value)} placeholder="e.g. The boat operator has cancelled all trips because of rough seas." /></Field>
      </Dialog>
    </>
  )
}
