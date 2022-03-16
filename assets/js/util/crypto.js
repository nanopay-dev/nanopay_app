import { Buffer } from 'buffer'
import Prando from 'prando'

/**
 * Hashes the email and password using a PBKDF2 process and returns an object
 * containing a password hash and 128bit recovery secret.
 * As an additional obfuscation step, Prando is used to generate a deterministic
 * pseudo-random salt and a integer to determine extra hash loops.
 */
export const hashCredentials = async (email, password) => {
  const rng = new Prando(`${ email.toLowerCase() }:${ password }`),
        salt = rng.nextString(),
        exHash = rng.nextInt();

  const rawBytes = await pbkdf2(password, salt, { iterations: 128000, hash: 'SHA-512', length: 256 });

  let part1 = await sha256(rawBytes.subarray(0, 32)),
      part2 = await sha256(rawBytes.subarray(32));

  for (let i = 1; i < exHash; i++) {
    part1 = await sha256(part1)
    part2 = await sha256(part2)
  }

  return {
    password: part1.toString('hex'),
    recovery: part2.subarray(0, 16).toString('base64')
  }
}

/**
 * PBKDF2 function. Iterates over the given data and continuously hashes it with
 * the specified params.
 */
export const pbkdf2 = async (data, salt, opts = {}) => {
  const hash = opts.hash || 'SHA-256'
  const length = opts.length || 256
  const iterations = opts.iterations || 128000
  data = Buffer.from(data)
  salt = Buffer.from(salt)

  const key = await crypto.subtle.importKey(
    'raw', data, 'PBKDF2', false, ['deriveBits']
  )

  const res = await crypto.subtle.deriveBits(
    { name: 'PBKDF2', hash, salt, iterations }, key, length
  )

  data = Buffer.from(res)
  return opts.to ? data.toString(opts.to) : data
}

/**
 * Hashes the given data using SHA-256.
 */
 export const sha256 = async (data, opts = {}) => {
  data = Buffer.from(data, opts.from)
  data = await crypto.subtle.digest('SHA-256', data)
  data = Buffer.from(data)
  return opts.to ? data.toString(opts.to) : data
}

/**
 * Returns the given data bytes as a web-crypto key.
 */
 export const toKey = async (data, algo, opts = {}) => {
  const usages = opts.usages || ['encrypt', 'decrypt']
  data = Buffer.from(data, opts.from)
  return crypto.subtle.importKey('raw', data, algo, false, usages)
}

/**
 * Encrypts the given data with the given encryption key.
 */
export const encrypt = async (data, key, opts = {}) => {
  data = Buffer.from(data, opts.from)
  const addData = opts.addData ? Buffer.from(opts.addData) : new ArrayBuffer
  const iv = crypto.getRandomValues(new Uint8Array(12))
  
  const ciphertext = await crypto.subtle.encrypt({
    name: 'AES-GCM',
    iv,
    additionalData: addData
  }, key, data)

  data = Buffer.concat([
    Buffer.from(iv),
    Buffer.from(ciphertext)
  ])

  return opts.to ? data.toString(opts.to) : data
}

/**
 * Decrypts the given data with the given encryption key.
 */
export const decrypt = async (data, key, opts = {}) => {
  data = Buffer.from(data, opts.from)
  const addData = opts.addData ? Buffer.from(opts.addData) : new ArrayBuffer
  const iv = data.subarray(0, 12)
  const ciphertext = data.subarray(12)

  const result = await crypto.subtle.decrypt({
    name: 'AES-GCM',
    iv,
    additionalData: addData
  }, key, ciphertext)

  data = Buffer.from(result)
  return opts.to ? data.toString(opts.to) : data
}

/**
 * Returns the specified number of random bytes.
 */
export const randBytes = (bytes, opts = {}) => {
  const data = new Uint8Array(bytes)
  crypto.getRandomValues(data)
  return opts.to ? Buffer.from(data).toString(opts.to) : Buffer.from(data)
}