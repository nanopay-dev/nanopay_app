import Alpine from 'alpinejs'
import { Buffer } from 'buffer'
import { Bn, Bip39, Ecies, KeyPair, PubKey, Point } from 'bsv/dist/bsv.bundle'
import { decrypt, encrypt, toKey, randBytes, sha256 } from './util/crypto'

/**
 * Appkey store
 * Contains the app master pubkey and a session key (if exists)
 */
Alpine.store('appkey', {
  masterPubKey: null,
  sessionKey: null,

  initialize(mpkey, skey) {
    this.masterPubKey = mpkey
    this.sessionKey = skey
  },

  /**
   * Returns the master pubkey as a BSV pubkey
   */
  getMasterPubKey() {
    return PubKey.fromHex(this.masterPubKey)
  },

  /**
   * Returns the session key as a web crypto AES key
   */
  async getSessionKey() {
    return toKey(this.sessionKey, 'AES-GCM', { from: 'base64' })
  },

  /**
   * Derives a new encryption pubkey from the master pubkey using the given path
   */
  async deriveEncryptionKey(path) {
    const pubKey = this.getMasterPubKey()
    const hash = await sha256(path)
    const s = Bn.fromBuffer(hash)
    const point = Point.getG().mul(s).add(pubKey.point)
    return new PubKey(point)
  }
})

/**
 * Userkey store
 * Contains the secret key and recovery key
 * The secret key is randomly generated when a user registers. The recovery key
 * is derived from the users login credentials.
 */
Alpine.store('userkey', {
  recoveryKey: null,
  secretKey: null,

  async initialize() {
    this.secretKey = randBytes(16, { to: 'base64' })
  },

  /**
   * Derives an app encryption pubkey with the given path and returns an
   * encrypted recovery key. This can only be decrypted with the master privkey
   * by deriving a encryption privkey from the same path.
   */
  async getEncryptedRecoveryKey(path) {
    const pubKey = await Alpine.store('appkey').deriveEncryptionKey(path)
    const data = Ecies.electrumEncrypt(Buffer.from(this.recoveryKey, 'base64'), pubKey, null)
    return data.toString('base64')
  },

  /**
   * Encrypts the secret key with the recovery key and returns the encrypted
   * secret key.
   */
  async getEncryptedSecretKey() {
    const key = await this.getRecoveryKey()
    return encrypt(this.secretKey, key, { from: 'base64', to: 'base64' })
  },

  /**
   * Returns the recovery key as a web crypto AES key
   */
  async getRecoveryKey() {
    return toKey(this.recoveryKey, 'AES-GCM', { from: 'base64' })
  },

  /**
   * Returns the secret key as a web crypto AES key
   */
  async getSecretKey() {
    return toKey(this.secretKey, 'AES-GCM', { from: 'base64' })
  },

  /**
   * Returns the mnemonic from the secret key
   */
  getSecretMnemonic() {
    if (!this.secretKey) return nil;
    const secretBuf = Buffer.from(this.secretKey, 'base64')
    const bip39 = Bip39.fromEntropy(secretBuf)
    return bip39.mnemonic
  },

  /**
   * Decrypts the encrypted secret key using the recovery key and puts the
   * secret key into the store
   */
  async putEncryptedSecretKey(encSecret) {
    const key = await this.getRecoveryKey()
    this.secretKey = await decrypt(encSecret, key, { from: 'base64', to: 'base64' })
  },

  /**
   * Loads the encrypted secret key from local storage, decrypts it using the
   * app session key and puts the secret key into the store
   */
  async restoreSecretKey() {
    const key = await Alpine.store('app').getSessionKey()
    const encSecretKey = window.localStorage.getItem('nanopay_esk')
    if (key && encSecretKey) {
      this.secretKey = await await decrypt(encSecret, key, { from: 'base64', to: 'base64' })
    } else {
      throw 'Unauthenticated'
    }
  },

  /**
   * Encrypts the secret key with the app session key and saves the encrypted
   * secret key into local storage
   */
  async saveSecretKey() {
    const key = await Alpine.store('appkey').getSessionKey()
    const encSecretKey = await encrypt(this.secretKey, key, { from: 'base64', to: 'base64' })
    window.localStorage.setItem('nanopay_esk', encSecretKey)
  }
})

/**
 * Profilekey store
 * Contains a BSV keypair for a profile
 */
Alpine.store('profilekey', {
  privKey: null,
  pubKey: null,

  async initialize() {
    const keyPair = KeyPair.fromRandom()
    this.privKey = keyPair.privKey.bn.toBuffer().toString('hex')
    this.pubKey = keyPair.pubKey.toHex()
  },

  /**
   * Encrypts the private key with the user secret key and returns the encrypted
   * private key.
   */
  async getEncryptedPrivKey() {
    const key = await Alpine.store('userkey').getSecretKey()
    return await encrypt(this.privKey, key, { from: 'hex', to: 'base64' })
  }
})