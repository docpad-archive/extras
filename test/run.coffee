# Requires
assert = require('assert')
fs = require('fs')
path = require('path')
request = require('request')
util = require('bal-util')
DocPad = require('docpad')


# -------------------------------------
# Configuration

# Vars
port = 9779
outPath = "#{__dirname}/out"
outExpectedPath = "#{__dirname}/out-expected"
baseUrl = "http://localhost:#{port}"

# Configure DocPad
docpadConfig = 
	port: port
	rootPath: __dirname
	pluginsPath: path.join(__dirname, '..', 'plugins')
	logLevel: 6
	enableUnlistedPlugins: false
	enabledPlugins:
		#move: true  installation currently fails
		php: true
		roy: true
		ruby: true

# Fail on an uncaught error
process.on 'uncaughtException', (err) ->
	throw err

# Local globals
docpad = null
logger = null


# -------------------------------------
# Tests

describe 'core', ->

	it 'should instantiate correctly', (done) ->
		@timeout(60000)
		docpad = DocPad.createInstance docpadConfig, (err) ->
			throw err  if err
			logger = docpad.logger
			done()

	it 'should run correctly', (done) ->
		@timeout(60000)
		docpad.action 'run', (err) ->
			throw err  if err
			done()

			describe 'generate', ->
				testMarkup = (markupName,markupFile) ->
					describe markupName, ->
						it "should generate #{markupName} files", (done) ->
							@timeout(5000)
							fs.readFile "#{outExpectedPath}/#{markupFile}", (err,expecting) ->
								throw err  if err
								fs.readFile "#{outPath}/#{markupFile}", (err,actual) ->
									throw err  if err
									assert.equal(
										expecting.toString()
										actual.toString()
									)
									done()
				testMarkup(markupName,markupFile)  for own markupName, markupFile of {
					move: 'move.js'
					php: 'php.html'
					roy: 'roy.js'
					ruby: 'ruby.html'
					eruby: 'eruby.html'
				}
