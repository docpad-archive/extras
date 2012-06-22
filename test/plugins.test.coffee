# Requires
pathUtil = require('path')
balUtil = require('bal-util')
joe = require('joe')
Reporter = joe.require('reporters/console')
joe.setReporter(new Reporter())

# Configure
pluginsPath = pathUtil.join(__dirname, '..', 'plugins')
indentResult = (result) ->
	(result or '').replace(/\n/g,'\n\t')

# Fail on an uncaught error
process.on 'uncaughtException', (err) ->
	throw err

# Scan Plugins
balUtil.scandir(
	# Path
	pluginsPath

	# Skip files
	false

	# Handle directories
	(pluginPath,pluginRelativePath,nextFile) ->
		# Prepare
		pluginName = pathUtil.basename(pluginRelativePath)

		# Test the plugin
		joe.test pluginName, (done) ->
			# Execute the plugin's tests
			commands = ['npm install', 'make compile', 'npm test']
			options = {cwd:pluginPath, output:true}
			balUtil.spawn commands, options, (err,results) ->
				# Output the test results for the plugin
				if results.length is commands.length
					testResult = results[commands.length-1]
					err = testResult[0]
					if err
						err = new Error('the tests failed')
						done(err)
					else
						done()
				else
					done()

				# All done
				nextFile(err,true)

	# Finish
	(err) ->
		# Check
		throw err  if err
)