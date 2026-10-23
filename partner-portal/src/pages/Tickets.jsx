import { useState } from 'react'
import { listTicketSales, listTicketTypes, saveTicketType, setTicketPaused } from '../api/portal'
import Icon from '../components/Icon'
import { useToast } from '../components/Toasts'
import { Dialog, Empty, Field, FormMessage, Loading, LoadError, PageHead, Status } from '../components/ui'
import { formatDate, lagosDate, naira } from '../lib/format'
import { useAsync, useForm, useTitle } from '../lib/hooks'

/** P-08: attractions and venues list tickets for sale. */
export default function Tickets() {
  useTitle('Tickets')
  const toast = useToast()
  const types = useAsync(listTicketTypes, [])
  const [date, setDate] = useState(lagosDate())
  const [q, setQ] = useState('')
  const sales = useAsync(() => listTicketSales({ date, q }), [date, q])
  const [editing, setEditing] = useState(null)

  return (
    <>
      <PageHead title="Tickets" subtitle="Entry tickets sold in the Cabo app. New tickets and price changes go live after Cabo reviews them.">
        <button className="btn btn-primary" onClick={() => setEditing({})}><Icon name="plus" size={16} /> New ticket</button>
      </PageHead>
      {types.error && <LoadError error={types.error} retry={types.reload} />}
      <div className="card">
        <div className="card-head"><h2>Ticket types</h2></div>
        {types.loading && !types.data ? <Loading /> : types.data?.length === 0 ? <Empty>No tickets yet.</Empty> : (
          <div className="table-wrap"><table>
            <thead><tr><th>Ticket</th><th className="right">Price</th><th className="right">Daily limit</th><th className="right">Sold today</th><th className="right">Last 30 days</th><th>Status</th><th /></tr></thead>
            <tbody>{types.data?.map((t) => (
              <tr key={t.id}>
                <td><span className="strong">{t.name}</span><div className="muted small">{t.description} · {t.validFor}</div></td>
                <td className="right">{naira(t.price)}</td>
                <td className="right">{t.dailyCapacity}</td>
                <td className="right">{t.soldToday}</td>
                <td className="right">{t.sold30}</td>
                <td><Status value={t.status} />{t.changesInReview && <div><Status value="in_review" label="Price change in review" /></div>}</td>
                <td className="nowrap right">
                  <button className="btn btn-ghost btn-sm" onClick={() => setEditing(t)}>Edit</button>{' '}
                  {['live', 'paused'].includes(t.status) && <button className="btn btn-ghost btn-sm" onClick={async () => { await setTicketPaused(t.id, t.status === 'live'); types.reload(); toast(t.status === 'live' ? 'Sales paused.' : 'Sales resumed.') }}>{t.status === 'live' ? 'Pause' : 'Resume'}</button>}
                </td>
              </tr>
            ))}</tbody>
          </table></div>
        )}
      </div>

      <div className="card" style={{ marginTop: 16 }}>
        <div className="card-head"><h2>Sales</h2></div>
        <div className="filters">
          <label className="visually-hidden" htmlFor="sales-date">Visit date</label>
          <input id="sales-date" type="date" value={date} onChange={(e) => setDate(e.target.value)} />
          <label className="visually-hidden" htmlFor="sales-q">Search sales</label>
          <input id="sales-q" type="search" placeholder="Buyer or reference" value={q} onChange={(e) => setQ(e.target.value)} />
          {date && <button className="btn-link" onClick={() => setDate('')}>All dates</button>}
        </div>
        {sales.data?.length === 0 ? <Empty>No tickets sold for this date.</Empty> : (
          <div className="table-wrap"><table>
            <thead><tr><th>Visit date</th><th>Buyer</th><th>Ticket</th><th className="right">Qty</th><th className="right">You receive</th><th>Status</th></tr></thead>
            <tbody>{sales.data?.map((s) => (
              <tr key={s.id}>
                <td className="nowrap">{formatDate(s.visitDate)}</td>
                <td><span className="strong">{s.buyerName}</span><div className="muted small"><span className="mono">{s.reference}</span> · {s.buyerCountry}</div></td>
                <td>{s.type.name}</td>
                <td className="right">{s.quantity}</td>
                <td className="right">{naira(s.net)}</td>
                <td><Status value={s.status} /></td>
              </tr>
            ))}</tbody>
          </table></div>
        )}
        {sales.data?.length > 0 && <div className="card-foot small muted">{sales.data.reduce((n, s) => n + s.quantity, 0)} tickets · {naira(sales.data.reduce((n, s) => n + s.net, 0))} to you after commission</div>}
      </div>

      {editing && <TicketDialog ticket={editing} onClose={() => setEditing(null)} onSaved={(t) => { setEditing(null); types.reload(); toast(editing.id ? 'Ticket saved.' : `${t.name} sent to Cabo for review.`) }} />}
    </>
  )
}

function TicketDialog({ ticket, onClose, onSaved }) {
  const form = useForm({ id: ticket.id, name: ticket.name || '', description: ticket.description || '', price: ticket.price || '', dailyCapacity: ticket.dailyCapacity || 100, validFor: ticket.validFor || 'Any one day' })
  const save = async () => {
    try { onSaved(await form.submit(saveTicketType)) } catch { /* shown */ }
  }
  return (
    <Dialog open onClose={onClose} title={ticket.id ? 'Edit ticket' : 'New ticket'} footer={<><button className="btn btn-ghost" onClick={onClose}>Cancel</button><button className="btn btn-primary" onClick={save} disabled={form.busy}>{ticket.id ? 'Save' : 'Send for review'}</button></>}>
      <FormMessage message={form.message} />
      <Field label="Name" name="name" error={form.errors.name}><input type="text" placeholder="e.g. Adult entry" {...form.bind('name')} /></Field>
      <Field label="What it includes" name="description" optional><input type="text" {...form.bind('description')} /></Field>
      <div className="form-grid">
        <Field label="Price (₦)" name="price" error={form.errors.price} hint={ticket.status === 'live' ? 'Price changes go live after Cabo review.' : undefined}><input type="number" min="0" step="100" {...form.bind('price')} /></Field>
        <Field label="Tickets per day" name="dailyCapacity" error={form.errors.dailyCapacity}><input type="number" min="1" {...form.bind('dailyCapacity')} /></Field>
      </div>
      <Field label="Valid for" name="validFor"><input type="text" placeholder="Any one day" {...form.bind('validFor')} /></Field>
    </Dialog>
  )
}
