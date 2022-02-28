import Alpine from 'alpinejs'

/**
 * TODO
 */
export const RelayOne = {
  async mounted() {
    const rx = await Alpine.store('libs').get('relayone')
    const { amount, paymail } = this.el.dataset

    rx.render(this.el, {
      to: paymail,
      amount: amount,
      currency: 'BSV',
      label: 'Send payment',
      onPayment(payment) {
        // todo - post rawtx to liveview
        console.log(payment)
      }
    })
  }
}