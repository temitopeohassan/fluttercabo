import { render, screen, within } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { MemoryRouter } from 'react-router-dom'
import { describe, expect, it } from 'vitest'
import { AppRoutes } from '../App'
import { DEMO_PASSWORD, signIn } from '../api/auth'
import { AuthProvider } from '../auth/AuthContext'
import { ToastProvider } from '../components/Toasts'

function renderAt(path) {
  return render(
    <MemoryRouter initialEntries={[path]}>
      <AuthProvider>
        <ToastProvider>
          <AppRoutes />
        </ToastProvider>
      </AuthProvider>
    </MemoryRouter>,
  )
}

describe('the portal', () => {
  it('sends signed-out visitors to sign in, then on to the dashboard', async () => {
    const user = userEvent.setup()
    renderAt('/bookings')
    await screen.findByRole('heading', { name: 'Partner portal' })
    await user.type(screen.getByLabelText('Email'), 'adaeze@ekonaturetrails.ng')
    await user.type(screen.getByLabelText('Password'), DEMO_PASSWORD)
    await user.click(screen.getByRole('button', { name: 'Sign in' }))
    expect(await screen.findByRole('heading', { name: 'Bookings' }, { timeout: 5000 })).toBeInTheDocument()
  })

  it('shows an error for a wrong password', async () => {
    const user = userEvent.setup()
    renderAt('/login')
    await user.type(await screen.findByLabelText('Email'), 'adaeze@ekonaturetrails.ng')
    await user.type(screen.getByLabelText('Password'), 'wrong-password')
    await user.click(screen.getByRole('button', { name: 'Sign in' }))
    expect(await screen.findByRole('alert')).toHaveTextContent('do not match')
  })

  it('fills the form from a demo account', async () => {
    const user = userEvent.setup()
    renderAt('/login')
    await user.click(await screen.findByRole('button', { name: /Lekki Arts Hub/ }))
    expect(screen.getByLabelText('Email')).toHaveValue('ifeoma@lekkiartshub.ng')
  })

  it('keeps a pending partner on their application page', async () => {
    await signIn({ email: 'kunle@badagryroots.ng', password: DEMO_PASSWORD })
    renderAt('/bookings')
    expect(await screen.findByRole('heading', { name: 'Your application' })).toBeInTheDocument()
    const nav = screen.getByRole('complementary', { name: 'Portal navigation' })
    expect(within(nav).queryByRole('link', { name: /Bookings/ })).toBeNull()
    expect(within(nav).getByRole('link', { name: /Tours/ })).toBeInTheDocument()
  })

  it('shows each partner type its own tools', async () => {
    await signIn({ email: 'bisi@lagoonhouse.ng', password: DEMO_PASSWORD })
    renderAt('/tours')
    expect(await screen.findByRole('heading', { name: /Good (morning|afternoon|evening), Bisi/ })).toBeInTheDocument()
    const nav = screen.getByRole('complementary', { name: 'Portal navigation' })
    expect(within(nav).getByRole('link', { name: /Concierge/ })).toBeInTheDocument()
    expect(within(nav).queryByRole('link', { name: /Tours/ })).toBeNull()
  })

  it('walks through the partner application', async () => {
    const user = userEvent.setup()
    renderAt('/apply')
    await screen.findByRole('heading', { name: 'Apply to become a Cabo partner' })
    await user.click(screen.getByRole('button', { name: 'Continue' }))
    expect(await screen.findByText('Enter your business name.')).toBeInTheDocument()
    await user.type(screen.getByLabelText('Business name'), 'Lagos Bike Tours')
    await user.type(screen.getByLabelText('CAC registration number'), 'RC 7654321')
    await user.type(screen.getByLabelText('Business address'), '3 Herbert Macaulay Way, Yaba')
    await user.selectOptions(screen.getByLabelText('Area'), 'Yaba')
    await user.click(screen.getByRole('button', { name: 'Continue' }))
    expect(await screen.findByRole('heading', { name: 'Your guides' })).toBeInTheDocument()
  })
})
