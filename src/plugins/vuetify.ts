import { createVuetify } from 'vuetify'
import { aliases, mdi } from 'vuetify/iconsets/mdi-svg'
import { de } from 'vuetify/locale'

import 'vuetify/styles'

export default createVuetify({
  theme: {
    defaultTheme: 'light'
  },
  locale: {
    messages: { de }
  },
  icons: {
    defaultSet: 'mdi',
    aliases,
    sets: {
      mdi
    }
  },
  defaults: {
    VTooltip: {
      location: 'top'
    }
  }
})
