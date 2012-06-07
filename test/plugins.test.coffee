# Requires
path = require('path')
balUtil = require('bal-util')

# Configure
pluginsPath = path.join(__dirname, '..', 'plugins')

# Fail on an uncaught error
process.on 'uncaughtException', (err) ->
	throw err

# Scan Plugins
describe 'plugins', ->
	it 'should dance', (done) ->
		@timeout(60*1000)
		balUtil.scandir(
			# Path
			pluginsPath

			# Skip files
			false

			# Handle directories
			(pluginPath,pluginRelativePath,nextFile) ->
				# Prepare
				pluginName = path.basename(pluginPath)
				testPath = path.join(pluginPath, "test/#{pluginName}.test.js")

				balUtil.exec ['rm -Rf lib', 'make compile'], {cwd:pluginPath}, (err) ->
					# Check if the tester exists
					testPathExists = path.existsSync(testPath)

					# Check if the tester exists
					return nextFile(null,true)  unless testPathExists

					# Test the plugin's tester
					require(testPath)

					# Next file
					return nextFile(null,true)

			# Finish
			(err) ->
				# Check
				throw err  if err
				done()
		)