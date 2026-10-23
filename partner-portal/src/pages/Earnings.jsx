import { useState } from 'react'
import { Link } from 'react-router-dom'
import { earnings, toCsv } from '../api/portal'
import Icon from '../components/Icon'
import { Empty, Loading, LoadError, PageHead, Status } from '../components/ui'
import { formatDate, formatLongDate, humanize, naira } from '../lib/format'
import { download, useAsync, useTitle } from '../lib/hooks'

const monthLabel = (key) => new Date(`${key}-15T12:00:00Z`).toLocaleDateString('en-GB', { month: 'short' })

/** P-06: earnings, commission and payout history. */
export default function Earnings() {
  useTitle('Earnings')
  const { data, loading, error, reload } = useAsync(earnings, [])
  const [tab, setTab] = useState('payouts')
  if (error) return <LoadError error={error} retry={reload} />
  if (loading && !data) return <Loading />
  const max = Math.max(1, ...data.months.map((m) => m.net))

  function exportItems() {
    download('cabo-earnings.csv', toCsv(data.items, [
      { label: 'Date', value: 'date' }, { label: 'Reference', value: 'reference' }, { label: 'Type', value: 'kind' },
      { label: 'Item', value: 'title' }, { label: 'Guest', value: 'guest' }, { label: 'Status', value: 'status' },
      { label: 'Gross (NGN)', value: 'gross' }, { label: 'Commission (NGN)', value: 'commission' }, { label: 'Net (NGN)', value: 'net' },
    ]))
  }
  function exportPayouts() {
    download('cabo-payouts.csv', toCsv(data.payouts, [
      { label: 'Reference', value: 'reference' }, { label: 'Period start', value: 'periodStart' }, { label: 'Period end', value: 'periodEnd' },
      { label: 'Bookings', value: 'bookings' }, { label: 'Gross (NGN)', value: 'gross' }, { label: 'Commission (NGN)', value: 'commission' },
      { label: 'Paid (NGN)', value: 'amount' }, { label: 'Status', value: 'status' }, { label: 'Paid on', value: (p) => p.paidAt?.slice(0, 10) },
    ]))
  }

  return (
    <>
      <PageHead title="Earnings" subtitle={`Cabo keeps ${data.commissionRate}% commission. Each Tuesday we pay the previous week's completed bookings to your bank account.`}>
        <button className="btn btn-ghost" onClick={tab === 'payouts' ? exportPayouts : exportItems}><Icon name="download" size={16} /> Export CSV</button>
      </PageHead>
      <div className="grid grid-4">
        <div className="card kpi accent"><div className="label">Next payout</div><div className="value">{naira(data.totals.unpaid + data.totals.processing)}</div><div className="hint">{formatLongDate(data.nextPayout)}</div></div>
        <div className="card kpi"><div className="label">Booked, not yet happened</div><div className="value">{naira(data.totals.upcoming)}</div><div className="hint">Paid after each tour date</div></div>
        <div className="card kpi"><div className="label">Paid to you so far</div><div className="value">{naira(data.totals.paid)}</div><div className="hint">{data.payouts.filter((p) => p.status === 'paid').length} payouts</div></div>
        <div className="card kpi"><div className="label">Commission this year</div><div className="value">{naira(data.totals.commissionYear)}</div><div className="hint">{data.commissionRate}% of bookings</div></div>
      </div>

      <div className="grid grid-main" style={{ marginTop: 16 }}>
        <div className="card">
          <div className="card-head"><h2>Your earnings by month</h2><span className="muted small">After commission</span></div>
          <div className="card-body">
            <div className="bars" role="img" aria-label={`Monthly earnings: ${data.months.map((m) => `${monthLabel(m.month)} ${naira(m.net)}`).join(', ')}`}>
              {data.months.map((m, i) => (
                <div className={`bar${i === data.months.length - 1 ? ' current' : ''}`} key={m.month}>
                  <small>{m.net ? `₦${Math.round(m.net / 1000)}k` : '—'}</small>
                  <span style={{ height: `${Math.round((m.net / max) * 100)}%` }} />
                  <small>{monthLabel(m.month)}</small>
                </div>
              ))}
            </div>
          </div>
        </div>
        <div className="card">
          <div className="card-head"><h2>Paid to</h2><Link to="/settings/bank">Change</Link></div>
          <div className="card-body">
            {data.bank.accountNumber ? (
              <dl className="dl"><dt>Bank</dt><dd>{data.bank.name}</dd><dt>Account</dt><dd className="mono">••••{data.bank.accountNumber.slice(-4)}</dd><dt>Name</dt><dd>{data.bank.accountName}</dd></dl>
            ) : <p>Add your bank details to get paid. <Link to="/settings/bank">Add bank details</Link></p>}
          </div>
        </div>
      </div>

      <div className="card" style={{ marginTop: 16 }}>
        <div className="filters">
          <nav className="tabs" aria-label="Earnings detail">
            <button type="button" aria-selected={tab === 'payouts'} onClick={() => setTab('payouts')}>Payouts</button>
            <button type="button" aria-selected={tab === 'items'} onClick={() => setTab('items')}>Bookings and tickets</button>
          </nav>
        </div>
        {tab === 'payouts' && (data.payouts.length === 0 ? <Empty>No payouts yet. Your first payout is on the Tuesday after your first completed booking.</Empty> : (
          <div className="table-wrap"><table>
            <thead><tr><th>Week</th><th>Reference</th><th className="right">Bookings</th><th className="right">Gross</th><th className="right">Commission</th><th className="right">Paid to you</th><th>Status</th></tr></thead>
            <tbody>{data.payouts.map((p) => (
              <tr key={p.id}>
                <td className="nowrap">{formatDate(p.periodStart)} – {formatDate(p.periodEnd)}</td>
                <td className="mono">{p.reference}</td>
                <td className="right">{p.bookings}</td>
                <td className="right">{naira(p.gross)}</td>
                <td className="right">−{naira(p.commission)}</td>
                <td className="right strong">{naira(p.amount)}</td>
                <td><Status value={p.status} />{p.paidAt && <div className="muted small">{formatDate(p.paidAt)} · {p.bankName}</div>}</td>
              </tr>
            ))}</tbody>
          </table></div>
        ))}
        {tab === 'items' && (
          <div className="table-wrap"><table>
            <thead><tr><th>Date</th><th>Item</th><th>Guest</th><th className="right">Gross</th><th className="right">Commission</th><th className="right">You receive</th><th>Status</th></tr></thead>
            <tbody>{data.items.slice(0, 100).map((i) => (
              <tr key={i.id}>
                <td className="nowrap">{formatDate(i.date)}</td>
                <td>{i.kind === 'tour' ? <Link to={`/bookings/${i.id}`}>{i.title}</Link> : i.title}<div className="muted small mono">{i.reference}</div></td>
                <td>{i.guest}</td>
                <td className="right">{naira(i.gross)}</td>
                <td className="right">−{naira(i.commission)}</td>
                <td className="right strong">{naira(i.net)}</td>
                <td><Status value={i.status} label={humanize(i.status)} /></td>
              </tr>
            ))}</tbody>
          </table></div>
        )}
      </div>
    </>
  )
}
