import { useEffect, useState } from 'react'
import { Link, useNavigate, useParams } from 'react-router-dom'
import { deleteTour, getTour, saveTour, setTourPaused, tourProblems } from '../api/portal'
import { settings } from '../api/store'
import { useAuth } from '../auth/AuthContext'
import Icon from '../components/Icon'
import { useToast } from '../components/Toasts'
import { Dialog, Field, FormMessage, ListEditor, Loading, LoadError, PageHead, Status } from '../components/ui'
import { formatDateTime, naira } from '../lib/format'
import { useForm, useTitle } from '../lib/hooks'
import { resizeImage } from '../lib/images'

const MAX_PHOTOS = 8

const EMPTY = {
  title: '', category: '', area: '', description: '', durationMinutes: 180, price: '', minGroup: 1, maxGroup: 10, languages: ['English'],
  meetingPoint: '', meetingLat: '', meetingLng: '', itinerary: [''], inclusions: [''], exclusions: [], addons: [],
  cancellationPolicy: 'flexible', photos: [], guideIds: [], wheelchairAccessible: false,
}

export default function TourEditor() {
  const { id } = useParams()
  const isNew = !id
  const navigate = useNavigate()
  const toast = useToast()
  const { partner } = useAuth().account
  const [tour, setTour] = useState(isNew ? null : undefined)
  const [loadError, setLoadError] = useState(null)
  const form = useForm(EMPTY)
  const [photoError, setPhotoError] = useState(null)
  const [confirmDelete, setConfirmDelete] = useState(false)
  useTitle(isNew ? 'New tour' : tour?.title || 'Tour')
  const { categories: CATEGORIES, languages: LANGUAGES, policies: POLICIES } = settings()

  useEffect(() => {
    if (isNew) return
    getTour(id).then(
      (t) => {
        setTour(t)
        form.setValues({ ...EMPTY, ...t, meetingLat: t.meetingLat ?? '', meetingLng: t.meetingLng ?? '', itinerary: t.itinerary.length ? t.itinerary : [''], inclusions: t.inclusions.length ? t.inclusions : [''] })
      },
      setLoadError,
    )
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [id])

  if (loadError) return <LoadError error={loadError} />
  if (tour === undefined) return <Loading />

  const v = form.values
  const e = form.errors
  const approved = partner.status === 'approved'
  const isLive = tour && ['live', 'paused'].includes(tour.status)
  const missing = Object.values(tourProblems({ ...v, price: Number(v.price), durationMinutes: Number(v.durationMinutes), minGroup: Number(v.minGroup), maxGroup: Number(v.maxGroup) }))

  async function save(submit) {
    try {
      const saved = await form.submit((values) => saveTour({ ...values, id: tour?.id }, { submit }))
      setTour(saved)
      toast(submit ? (isLive ? 'Changes sent to Cabo for review. The current version stays bookable.' : 'Sent to Cabo for review.') : 'Tour saved.')
      if (isNew) navigate(`/tours/${saved.id}`, { replace: true })
    } catch (error) {
      const first = Object.keys(error.fields || {})[0]
      if (first) document.getElementById(first)?.focus()
      else window.scrollTo(0, 0)
    }
  }

  async function addPhotos(files) {
    setPhotoError(null)
    const room = MAX_PHOTOS - v.photos.length
    const added = []
    for (const file of [...files].slice(0, room)) {
      try {
        added.push(await resizeImage(file))
      } catch (err) {
        setPhotoError(`${file.name}: ${err.message}`)
      }
    }
    if (files.length > room) setPhotoError(`You can add up to ${MAX_PHOTOS} photos.`)
    form.set('photos', [...v.photos, ...added])
  }

  const movePhotoFirst = (i) => form.set('photos', [v.photos[i], ...v.photos.filter((_, j) => j !== i)])

  return (
    <>
      <PageHead
        crumbs={<><Link to="/tours">Tours</Link> / {isNew ? 'New tour' : tour.title}</>}
        title={isNew ? 'New tour' : tour.title}
        subtitle={tour ? `Last saved ${formatDateTime(tour.updatedAt)}` : 'Fill in what you can. Save as a draft at any time.'}
      >
        {tour && <Status value={tour.status} />}
        {tour?.changesInReview && <Status value="in_review" label="Changes in review" />}
      </PageHead>

      {tour?.status === 'changes_requested' && tour.reviewNote && (
        <div className="alert warn"><p className="strong">Cabo asked for changes</p><p>{tour.reviewNote}</p></div>
      )}
      {tour?.status === 'in_review' && <div className="alert info">Cabo is reviewing this tour. You can still make changes; they will be included in the review.</div>}
      <FormMessage message={form.message} />

      <form className="grid grid-main" onSubmit={(ev) => { ev.preventDefault(); save(false) }} noValidate>
        <div className="stack">
          <section className="card" aria-labelledby="basics">
            <div className="card-head"><h2 id="basics">Basics</h2></div>
            <div className="card-body form-grid">
              <div className="full"><Field label="Title" name="title" error={e.title} hint="What guests see first, e.g. “Lekki Conservation Centre canopy walk”."><input type="text" maxLength={80} {...form.bind('title')} /></Field></div>
              <Field label="Category" name="category" error={e.category}>
                <select {...form.bind('category')}><option value="">Choose…</option>{CATEGORIES.map((c) => <option key={c}>{c}</option>)}</select>
              </Field>
              <Field label="Area" name="area" error={e.area}><input type="text" placeholder="e.g. Lekki" {...form.bind('area')} /></Field>
              <div className="full"><Field label="Description" name="description" error={e.description} hint={`${v.description.length}/2000 characters`}><textarea maxLength={2000} {...form.bind('description')} /></Field></div>
              <Field label="Duration (hours)" name="durationMinutes" error={e.durationMinutes}>
                <input id="durationMinutes" type="number" min="0.5" max="24" step="0.5" value={v.durationMinutes ? v.durationMinutes / 60 : ''} onChange={(ev) => form.set('durationMinutes', Math.round(Number(ev.target.value) * 60))} aria-invalid={e.durationMinutes ? true : undefined} />
              </Field>
              <div className="field">
                <label className="check" style={{ marginTop: 30 }}><input type="checkbox" checked={v.wheelchairAccessible} onChange={(ev) => form.set('wheelchairAccessible', ev.target.checked)} /> Wheelchair accessible</label>
              </div>
              <div className="full field">
                <span className="label" id="languages-label">Languages the tour is given in</span>
                <div className="choices" role="group" aria-labelledby="languages-label" id="languages">
                  {LANGUAGES.map((l) => (
                    <label className="chip" key={l}><input type="checkbox" checked={v.languages.includes(l)} onChange={(ev) => form.set('languages', ev.target.checked ? [...v.languages, l] : v.languages.filter((x) => x !== l))} /> {l}</label>
                  ))}
                </div>
                {e.languages && <div className="error">{e.languages}</div>}
              </div>
            </div>
          </section>

          <section className="card" aria-labelledby="photos-title">
            <div className="card-head"><h2 id="photos-title">Photos</h2><span className="muted small">{v.photos.length}/{MAX_PHOTOS} · the first photo is the cover</span></div>
            <div className="card-body">
              <div className="photo-grid" id="photos" tabIndex={-1}>
                {v.photos.map((src, i) => (
                  <div className="photo-tile" key={i}>
                    <img src={src} alt={`Tour photo ${i + 1}`} />
                    {i === 0 ? <span className="badge green plain cover">Cover</span> : <button type="button" className="btn btn-ghost btn-sm cover" onClick={() => movePhotoFirst(i)}>Make cover</button>}
                    <button type="button" className="icon-button remove" aria-label={`Remove photo ${i + 1}`} onClick={() => form.set('photos', v.photos.filter((_, j) => j !== i))}><Icon name="x" /></button>
                  </div>
                ))}
                {v.photos.length < MAX_PHOTOS && (
                  <label className="upload-tile">
                    <input type="file" accept="image/jpeg,image/png,image/webp" multiple onChange={(ev) => { addPhotos(ev.target.files); ev.target.value = '' }} />
                    <span><Icon name="upload" /><br />Add photos<br /><span className="small">JPG or PNG, at least 800 px wide</span></span>
                  </label>
                )}
              </div>
              {(photoError || e.photos) && <div className="error">{photoError || e.photos}</div>}
              <p className="hint">Use your own photos of the real experience. Guests trust photos with people enjoying the tour.</p>
            </div>
          </section>

          <section className="card" aria-labelledby="itinerary-title">
            <div className="card-head"><h2 id="itinerary-title">Itinerary</h2></div>
            <div className="card-body">
              <ListEditor id="itinerary" numbered items={v.itinerary} onChange={(x) => form.set('itinerary', x)} placeholder="Step" addLabel="Add step" error={e.itinerary} />
              {e.itinerary && <div className="error">{e.itinerary}</div>}
            </div>
          </section>

          <section className="card" aria-labelledby="included-title">
            <div className="card-head"><h2 id="included-title">What's included</h2></div>
            <div className="card-body grid grid-2">
              <div>
                <h3 style={{ marginBottom: 8 }}>Included</h3>
                <ListEditor id="inclusions" items={v.inclusions} onChange={(x) => form.set('inclusions', x)} placeholder="Included item" addLabel="Add item" error={e.inclusions} />
                {e.inclusions && <div className="error">{e.inclusions}</div>}
              </div>
              <div>
                <h3 style={{ marginBottom: 8 }}>Not included</h3>
                <ListEditor id="exclusions" items={v.exclusions} onChange={(x) => form.set('exclusions', x)} placeholder="Not included" addLabel="Add item" />
              </div>
            </div>
          </section>

          <section className="card" aria-labelledby="pricing-title">
            <div className="card-head"><h2 id="pricing-title">Price, group size and add-ons</h2></div>
            <div className="card-body">
              <div className="form-grid">
                <Field label="Price per person (₦)" name="price" error={e.price} hint={Number(v.price) > 0 ? `You receive ${naira(Number(v.price) * (1 - partner.commissionRate / 100))} after Cabo's ${partner.commissionRate}% commission.` : undefined}>
                  <input type="number" min="0" step="500" inputMode="numeric" {...form.bind('price')} />
                </Field>
                <div className="form-grid" style={{ gap: '0 12px' }}>
                  <Field label="Minimum group" name="minGroup" error={e.minGroup}><input type="number" min="1" max="50" {...form.bind('minGroup')} /></Field>
                  <Field label="Maximum group" name="maxGroup" error={e.maxGroup}><input type="number" min="1" max="200" {...form.bind('maxGroup')} /></Field>
                </div>
              </div>
              <h3 style={{ margin: '4px 0 8px' }}>Add-ons</h3>
              <p className="hint" style={{ marginTop: 0 }}>Extras guests can buy with the booking, such as a photographer, meals or a private upgrade. Cabo adds the “ride to the meeting point” add-on itself.</p>
              {v.addons.map((a, i) => (
                <div className="row" key={a.id || i} style={{ marginBottom: 8, alignItems: 'flex-end' }}>
                  <div style={{ flex: '2 1 200px' }}><label htmlFor={`addon-name-${i}`} className="small">Add-on</label><input id={`addon-name-${i}`} type="text" value={a.name} onChange={(ev) => form.set('addons', v.addons.map((x, j) => (j === i ? { ...x, name: ev.target.value } : x)))} /></div>
                  <div style={{ flex: '1 1 110px' }}><label htmlFor={`addon-price-${i}`} className="small">Price (₦)</label><input id={`addon-price-${i}`} type="number" min="0" step="500" value={a.price} onChange={(ev) => form.set('addons', v.addons.map((x, j) => (j === i ? { ...x, price: ev.target.value } : x)))} /></div>
                  <div style={{ flex: '1 1 130px' }}><label htmlFor={`addon-per-${i}`} className="small">Charged</label>
                    <select id={`addon-per-${i}`} value={a.per} onChange={(ev) => form.set('addons', v.addons.map((x, j) => (j === i ? { ...x, per: ev.target.value } : x)))}><option value="booking">Per booking</option><option value="person">Per person</option></select>
                  </div>
                  <button type="button" className="icon-button" aria-label={`Remove add-on ${a.name || i + 1}`} onClick={() => form.set('addons', v.addons.filter((_, j) => j !== i))}><Icon name="x" /></button>
                </div>
              ))}
              <button type="button" className="btn btn-ghost btn-sm" onClick={() => form.set('addons', [...v.addons, { name: '', price: '', per: 'booking' }])}><Icon name="plus" size={16} /> Add an add-on</button>
            </div>
          </section>

          <section className="card" aria-labelledby="meeting-title">
            <div className="card-head"><h2 id="meeting-title">Meeting point</h2></div>
            <div className="card-body form-grid">
              <div className="full"><Field label="Where guests meet you" name="meetingPoint" error={e.meetingPoint} hint="Be specific: the gate, sign or landmark. Cabo rides drop guests here."><input type="text" {...form.bind('meetingPoint')} /></Field></div>
              <Field label="Latitude" name="meetingLat" optional><input type="text" inputMode="decimal" placeholder="6.4413" {...form.bind('meetingLat')} /></Field>
              <Field label="Longitude" name="meetingLng" optional hint={v.meetingLat && v.meetingLng ? <a href={`https://maps.google.com/?q=${v.meetingLat},${v.meetingLng}`} target="_blank" rel="noreferrer">Check on Google Maps</a> : 'From Google Maps: right-click the spot and copy the numbers.'}><input type="text" inputMode="decimal" placeholder="3.5357" {...form.bind('meetingLng')} /></Field>
            </div>
          </section>

          <section className="card" aria-labelledby="guides-title">
            <div className="card-head"><h2 id="guides-title">Guides</h2><Link to="/settings/guides">Manage guides</Link></div>
            <div className="card-body">
              {partner.guides.length === 0 ? <p className="muted">Add guides under Settings first.</p> : (
                <div className="choices" role="group" aria-labelledby="guides-title">
                  {partner.guides.map((g) => (
                    <label className="chip" key={g.id}><input type="checkbox" checked={v.guideIds.includes(g.id)} onChange={(ev) => form.set('guideIds', ev.target.checked ? [...v.guideIds, g.id] : v.guideIds.filter((x) => x !== g.id))} /> {g.name} <span className="muted small">({g.languages.join(', ')})</span></label>
                  ))}
                </div>
              )}
              <p className="hint">Guests see the guide's name, languages and bio on the tour page.</p>
            </div>
          </section>

          <section className="card" aria-labelledby="policy-title">
            <div className="card-head"><h2 id="policy-title">Cancellation policy</h2></div>
            <div className="card-body stack-sm" role="radiogroup" aria-labelledby="policy-title">
              {Object.entries(POLICIES).map(([key, text]) => (
                <label className="option-card" key={key}>
                  <input type="radio" name="cancellationPolicy" value={key} checked={v.cancellationPolicy === key} onChange={() => form.set('cancellationPolicy', key)} />
                  <span><span className="strong">{key.charAt(0).toUpperCase() + key.slice(1)}</span><br /><span className="muted small">{text}</span></span>
                </label>
              ))}
              <p className="hint">Cabo refunds guests automatically under this policy. If you cancel, guests always get a full refund.</p>
            </div>
          </section>
        </div>

        <aside className="stack">
          <div className="card" style={{ position: 'sticky', top: 80 }}>
            <div className="card-head"><h2>Publish</h2>{tour && <Status value={tour.status} />}</div>
            <div className="card-body stack-sm">
              {missing.length > 0 ? (
                <>
                  <p className="small strong">Before sending for review:</p>
                  <ul className="small" style={{ margin: 0, paddingLeft: 18 }}>{missing.map((m) => <li key={m}>{m}</li>)}</ul>
                </>
              ) : <p className="small">Everything Cabo needs is filled in.</p>}
              <button type="button" className="btn btn-primary btn-block" disabled={form.busy || !approved} onClick={() => save(true)}>
                {isLive ? 'Send changes for review' : tour?.status === 'in_review' ? 'Update review' : 'Send for review'}
              </button>
              {!approved && <p className="hint">Available once your application is approved.</p>}
              <button type="submit" className="btn btn-ghost btn-block" disabled={form.busy}>{isLive ? 'Save without sending' : 'Save draft'}</button>
              {isLive && (
                <button type="button" className="btn btn-ghost btn-block" onClick={async () => {
                  const t = await setTourPaused(tour.id, tour.status === 'live')
                  setTour(t)
                  toast(t.status === 'paused' ? 'Tour paused. Guests cannot book it until you resume.' : 'Tour is bookable again.')
                }}>{tour.status === 'live' ? 'Pause bookings' : 'Resume bookings'}</button>
              )}
              {isLive && <Link className="btn btn-ghost btn-block" to={`/availability?tour=${tour.id}`}><Icon name="calendar" size={16} /> Manage availability</Link>}
              {tour && !isLive && <button type="button" className="btn btn-danger btn-block" onClick={() => setConfirmDelete(true)}>Delete tour</button>}
            </div>
          </div>
        </aside>
      </form>

      <Dialog open={confirmDelete} onClose={() => setConfirmDelete(false)} title="Delete this tour?" footer={<>
        <button className="btn btn-ghost" onClick={() => setConfirmDelete(false)}>Keep it</button>
        <button className="btn btn-danger" onClick={async () => {
          try {
            await deleteTour(tour.id)
            toast('Tour deleted.')
            navigate('/tours')
          } catch (err) {
            setConfirmDelete(false)
            form.setMessage(err.message)
          }
        }}>Delete tour</button>
      </>}>
        <p>{tour?.title} will be removed. This cannot be undone.</p>
      </Dialog>
    </>
  )
}
