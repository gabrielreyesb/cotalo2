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

// Disable compression and optimize for Heroku
if (process.env.RAILS_ENV === 'production' && process.env.NODE_ENV === 'production') {
  // Remove all compression-related plugins
  const pluginsToRemove = ['CompressionPlugin', 'compression-webpack-plugin']
  pluginsToRemove.forEach(pluginName => {
    try {
      environment.plugins.delete(pluginName)
    } catch (e) {
      // Ignore if plugin doesn't exist
    }
  })
  
  // Disable compression and optimize for Heroku
  environment.config.optimization = environment.config.optimization || {}
  environment.config.optimization.minimize = false
  environment.config.optimization.runtimeChunk = false
  environment.config.optimization.splitChunks = {
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
  }
  
  // Reduce memory usage
  environment.config.cache = false
  environment.config.parallelism = 1
  environment.config.performance = { hints: false }
  environment.config.stats = 'minimal'
  environment.config.devtool = false
}

module.exports = environment
