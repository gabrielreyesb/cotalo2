<template>
  <div class="language-switcher">
    <div class="dropdown">
      <button class="btn btn-outline-secondary dropdown-toggle" type="button" id="languageDropdown" data-bs-toggle="dropdown" aria-expanded="false">
        {{ currentLanguage }}
      </button>
      <ul class="dropdown-menu" aria-labelledby="languageDropdown">
        <li>
          <a class="dropdown-item" href="#" @click.prevent="changeLanguage('es')">
            <span class="flag-icon flag-icon-es"></span> Español
          </a>
        </li>
        <li>
          <a class="dropdown-item" href="#" @click.prevent="changeLanguage('en')">
            <span class="flag-icon flag-icon-us"></span> English
          </a>
        </li>
      </ul>
    </div>
  </div>
</template>

<script>
export default {
  name: 'LanguageSwitcher',
  data() {
    return {
      currentLanguage: this.getCurrentLanguage()
    }
  },
  methods: {
    getCurrentLanguage() {
      const lang = i18n.global.locale
      return lang === 'es' ? 'Español' : 'English'
    },
    changeLanguage(lang) {
      i18n.global.locale = lang
      this.currentLanguage = lang === 'es' ? 'Español' : 'English'
      document.documentElement.lang = lang
      
      // Store the preference in localStorage
      localStorage.setItem('preferred_language', lang)
      
      // Dispatch an event that other components can listen to
      window.dispatchEvent(new CustomEvent('languageChanged', { detail: { language: lang } }))
    }
  },
  mounted() {
    // Check for saved language preference
    const savedLanguage = localStorage.getItem('preferred_language')
    if (savedLanguage) {
      this.changeLanguage(savedLanguage)
    }
  }
}
</script>

<style scoped>
.language-switcher {
  display: inline-block;
}

.dropdown-item {
  cursor: pointer;
  display: flex;
  align-items: center;
  gap: 8px;
}

.flag-icon {
  width: 20px;
  height: 15px;
  background-size: contain;
  background-position: center;
  background-repeat: no-repeat;
  display: inline-block;
}

.flag-icon-es {
  background-image: url('data:image/svg+xml;utf8,<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 750 500"><rect width="750" height="250" fill="%23c60b1e"/><rect y="250" width="750" height="250" fill="%23ffc400"/><rect y="500" width="750" height="250" fill="%23c60b1e"/></svg>');
}

.flag-icon-us {
  background-image: url('data:image/svg+xml;utf8,<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1235 650"><rect width="1235" height="650" fill="%23bf0a30"/><rect width="1235" height="50" y="50" fill="%23fff"/><rect width="1235" height="50" y="150" fill="%23fff"/><rect width="1235" height="50" y="250" fill="%23fff"/><rect width="1235" height="50" y="350" fill="%23fff"/><rect width="1235" height="50" y="450" fill="%23fff"/><rect width="1235" height="50" y="550" fill="%23fff"/><rect width="494" height="350" fill="%23002169"/></svg>');
}
</style> 