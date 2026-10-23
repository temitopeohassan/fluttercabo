import { describe, expect, it } from 'vitest'
import { apply, changePassword, DEMO_PASSWORD, getAccount, getSession, requestPasswordReset, resetPassword, signIn, signOut } from '../api/auth'
import { load } from '../api/store'

const application = {
  name: 'Ada Lovelace', email: 'Ada@Example.ng', phone: '+2348030000000', password: 'tours2026',
  businessName: 'Ada Lagoon Walks', type: 'tour_operator', cacNumber: 'rc 1234567', address: '1 Marina, Lagos', area: 'Lagos Island',
  documents: { cac: { name: 'cac.pdf', size: 1000 }, insurance: { name: 'ins.pdf', size: 2000 } }, insuranceExpiresOn: '2099-01-01',
  guides: [{ name: 'Ada Lovelace', phone: '+2348030000000', languages: ['English'] }],
  bankName: 'GTBank', bankAccountNumber: '0123456789', bankAccountName: 'Ada Lagoon Walks', consent: true,
}

describe('sign in', () => {
  it('signs in a seeded partner with the demo password', async () => {
    await signIn({ email: 'ADAEZE@ekonaturetrails.ng ', password: DEMO_PASSWORD })
    const account = await getAccount()
    expect(account.partner.name).toBe('Eko Nature Trails')
    expect(account.user.password).toBeUndefined()
  })

  it('rejects a wrong password without saying which part was wrong', async () => {
    await expect(signIn({ email: 'adaeze@ekonaturetrails.ng', password: 'nope' })).rejects.toThrow('do not match')
    await expect(signIn({ email: 'nobody@example.com', password: 'nope' })).rejects.toThrow('do not match')
    expect(getSession()).toBeNull()
  })

  it('locks an email after five failed attempts', async () => {
    for (let i = 0; i < 5; i++) await expect(signIn({ email: 'funmi@funmiisland.ng', password: 'wrong' })).rejects.toThrow()
    await expect(signIn({ email: 'funmi@funmiisland.ng', password: DEMO_PASSWORD })).rejects.toThrow('Too many attempts')
  })

  it('keeps the session only for the browser session unless remembered', async () => {
    await signIn({ email: 'funmi@funmiisland.ng', password: DEMO_PASSWORD })
    expect(window.sessionStorage.getItem('cabo-partner-portal:session')).not.toBeNull()
    expect(window.localStorage.getItem('cabo-partner-portal:session')).toBeNull()
    await signIn({ email: 'funmi@funmiisland.ng', password: DEMO_PASSWORD, remember: true })
    expect(window.localStorage.getItem('cabo-partner-portal:session')).not.toBeNull()
    signOut()
    expect(getSession()).toBeNull()
  })
})

describe('applying to join (P-01)', () => {
  it('creates a pending partner with documents and guides, and signs in', async () => {
    await apply(application)
    const { partner, user } = await getAccount()
    expect(partner).toMatchObject({ name: 'Ada Lagoon Walks', status: 'pending', cacNumber: 'RC 1234567', commissionRate: 15 })
    expect(partner.documents.map((d) => d.type)).toEqual(['cac', 'insurance'])
    expect(partner.guides).toHaveLength(1)
    expect(user.email).toBe('ada@example.ng')
    const stored = load().users.find((u) => u.email === 'ada@example.ng')
    expect(stored.password.hash).toMatch(/^[0-9a-f]{64}$/)
    expect(JSON.stringify(stored)).not.toContain('tours2026')
  })

  it('requires the documents, guides and consent', async () => {
    const error = await apply({ ...application, documents: {}, guides: [], consent: false, password: 'short' }).catch((e) => e)
    expect(Object.keys(error.fields)).toEqual(expect.arrayContaining(['cac', 'insurance', 'guides', 'consent', 'password']))
  })

  it('refuses an email that already has an account', async () => {
    const error = await apply({ ...application, email: 'funmi@funmiisland.ng' }).catch((e) => e)
    expect(error.fields.email).toMatch(/already/)
  })
})

describe('passwords', () => {
  it('resets a password with the emailed code', async () => {
    const { demoCode } = await requestPasswordReset('funmi@funmiisland.ng')
    await expect(resetPassword({ email: 'funmi@funmiisland.ng', code: '000000', password: 'newpass123' })).rejects.toThrow('not right')
    await resetPassword({ email: 'funmi@funmiisland.ng', code: demoCode, password: 'newpass123' })
    await expect(signIn({ email: 'funmi@funmiisland.ng', password: DEMO_PASSWORD })).rejects.toThrow()
    await signIn({ email: 'funmi@funmiisland.ng', password: 'newpass123' })
  })

  it('does not reveal whether an email has an account', async () => {
    expect(await requestPasswordReset('stranger@example.com')).toEqual({ demoCode: null })
  })

  it('changes the password only with the current one', async () => {
    await signIn({ email: 'funmi@funmiisland.ng', password: DEMO_PASSWORD })
    await expect(changePassword({ current: 'wrong', password: 'another123' })).rejects.toThrow('not right')
    await changePassword({ current: DEMO_PASSWORD, password: 'another123' })
    signOut()
    await signIn({ email: 'funmi@funmiisland.ng', password: 'another123' })
  })
})
