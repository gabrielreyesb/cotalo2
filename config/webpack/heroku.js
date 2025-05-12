process.env.NODE_ENV = process.env.NODE_ENV || 'production'
process.env.NODE_OPTIONS = '--openssl-legacy-provider'

const environment = require('./environment')
const config = environment.toWebpackConfig()

// Remove compression plugins explicitly
const pluginsToRemove = ['CompressionPlugin', 'compression-webpack-plugin']
pluginsToRemove.forEach(pluginName => {
  try {
    config.plugins = config.plugins.filter(plugin => {
      return !plugin.constructor || !plugin.constructor.name || !plugin.constructor.name.includes(pluginName)
    })
  } catch (e) {
    // Ignore if plugin doesn't exist
  }
})

// Optimize for memory usage in Heroku
config.optimization = {
  minimize: false, // Disable minimization to avoid OpenSSL issues
  runtimeChunk: false,
  minimizer: [], // Remove minimizers to avoid OpenSSL issues
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

// Reduce memory usage during compilation
config.cache = false
config.parallelism = 1
config.performance = { hints: false }
config.stats = 'minimal'
config.devtool = false

module.exports = config 