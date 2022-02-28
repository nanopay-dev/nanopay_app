import QrCreator from 'qr-creator'

/**
 * TODO
 */
export const QrCode = {
  mounted() {
    this.renderQr()
  },

  updated() {
    this.renderQr()
  },

  renderQr() {
    QrCreator.render({
      text: this.el.dataset.url,
      radius: 0,
      ecLevel: 'L',
      fill: '#111827',
      size: 128
    }, this.el);
  }
}