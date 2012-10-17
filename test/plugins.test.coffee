# Requires
request = require('request')
pathUtil = require('path')
fsUtil = require('fs')
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

# Prepare
class App
	runner: null
	config: null

	constructor: (@config) ->
		# Runner
		@runner = new balUtil.Group 'sync', (err) ->
			throw err	if err
		@runner.total = Infinity

	ensure: (next) ->
		@runner.pushAndRun (complete) ->
			balUtil.ensurePath pluginsPath, (err) ->
				return (complete(err); next?(err))
		@

	clone: (next) ->
		@runner.pushAndRun (complete) ->
			clonePage = (page) ->
				requestOptions =
					method: 'GET'
					uri: 'https://api.github.com/orgs/docpad/repos'
					qs: {page}
				request requestOptions, (err,res,body) ->
					return (complete(err); next?(err))  if err
					commands = []
					repos = JSON.parse(body)

					if repos.message
						err = new Error(repos.message)
						return (complete(err); next?(err))

					if repos.length is 0
						return (complete(); next?())

					for repo in repos
						repoShortname = repo.name.replace(/^docpad-plugin-/,'')
						repoClonePath = "#{pluginsPath}/#{repoShortname}"
						if repoShortname isnt repo.name and /^(EXPER|DEPR)/.test(repo.description) is false and fsUtil.existsSync(repoClonePath) is false
							commands.push ['git', 'clone', repo.ssh_url, repoClonePath]

					balUtil.spawnMultiple commands, {output:true}, (err) ->
						return (complete(err); next?(err))  if err
						clonePage(page+1)
			clonePage(1)

		@

	test: (next) ->
		@runner.pushAndRun (complete) ->
			# Should we skip any plugins?
			skip = null
			for arg in process.argv
				value = arg.replace(/^--skip=/,'')
				if value isnt arg
					skip = value.split(',')
					break
			only = null
			for arg in process.argv
				value = arg.replace(/^--only=/,'')
				if value isnt arg
					only = value.split(',')
					break

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

					# Skip
					if skip and (pluginName in skip)
						console.log("Skipping #{pluginName}")
						return
					if only and (pluginName in only) is false
						console.log("Skipping #{pluginName}")
						return

					# Test the plugin
					joe.test pluginName, (done) ->
						# Execute the plugin's tests
						commands = ['npm install', 'make compile', 'npm test']
						options = {cwd:pluginPath, output:true}
						balUtil.spawnMultiple commands, options, (err,results) ->
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
					return (complete(err); next?(err))
			)

		@

# Run
app = new App()
app.ensure().clone().test()
