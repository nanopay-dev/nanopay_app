import Alpine from 'alpinejs'

Alpine.data('PayRequest', () => {
  return {
    init() {
      console.log('yo you')
      this.$el.addEventListener('phx.hooked', () => {
        this.$el.$hook.handleEvent('funded', (data) => {
          this.$store.iframe.postMessage('pr.funded', data)
        })
      })
    }
  }
})