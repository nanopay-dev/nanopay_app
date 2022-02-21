import Alpine from 'alpinejs'
import { Iodine } from '@kingshott/iodine'
import { hashCredentials, randBytes } from '../util/crypto'
import { appApi } from '../util/api'

const iodine = new Iodine()
iodine.setErrorMessage('regexMatch', '[FIELD] can contain letters, numbers and underscore')

const model = {
  blurred: false,
  error: null,
  rules: null,
  value: ''
}

/**
 * Registration form component
 */
Alpine.data('RegistrationForm', _ => {
  return {
    handle: { ...model, rules: ['required', 'minLength:4', 'regexMatch:^[\\w]+$'] },
    email: { ...model, rules: ['required', 'email'] },
    password: { ...model, rules: ['required', 'minLength:8'] },

    /**
     * Returns the array of form field keys.
     */
    get keys() {
      return ['handle', 'email', 'password']
    },

    /**
     * Initialises the component.
     * Creates a new user secret key and sets up watchers on the form fields
     */
    async init() {
      this.$store.userkey.initialize()
      
      this.$watch('handle.value', val => this.validate('handle', val))
      this.$watch('email.value', val => this.validate('email', val))
      this.$watch('password.value', val => this.validate('password', val))
    },

    /**
     * Submit form handler.
     * If the form is valid it hashes the user credentials, sets up user
     * registration object and attempts to register the user with liveview.
     * If successful it attempts to log the user in with HTTP API and redirects,
     */
    async submit() {
      if (this.isValid() && this.keys.some(k => this[k].blurred)) {
        const {password, recovery} = await hashCredentials(this.email.value, this.password.value)
        this.$store.userkey.recoveryKey = recovery
        await this.$store.profilekey.initialize()

        const recPath = `e/${ randBytes(6, { to: 'base64' }) }`

        const event = {
          user: {
            email: this.email.value,
            password,
            key_data: {
              rec_path: recPath,
              enc_recovery: await this.$store.userkey.getEncryptedRecoveryKey(recPath),
              enc_secret: await this.$store.userkey.getEncryptedSecretKey()
            }
          },
          profile: {
            handle: this.handle.value,
            pubkey: this.$store.profilekey.pubKey,
            enc_privkey: await this.$store.profilekey.getEncryptedPrivKey()
          }
        }

        this.$el.$hook.pushEvent('submit', event, (reply) => {
          // If errors display them
          if (reply.errors) {
            Object.keys(reply.errors).forEach(k => {
              this[k].error = reply.errors[k][0]
            })
          }

          // If success log the user in
          if (reply.success) {
            appApi.post('/auth', { email: this.email.value, password })
              .then(async ({ data }) => {
                this.$store.appkey.sessionKey = data.session_key
                await this.$store.userkey.saveSecretKey()
                this.$el.$hook.pushEvent('login')
              })
              .catch(e => {
                console.log(e)
              })
          }
        })

      } else {
        // Iterate over fields and validate each
        this.keys.forEach(k => {
          this[k].blurred = true
          this.validate(k, this[k].value || '')
        })
      }
    },

    /**
     * Returns true if the form fields are valid
     */
    isValid() {
      return this.keys.every(k => !this[k].error)
    },

    /**
     * Validates the given form field and value
     */
    validate(key, value) {
      const rules = this[key].rules
      if (rules.length) {
        const isValid = iodine.is(value, rules)
        this[key].error = isValid === true ? null : iodine.getErrorMessage(isValid);
      }
    }
  }
})
