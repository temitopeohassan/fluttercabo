import '@testing-library/jest-dom/vitest'
import { cleanup } from '@testing-library/react'
import { afterEach, beforeAll, beforeEach } from 'vitest'
import { signOut } from '../api/auth'
import { initStore, resetDemoData } from '../api/store'

beforeAll(initStore)

beforeEach(() => {
  window.localStorage.clear()
  window.sessionStorage.clear()
  resetDemoData()
  signOut()
})

afterEach(() => cleanup())
