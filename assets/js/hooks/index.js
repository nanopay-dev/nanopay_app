import Alpine from 'alpinejs'
import { BalanceChart } from './charts'

export default {
  /**
   * Alpine Hook simply attaches the liveView hook to the Alpine component el.
   */
   AlpineHook: {
    mounted() {
      this.el.$hook = this
      this.el.dispatchEvent(new Event('phx.hooked'))
    }
  },

  /**
   * Wraps the app and stores the master pubkey and session key
   */
   AppWrap: {
    mounted() {
      Alpine.store('appkey').initialize(
        this.el.dataset.mkey,
        this.el.dataset.skey
      )
    }
  },
  
  BalanceChart
}