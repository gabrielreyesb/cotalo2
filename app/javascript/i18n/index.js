import { createI18n } from 'vue-i18n'
import translations from './translations'

const i18n = createI18n({
  locale: document.documentElement.lang || 'es', // Default to Spanish
  fallbackLocale: 'es',
  messages: translations
})

export default i18n 