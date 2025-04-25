const { environment } = require('@rails/webpacker')
const { VueLoaderPlugin } = require('vue-loader')
const webpack = require('webpack')

// Add Vue loader
const vue = require('./loaders/vue')
environment.plugins.prepend('VueLoaderPlugin', new VueLoaderPlugin())
environment.loaders.prepend('vue', vue)

// Set Vue 3 feature flags
environment.plugins.prepend(
  'DefinePlugin',
  new webpack.DefinePlugin({
    __VUE_OPTIONS_API__: 'true',
    __VUE_PROD_DEVTOOLS__: 'false',
    __VUE_PROD_HYDRATION_MISMATCH_DETAILS__: 'false',
  })
)

// Disable compression during asset precompilation
if (process.env.RAILS_ENV === 'production' && process.env.NODE_ENV === 'production') {
  environment.plugins.delete('CompressionPlugin')
}

module.exports = environment
