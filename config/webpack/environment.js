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

// Completely disable compression and optimization for all environments
environment.config.optimization = {
  minimize: false,
  runtimeChunk: false,
  minimizer: [],
  splitChunks: {
    chunks: 'all',
    maxInitialRequests: 1,
    cacheGroups: {
      vendor: {
        test: /[\\/]node_modules[\\/]/,
        name: 'vendors',
        chunks: 'all',
        enforce: true,
      },
    },
  },
}

// Remove any existing compression plugins
environment.plugins = environment.plugins.filter(plugin => {
  const pluginName = plugin.constructor && plugin.constructor.name
  return !pluginName || !pluginName.toLowerCase().includes('compression')
})

// Reduce memory usage
environment.config.cache = false
environment.config.parallelism = 1
environment.config.performance = { hints: false }
environment.config.stats = 'minimal'
environment.config.devtool = false

module.exports = environment
