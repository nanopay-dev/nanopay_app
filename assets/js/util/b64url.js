import { Buffer } from 'buffer'

export function unescape (str) {
  return (str + '==='.slice((str.length + 3) % 4))
    .replace(/-/g, '+')
    .replace(/_/g, '/')
}

export function escape (str) {
  return str.replace(/\+/g, '-')
    .replace(/\//g, '_')
    .replace(/=/g, '')
}

export function encode (str, encoding) {
  return escape(Buffer.from(str, encoding || 'utf8').toString('base64'))
}

export function decode (str, encoding) {
  return Buffer.from(unescape(str), 'base64').toString(encoding || 'utf8')
}