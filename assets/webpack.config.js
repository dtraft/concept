

const path = require('path');
const MiniCssExtractPlugin = require('mini-css-extract-plugin');
const UglifyJsPlugin = require('uglifyjs-webpack-plugin');
const OptimizeCSSAssetsPlugin = require('optimize-css-assets-webpack-plugin');
const CopyWebpackPlugin = require('copy-webpack-plugin');
const postcssPresetEnv = require('postcss-preset-env');

module.exports = (env, options) => {
    const isDev = options.mode == 'development';

    return {
        optimization: {
            minimizer: [
                new UglifyJsPlugin({
                    cache: true,
                    parallel: true,
                    sourceMap: isDev,
                }),
                new OptimizeCSSAssetsPlugin({}),
            ],
        },
        entry: {
            app: './src/static/index.js'
        },
        resolve: {
            extensions: ['.js', '.elm'],
            modules: ['node_modules'],
        },
        output: {
            filename: '[name].js',
            path: path.resolve(__dirname, '../priv/static/js'),
        },
        devtool: 'source-map',
        module: {
            rules: [{
                test: /\.js$/,
                exclude: [/node_modules/, /js\/components/, /js\/vendor/],
                use: {
                    loader: 'babel-loader',
                },
            },
            {
                test: /\.elm$/,
                exclude: [/elm-stuff/, /node_modules/],
                use: [{
                    loader: 'elm-webpack-loader',
                    options: {
                        pathToElm: 'node_modules/.bin/elm',
                        verbose: isDev,
                        debug: isDev,
                        forceWatch: isDev
                    },
                },],
            },
            {
                test: /\.css$/,
                use: [MiniCssExtractPlugin.loader, 'css-loader'],
            },
            {
                test: /\.scss$/,
                use: [{
                    loader: MiniCssExtractPlugin.loader,
                    options: {
                        sourceMap: isDev,
                    },
                },
                {
                    loader: 'css-loader',
                    options: {
                        minimize: true || {
                            /* CSSNano Options */
                        },
                        sourceMap: isDev,
                    },
                },
                {
                    loader: 'postcss-loader',
                    options: {
                        sourceMap: isDev,
                        ident: 'postcss',
                        plugins: () => [
                            postcssPresetEnv(/* pluginOptions */)
                        ]
                    },
                },
                {
                    loader: 'sass-loader',
                    options: {
                        sourceMap: isDev,
                    },
                },
                ],
            },
            ],
        },
        plugins: [
            new MiniCssExtractPlugin({
                filename: '../css/[name].css',
            }),
        ],
    };
};
