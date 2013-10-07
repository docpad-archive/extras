# Requires
pathUtil = require('path')
fsUtil = require('fs')
balUtil = require('bal-util')
safefs = require('safefs')
safeps = require('safeps')
eachr = require('eachr')
{TaskGroup} = require('taskgroup')


# -----------------
# App

class App
	runner: null
	config: null

	constructor: (@config) ->
		# Runner
		@runner = new TaskGroup().setConfig(concurrency:0).run().on 'complete', (err) ->
			throw err	if err

	addTask: (next,task) ->
		@runner.addTask (complete) ->
			return task (err) ->
				return complete(err); next?(err)
		@

	ensure: (opts,next) ->
		{pluginsPath} = @config
		@addTask next, (next) ->
			return safefs.ensurePath(pluginsPath,next)
		@

	clone: (opts,next) ->
		{pluginsPath} = @config
		@addTask next, (next) ->
			# Prepare
			console.log "Fetching latest repos"
			balUtil.readPath "https://api.github.com/orgs/docpad/repos?page=1&per_page=100", (err,data) ->
				# Check
				return next(err)  if err

				# Invalid JSON
				try
					repos = JSON.parse(data)
				catch err
					return next(err)

				# Error Message
				if repos.message
					err = new Error(repos.message)
					return next(err)

				# No repos
				if repos.length is 0
					return next()

				# Log
				console.log "Fetched latest repos"

				# Prepare
				cloneTasks = new TaskGroup().setConfig(concurrency:1).once('complete',next)

				# Clone each one
				eachr repos, (repo) ->
					# Prepare
					spawnCommands = []
					spawnOpts = {}
					repoShortname = repo.name.replace(/^docpad-plugin-/,'')
					repoClonePath = "#{pluginsPath}/#{repoShortname}"

					# Skip if expiremental or deprecated or is not a plugin
					return  if /^(EXPER|DEPR)/.test(repo.description) or repoShortname is repo.name

					# New
					if fsUtil.existsSync(repoClonePath) is false
						spawnCommands.push ['git', 'clone', repo.clone_url, repoClonePath]

					# Update
					else
						spawnCommands.push ['git', 'checkout', 'master']
						spawnCommands.push ['git', 'pull', 'origin', 'master']
						spawnOpts.cwd = repoClonePath

					# Re-link
					spawnCommands.push ['npm', 'link', 'docpad']

					# Handle
					cloneTasks.addTask (next) ->
						console.log "Fetching #{repoShortname}"
						safeps.spawnMultiple spawnCommands, spawnOpts, (err,args...) ->
							if err
								console.log "Fetching #{repoShortname} FAILED", err
								return next(err)
							else
								console.log "Fetched #{repoShortname}"
							return next()

				# Run
				cloneTasks.run()

		@

	status: (opts,next) ->
		{pluginsPath} = @config
		{skip,only} = (opts or {skip:null,only:null})
		@addTask next, (next) ->
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
					safeps.spawnCommand 'git', ['status'], options, (err,stdout,stderr) ->
						# Log
						if stdout and stdout.indexOf('nothing to commit') is -1
							console.log pluginPath  if stdout or stderr
							console.log stdout  if stdout
							console.log stderr  if stderr

						# Done
						nextFile(err,true)

				# Finish
				(err,list,tree) ->
					return next(err)
			)

		@

	outdated: (opts,next) ->
		{npmEdgePath,pluginsPath} = @config
		{skip,only} = (opts or {skip:null,only:null})
		@addTask next, (next) ->
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
					safeps.spawnCommand 'node', command, options, (err,stdout,stderr) ->
						# Log
						if stdout and stdout.indexOf('is specified') isnt -1
							console.log pluginPath  if stdout or stderr
							console.log stdout  if stdout
							console.log stderr  if stderr

						# Done
						nextFile(err,true)

				# Finish
				next
			)

		@


	test: (opts,next) ->
		{pluginsPath} = @config
		{skip,only} = (opts or {skip:null,only:null})
		@addTask next, (next) ->
			# Require Joe Testing Framework
			joe = require('joe')

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
						# Prepare
						options = {output:true,cwd:pluginPath}

						# Commands
						spawnCommands = []
						spawnCommands.push('npm link docpad')
						spawnCommands.push('npm install')
						if fsUtil.existsSync(pluginPath+'/Cakefile')
							spawnCommands.push('cake compile')
						else if fsUtil.existsSync(pluginPath+'/Makefile')
							spawnCommands.push('make compile')
						spawnCommands.push('npm test')

						# Spawn
						safeps.spawnMultiple spawnCommands, options, (err,results) ->
							# Output the test results for the plugin
							if results.length is spawnCommands.length
								testResult = results[spawnCommands.length-1]
								err = testResult[0]
								# args = testResult[1...]
								if err
									joeError = new Error("Testing #{pluginName} FAILED")
									# console.log "Testing #{pluginName} FAILED"
									# args.forEach (arg) -> console.log(arg)  if arg
									done(joeError)
								else
									done()
							else
								done()

							# All done
							nextFile(err,true)

				# Finish
				next
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
defaultSkip = ['pygments','concatmin','iis','html2jade','html2coffee','tumblr']

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
