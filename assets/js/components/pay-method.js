import Alpine from 'alpinejs'

const isAndroid = navigator.userAgent.match(/Android/i)
const isIOS = navigator.userAgent.match(/iPhone|iPad|iPod/i)

Alpine.data('PayMethodBtns', (url) => {
  return {
    copied: false,
    isMobile: (isAndroid || isIOS),

    openUrl() {
      this.$store.iframe.postMessage('wallet.open', { url: this.$root.dataset.url })
    },

    async copyUrl() {
      try {
        await navigator.clipboard.writeText(this.$root.dataset.url)
        this.copied = true
        setTimeout(_ => this.copied = false, 3000)
      } catch(e) {
        console.error('Unable to copy URL')
        console.error(e)
      }
    }
  }
})
