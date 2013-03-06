# Requires
request = require('request')
pathUtil = require('path')
fsUtil = require('fs')
balUtil = require('bal-util')


# -----------------
# App

class App
	runner: null
	config: null

	constructor: (@config) ->
		# Runner
		@runner = new balUtil.Group 'serial', (err) ->
			throw err	if err
		@runner.total = Infinity

	ensure: (opts,next) ->
		{pluginsPath} = @config
		@runner.pushAndRun (complete) ->
			balUtil.ensurePath pluginsPath, (err) ->
				return (complete(err); next?(err))
		@

	clone: (opts,next) ->
		{pluginsPath} = @config
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
						if repoShortname isnt repo.name and /^(EXPER|DEPR)/.test(repo.description) is false
							if fsUtil.existsSync(repoClonePath) is false
								commands.push ['git', 'clone', repo.ssh_url, repoClonePath]
							else
								commands.push {
									command: 'git'
									args: ['pull','origin','master']
									options: {cwd: repoClonePath}
								}

					balUtil.spawnMultiple commands, {output:true,outputCommand:true,tasksMode:'parallel'}, (err) ->
						return (complete(err); next?(err))  if err
						clonePage(page+1)
			clonePage(1)

		@

	status: (opts,next) ->
		{pluginsPath} = @config
		{skip,only} = (opts or {skip:null,only:null})
		@runner.pushAndRun (complete) ->
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

					# Execute the plugin's tests
					options = {cwd:pluginPath, env:process.env}
					balUtil.exec 'git status', options, (err,stdout,stderr) ->
						# Log
						if stdout and stdout.indexOf('nothing to commit') is -1
							console.log pluginPath  if stdout or stderr
							console.log stdout  if stdout
							console.log stderr  if stderr

						# Done
						nextFile(err,true)

				# Finish
				(err,list,tree) ->
					return (complete(err); next?(err))
			)

		@

	outdated: (opts,next) ->
		{npmEdgePath,pluginsPath} = @config
		{skip,only} = (opts or {skip:null,only:null})
		@runner.pushAndRun (complete) ->
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

					# Execute the plugin's tests
					command = npmEdgePath
					options = {cwd:pluginPath}
					balUtil.nodeCommand command, options, (err,stdout,stderr) ->
						# Log
						if stdout and stdout.indexOf('is specified') isnt -1
							console.log pluginPath  if stdout or stderr
							console.log stdout  if stdout
							console.log stderr  if stderr

						# Done
						nextFile(err,true)

				# Finish
				(err,list,tree) ->
					return (complete(err); next?(err))
			)

		@


	test: (opts,next) ->
		{pluginsPath} = @config
		{skip,only} = (opts or {skip:null,only:null})
		@runner.pushAndRun (complete) ->
			# Require Joe Testing Framework
			joe = require('joe')
			Reporter = joe.require('reporters/console')
			joe.setReporter(new Reporter())

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
					if fsUtil.existsSync(pluginPath+'/test') is false
						console.log("Skipping #{pluginName}")
						return

					# Test the plugin
					joe.test pluginName, (done) ->
						# Execute the plugin's tests
						commands = []
						commands.push('npm install')
						if fsUtil.existsSync(pluginPath+'/Cakefile')
							commands.push('cake compile')
						else if fsUtil.existsSync(pluginPath+'/Makefile')
							commands.push('make compile')
						commands.push('npm test')
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
				(err,list,tree) ->
					return (complete(err); next?(err))
			)

		@

# -----------------
# Helpers

# Should we skip any plugins?
extractArgument = (name) ->
	result = null
	for arg in process.argv
		value = arg.replace(new RegExp("^--#{name}="),'')
		if value isnt arg
			result = value
			break
	return result
extractCsvArgument = (name) ->
	result = extractArgument(name)
	result = result.split(',')  if result
	return result



# -----------------
# Commands

# App
app = new App({
	npmEdgePath: pathUtil.join(__dirname, 'node_modules', 'npmedge', 'bin', 'npmedge')
	pluginsPath: pathUtil.join(__dirname, 'plugins')
}).ensure()
defaultSkip = ['pygments','concatmin','tumblr','iis']

# outdated
task 'outdated', 'check which plugins have outdated dependencies', ->
	app.outdated({
		skip: extractCsvArgument('skip') or defaultSkip
		only: extractCsvArgument('only')
	})

# clone
task 'clone', 'clone out new plugins and update the old', ->
	app.clone()

# status
task 'status', 'check the git status of our plugins', ->
	app.status({
		skip: extractCsvArgument('skip') or defaultSkip
		only: extractCsvArgument('only')
	})

# test
task 'test', 'run the tests', ->
	app.test({
		skip: extractCsvArgument('skip') or defaultSkip
		only: extractCsvArgument('only')
	})
