import Alpine from 'alpinejs'

/**
 * TODO
 */
export const MoneyButton = {
  async mounted() {
    const mb = await Alpine.store('libs').get('moneybutton')
    const { amount, paymail } = this.el.dataset

    mb.render(this.el, {
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