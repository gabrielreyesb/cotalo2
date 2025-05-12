process.env.NODE_ENV = process.env.NODE_ENV || 'production'
process.env.NODE_OPTIONS = '--openssl-legacy-provider'

const environment = require('./environment')
module.exports = environment.toWebpackConfig() 