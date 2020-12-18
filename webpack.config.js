const slsw = require('serverless-webpack');
// const nodeExternals = require('webpack-node-externals');

const baseConfig = {
  mode: slsw.lib.webpack.isLocal ? 'development' : 'production',
  target: 'node',
  devtool: 'source-map',
  module: {
    rules: [
      {
        test: /\.js$/,
        exclude: /(node_modules)/,
        use: {
          loader: 'babel-loader'
        }
      },
      {
        test: /\.(key|key.pub)$/,
        use: [
          {
            loader: 'raw-loader'
          }
        ]
      }
    ]
  }
};

const config = {
  ...baseConfig,
  output: {
    libraryTarget: 'commonjs2',
    path: `${__dirname}/dist-lambda`,
    filename: '[name].js'
  },
  entry: slsw.lib.entries,
};


module.exports = config;
