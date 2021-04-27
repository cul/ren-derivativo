const { environment } = require('@rails/webpacker')

environment.config.merge({
  module: {
    rules: [
      {
        test: /VERSION$/,
        use: 'raw-loader',
      },
    ],
  },
})

module.exports = environment
