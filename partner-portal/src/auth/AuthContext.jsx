import { createContext, useCallback, useContext, useEffect, useState } from 'react'
import * as auth from '../api/auth'

const AuthContext = createContext(null)

export function AuthProvider({ children }) {
  const [state, setState] = useState({ loading: true, account: null })

  const refresh = useCallback(async () => {
    const account = await auth.getAccount()
    setState({ loading: false, account })
    return account
  }, [])

  useEffect(() => {
    refresh()
  }, [refresh])

  const value = {
    ...state,
    refresh,
    signIn: async (credentials) => {
      await auth.signIn(credentials)
      return refresh()
    },
    apply: async (form) => {
      await auth.apply(form)
      return refresh()
    },
    signOut: () => {
      auth.signOut()
      setState({ loading: false, account: null })
    },
  }
  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>
}

export const useAuth = () => useContext(AuthContext)
