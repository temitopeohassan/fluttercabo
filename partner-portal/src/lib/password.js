// PBKDF2-SHA256 password hashing with the Web Crypto API. The seed script
// uses the same parameters with Node's crypto, so seeded hashes verify here.
const encoder = new TextEncoder()

const toHex = (buffer) => [...new Uint8Array(buffer)].map((b) => b.toString(16).padStart(2, '0')).join('')

export function randomHex(bytes = 16) {
  return toHex(crypto.getRandomValues(new Uint8Array(bytes)))
}

async function derive(password, salt, iterations) {
  const key = await crypto.subtle.importKey('raw', encoder.encode(password), 'PBKDF2', false, ['deriveBits'])
  const bits = await crypto.subtle.deriveBits({ name: 'PBKDF2', hash: 'SHA-256', salt: encoder.encode(salt), iterations }, key, 256)
  return toHex(bits)
}

export async function hashPassword(password, iterations = 100000) {
  const salt = randomHex(16)
  return { salt, hash: await derive(password, salt, iterations), iterations }
}

export async function verifyPassword(password, stored) {
  if (!stored?.salt || !stored?.hash) return false
  const hash = await derive(password, stored.salt, stored.iterations)
  // Constant-time comparison.
  let diff = hash.length ^ stored.hash.length
  for (let i = 0; i < hash.length; i++) diff |= hash.charCodeAt(i) ^ stored.hash.charCodeAt(i)
  return diff === 0
}

/** Returns a list of problems with a new password; empty when it is acceptable. */
export function passwordProblems(password) {
  const problems = []
  if (password.length < 8) problems.push('at least 8 characters')
  if (!/[A-Za-z]/.test(password)) problems.push('a letter')
  if (!/[0-9]/.test(password)) problems.push('a number')
  return problems
}
