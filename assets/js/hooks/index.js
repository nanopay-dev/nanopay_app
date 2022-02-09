//import Alpine from 'alpinejs'
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
  
  BalanceChart
}