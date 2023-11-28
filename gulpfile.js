/**
 * build, watch, deploy tasks
 * for the library and example application package
 */
const { src, dest, watch, series, parallel } = require('gulp')
const rename = require('gulp-rename')
const zip = require("gulp-zip")
const del = require('delete')

const { createClient, readOptionsFromEnv } = require('@existdb/gulp-exist')
const replace = require('@existdb/gulp-replace-tmpl')

// read metadata from package.json and .existdb.json
const { version, license, app } = require('./package.json')

// .tmpl replacements to include 
// first value wins
const replacements = [app, {version, license}]

const defaultOptions = { basic_auth: { user: "admin", pass: "" } }
const connectionOptions = Object.assign(defaultOptions, readOptionsFromEnv())
const existClient = createClient(connectionOptions);

// console.log(connectionOptions)

const distFolder = 'dist'
const buildFolder = 'build'
const staticBuild = 'static'

const package = {
    static: [
        "src/icon.svg",
        "src/content/*",
        "src/examples/*",
        "src/systems/*",
        "src/*.{xq,html}",
        // "icon.svg"
    ],
    allBuildFiles: 'build/**/*',
    templates: 'src/*.tmpl'
}

// construct the current xar name from available data
const packageFilename = `${app.target}-${version}.xar`

/**
 * helper function that uploads and installs a built XAR
 */
function installXar (packageFilename) {
    return src(packageFilename, {cwd: distFolder})
        .pipe(existClient.install())
}

function cleanDist (cb) {
    del([distFolder], cb);
}
exports['clean:dist'] = cleanDist

function cleanLibrary (cb) {
    del([buildFolder], cb);
}
exports['clean:library'] = cleanLibrary

function cleanAll (cb) {
    del([distFolder, buildFolder], cb);
}
exports['clean:all'] = cleanAll

exports.clean = cleanAll

/**
 * replace placeholders 
 * in src/*.xml.tmpl and 
 * output to build/*.xml
 */
function templates() {
    return src(package.templates, {base: 'src'})
        .pipe(replace(replacements, { unprefixed: true }))
        .pipe(rename(path => { path.extname = "" }))
        .pipe(dest(buildFolder))
}

exports.templates = templates

function watchTemplates () {
    watch(package.templates, series(templates))
}
exports["watch:tmpl"] = watchTemplates

/**
 * copy html templates, XSL stylesheet, XMLs and XQueries to 'build'
 */
function copyStatic () {
    return src(package.static, {base: 'src'}).pipe(dest(buildFolder))
}
exports.copy = copyStatic

function watchStatic () {
    watch(package.static, series(copyStatic));
}
exports["watch:static"] = watchStatic

/**
 * since this is a pure library package uploading
 * the library itself will not update the compiled
 * version in the cache.
 * This is why the xar will be installed instead
 */
function watchBuild () {
    watch(package.allBuildFiles, series(xar, installXar))
}

/**
 * create XAR package in repo root
 */
function xar () {
    return src(package.allBuildFiles, {base: buildFolder})
        .pipe(zip(packageFilename))
        .pipe(dest(distFolder))
}

/**
 * upload and install the latest built XAR
 */
function installApp () {
    return installXar(packageFilename)
}

// composed tasks
const packageApp = series(
    templates,
    copyStatic,
    xar
)

exports.build = series(cleanLibrary, packageApp)
exports.install = series(cleanLibrary, packageApp, installApp)

const watchAll = parallel(
    watchStatic,
    watchTemplates,
    watchBuild
)
exports.watch = watchAll

function buildStaticPage () {
    return src(['src/systems/*', 'src/content/*'], {base: 'src'})
        .pipe(dest(staticBuild))
}
exports.static = buildStaticPage

// main task for day to day development
// package and install library
// package test application but do not install it
// still watch all and install on change 
exports.default = series(
    cleanAll, 
    packageApp, installApp,
    watchAll
)
