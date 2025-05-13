const { merge } = require('webpack-merge');
const environment = require('./environment');
const customConfig = require('./custom');

// Optimize the bundle for production
const prodConfig = {
  optimization: {
    splitChunks: {
      chunks: 'all',
      maxInitialRequests: Infinity,
      minSize: 20000,
      cacheGroups: {
        vendor: {
          test: /[\\/]node_modules[\\/]/,
          name(module) {
            // Get the name. E.g. node_modules/packageName/not/this/part.js
            // or node_modules/packageName
            const packageName = module.context.match(/[\\/]node_modules[\\/](.*?)([\\/]|$)/)[1];
            // npm package names are URL-safe, but some servers don't like @ symbols
            return `vendor.${packageName.replace('@', '')}`;
          },
        },
      },
    },
  },
  performance: {
    hints: 'warning',
    maxEntrypointSize: 244000, // 244 KiB
    maxAssetSize: 244000,
  },
};

module.exports = merge(environment.toWebpackConfig(), customConfig, prodConfig); 