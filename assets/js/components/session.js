import Alpine from 'alpinejs'
import { hashCredentials } from '../util/crypto'
import { appApi } from '../util/api'

/**
 * Login form component
 */
Alpine.data('SessionForm', _ => {
  return {
    email: null,
    password: null,

    /**
     * Submit form handler.
     * Hashes the user credentials and attempts to log the user in with HTTP API.
     * If successful the session key is stored and encrypted secret key stored
     * to localstorage.
     */
    async submit() {
      const { password, recovery } = await hashCredentials(this.email, this.password)
      this.$store.userkey.recoveryKey = recovery

      appApi.post('/auth', { email: this.email, password })
        .then(async ({ data }) => {
          this.$store.appkey.sessionKey = data.session_key
          await this.$store.userkey.putEncryptedSecretKey(data.secret_key)
          await this.$store.userkey.saveSecretKey()
          this.$el.$hook.pushEvent('login', { success: true })
        })
        .catch(e => {
          this.$el.$hook.pushEvent('login', { success: false })
        })
    }
  }
})