import Alpine from 'alpinejs'
import { $iframe } from '../events'

function getWidgetSize() {
  const width = document.body.clientWidth
  const height = document.body.clientHeight
  return { width, height }
}

Alpine.store('iframe', {
  origin: null,

  init() {
    window.addEventListener('message', event => {
      if (!this.origin && event.data.type === 'handshake') {
        this.origin = event.origin
        $iframe.emit('mounted')
      } else if (this.origin === event.origin) {
        $iframe.emit(event.data.type, event.data.payload)
      }
    }, false)

    new ResizeObserver(_ => {
      this.postMessage('resize', getWidgetSize())
    }).observe(document.body)

    $iframe.on('mounted', _ => {
      this.initSize()
    })
  },

  initSize(int = 100) {
    setTimeout(_ => {
      const { width, height } = getWidgetSize()
      if (height > 320) {
        this.postMessage('resize', { width, height })
      } else {
        this.initSize(int+50)
      }
    }, int)
  },

  postMessage(type, payload = {}) {
    if (!this.origin) return;
    window.parent.postMessage({
      type,
      payload
    }, this.origin)
  }
})