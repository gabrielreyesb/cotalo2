process.env.NODE_ENV = process.env.NODE_ENV || 'production'

const environment = require('./environment')
const config = environment.toWebpackConfig()

// Optimize for memory usage in Heroku
config.optimization = {
  minimize: true,
  runtimeChunk: false, // Disable runtime chunk to save memory
  minimizer: [
    // Use terser plugin with reduced memory settings
    new (require('terser-webpack-plugin'))({
      terserOptions: {
        compress: {
          drop_console: true, // Remove console.* statements
        },
      },
      parallel: false, // Disable parallel processing to save memory
    }),
  ],
  splitChunks: {
    chunks: 'all',
    maxInitialRequests: 1, // Limit parallel requests
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
config.cache = false // Disable caching
config.parallelism = 1 // Use minimal parallelism
config.performance = { hints: false } // Disable performance hints
config.stats = 'minimal' // Minimal stats output

// Disable source maps in production to save memory
config.devtool = false

module.exports = config 