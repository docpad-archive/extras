# Requires
path = require('path')
balUtil = require('bal-util')
testers = require('docpad/lib/testers.coffee')

# Configure
pluginsPath = path.join(__dirname,'..','plugins')

# Fail on an uncaught error
process.on 'uncaughtException', (err) ->
	throw err

# Scan Plugins
describe 'plugins', (done) ->
	balUtil.scandir(
		# Path
		pluginsPath

		# Skip files
		false

		# Handle directories
		(pluginPath,pluginRelativePath,nextFile) ->
			# Prepare
			pluginName = path.basename(pluginPath)
			testerPath = path.join(pluginPath,"#{pluginName}.tester.coffee")

			# Check if the tester exists
			testerExists = path.existsSync(testerPath)
			
			# Check if the tester exists
			return nextFile(null,true)  unless testerExists

			# Test the plugin's tester
			describe pluginName, ->
				testerClass = require(testerPath)(testers)
				testerInstance = new testerClass(
					pluginName: pluginName
					pluginPath: pluginPath
				)
				testerInstance.test()

			# Next file
			return nextFile(null,true)

		# Finish
		(err) ->
			# Check
			throw err  if err
	)