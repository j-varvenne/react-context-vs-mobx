const path = require('path');
const ForkTsCheckerWebpackPlugin = require('fork-ts-checker-webpack-plugin');
const HtmlWebpackPlugin = require('html-webpack-plugin');
const isProd = process.argv.indexOf('--production') !== -1;

module.exports = {
    entry: {
        index: './src/index.tsx',
    },
    output: {
        filename: 'js/[name].js',
        chunkFilename: 'js/[id].[name].js',
        path: path.join(__dirname, 'dist/'),
        publicPath: '/',
    },
    resolve: {
        extensions: ['.ts', '.tsx', '.js'],
        alias: {
            '@': path.resolve(__dirname, './src/'),
        },
    },

    devtool: 'inline-source-map',

    devServer: {
        port: process.env.WEBPACK_PORT,
        publicPath: '',
        progress: false,
        contentBase: './folderthatdoesnotexists',
        hot: true,
        host: '0.0.0.0',
        compress: true,
        allowedHosts: ['localhost'],
        https: true,
    },

    // Plugins
    plugins: [
        new HtmlWebpackPlugin({
            filename: 'index.html',
            template: 'src/index.html',
            chunks: ['index'],
            minify: {
                removeComments: isProd,
                collapseWhitespace: true,
            },
        }),
        new ForkTsCheckerWebpackPlugin({}),
    ],

    module: {
        rules: [
            // Typescript files
            {
                enforce: 'pre',
                test: /\.js$/,
                use: 'source-map-loader'
            },
            {
                enforce: 'pre',
                test: /\.ts$/,
                use: 'source-map-loader'
            },
            {
                test: /\.tsx?$/,
                loader: 'ts-loader',
                exclude: /node_modules/,
                options: {
                    transpileOnly: true,
                },
            },
        ]
    },
};
