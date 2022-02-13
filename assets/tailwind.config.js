const defaultTheme = require('tailwindcss/defaultTheme')

module.exports = {
  content: [
    './js/**/*.js',
    '../lib/*_web.ex',
    '../lib/*_web/**/*.*ex',
  ],
  theme: {
    extend: {
      fontFamily: {
        sans: ['Inter var', ...defaultTheme.fontFamily.sans],
      },
      zIndex: {
        '-1': '-1',
      }
    },
  },
  plugins: [
    require('@tailwindcss/forms')
  ],
}
