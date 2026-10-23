import { lazy, Suspense } from 'react'
import { BrowserRouter, Navigate, Route, Routes, useLocation } from 'react-router-dom'
import { AuthProvider, useAuth } from './auth/AuthContext'
import Layout from './components/Layout'
import { ToastProvider } from './components/Toasts'
import { Loading } from './components/ui'
import Apply from './pages/Apply'
import ForgotPassword from './pages/ForgotPassword'
import SignIn from './pages/SignIn'

const Dashboard = lazy(() => import('./pages/Dashboard'))
const Application = lazy(() => import('./pages/Application'))
const Tours = lazy(() => import('./pages/Tours'))
const TourEditor = lazy(() => import('./pages/TourEditor'))
const Availability = lazy(() => import('./pages/Availability'))
const Bookings = lazy(() => import('./pages/Bookings'))
const BookingDetail = lazy(() => import('./pages/BookingDetail'))
const CheckIn = lazy(() => import('./pages/CheckIn'))
const Earnings = lazy(() => import('./pages/Earnings'))
const Reviews = lazy(() => import('./pages/Reviews'))
const Tickets = lazy(() => import('./pages/Tickets'))
const Concierge = lazy(() => import('./pages/Concierge'))
const Notifications = lazy(() => import('./pages/Notifications'))
const Settings = lazy(() => import('./pages/Settings'))
const NotFound = lazy(() => import('./pages/NotFound'))

const TOURS = ['tour_operator', 'guide']

function RequireAuth({ children }) {
  const { loading, account } = useAuth()
  const location = useLocation()
  if (loading) return <Loading />
  if (!account) return <Navigate to="/login" replace state={{ from: location.pathname + location.search }} />
  return children
}

/** Sends partners to the right page for their status and type. */
function Gate({ approved, types, children }) {
  const { partner } = useAuth().account
  if (approved && partner.status !== 'approved') return <Navigate to="/application" replace />
  if (types && !types.includes(partner.type)) return <Navigate to="/" replace />
  return children
}

/** Sign-in pages. Once signed in, go back to the page that asked for sign-in. */
function GuestOnly({ children }) {
  const { loading, account } = useAuth()
  const location = useLocation()
  if (loading) return <Loading />
  return account ? <Navigate to={location.state?.from || '/'} replace /> : children
}

export function AppRoutes() {
  return (
    <Suspense fallback={<Loading />}>
      <Routes>
        <Route path="/login" element={<GuestOnly><SignIn /></GuestOnly>} />
        <Route path="/apply" element={<GuestOnly><Apply /></GuestOnly>} />
        <Route path="/forgot-password" element={<GuestOnly><ForgotPassword /></GuestOnly>} />
        <Route element={<RequireAuth><Layout /></RequireAuth>}>
          <Route index element={<Gate approved><Dashboard /></Gate>} />
          <Route path="application" element={<Application />} />
          <Route path="tours" element={<Gate types={TOURS}><Tours /></Gate>} />
          <Route path="tours/new" element={<Gate types={TOURS}><TourEditor /></Gate>} />
          <Route path="tours/:id" element={<Gate types={TOURS}><TourEditor /></Gate>} />
          <Route path="availability" element={<Gate approved types={TOURS}><Availability /></Gate>} />
          <Route path="bookings" element={<Gate approved types={TOURS}><Bookings /></Gate>} />
          <Route path="bookings/:id" element={<Gate approved types={TOURS}><BookingDetail /></Gate>} />
          <Route path="check-in" element={<Gate approved types={[...TOURS, 'attraction']}><CheckIn /></Gate>} />
          <Route path="reviews" element={<Gate approved types={TOURS}><Reviews /></Gate>} />
          <Route path="tickets" element={<Gate approved types={['attraction']}><Tickets /></Gate>} />
          <Route path="concierge" element={<Gate approved types={['hotel']}><Concierge /></Gate>} />
          <Route path="earnings" element={<Gate approved types={[...TOURS, 'attraction']}><Earnings /></Gate>} />
          <Route path="notifications" element={<Notifications />} />
          <Route path="settings" element={<Navigate to="/settings/business" replace />} />
          <Route path="settings/:tab" element={<Settings />} />
          <Route path="*" element={<NotFound />} />
        </Route>
      </Routes>
    </Suspense>
  )
}

export default function App() {
  return (
    <BrowserRouter>
      <AuthProvider>
        <ToastProvider>
          <AppRoutes />
        </ToastProvider>
      </AuthProvider>
    </BrowserRouter>
  )
}
