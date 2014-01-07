# Requires
pathUtil = require('path')
fsUtil = require('fs')
balUtil = require('bal-util')
safefs = require('safefs')
safeps = require('safeps')
eachr = require('eachr')
commander = require('commander')
{TaskGroup} = require('taskgroup')
exchange = require('./exchange')


# -----------------
# App

class App
	runner: null
	config: null

	constructor: (@config) ->
		# Runner
		@runner = new TaskGroup().run().on 'complete', (err) ->
			console.log(err.stack)  if err

	ensure: (opts,next) ->
		{skeletonsPath, pluginsPath} = @config

		@runner.addGroup ->
			@addTask (complete) -> safefs.ensurePath(pluginsPath, complete)
			@addTask (complete) -> safefs.ensurePath(skeletonsPath, complete)

		@runner.addTask(next); @

	clone: (opts,next) ->
		me = @
		{skeletonsPath, pluginsPath} = @config

		@runner.addGroup ->
			# Skeletons
			@addTask (complete) ->
				console.log "Cloning latest skeletons"

				cloneRepos = []
				for own key,repo of exchange.skeletons
					repoShortname = repo.repo.replace(/^.+\/(.+\/.+)\.git$/, '$1').replace('/', '-')
					cloneRepos.push(
						name: key
						url: repo.repo
						path: "#{skeletonsPath}/#{repoShortname}"
						branch: repo.branch
					)

				# Clone the repos
				me.cloneRepos({repos: cloneRepos}, complete)

			# Plugins
			@addTask (complete) ->
				console.log "Fetching latest plugins"
				balUtil.readPath "https://api.github.com/orgs/docpad/repos?page=1&per_page=100", (err,data) ->
					# Check
					return next(err)  if err

					# Invalid JSON
					try
						repos = JSON.parse(data)
					catch err
						return complete(err)

					# Error Message
					if repos.message
						err = new Error(repos.message)
						return complete(err)

					# No repos
					if repos.length is 0
						return complete()

					# Skip if not a plugin
					cloneRepos = []
					repos.forEach (repo) ->
						# Prepare
						repoShortname = repo.name.replace(/^docpad-plugin-/,'')

						# Skip if expiremental or deprecated or is not a plugin
						return  if /^(EXPER|DEPR)/.test(repo.description) or repoShortname is repo.name

						# Add the repo to the ones we want to clone
						cloneRepos.push(
							name: repo.name
							url: repo.clone_url
							path: "#{pluginsPath}/#{repoShortname}"
							branch: 'master'
						)

					# Log
					console.log "Cloning latest plugins"

					# Clone the repos
					me.cloneRepos({repos: cloneRepos}, complete)

		@runner.addTask(next); @

	cloneRepos: (opts,next) ->
		# Prepare
		cloneTasks = new TaskGroup().setConfig(concurrency:1).once('complete',next)

		# Clone each one
		eachr opts.repos, (repo) ->
			# Prepare
			spawnCommands = []
			spawnOpts = {}

			# New
			if fsUtil.existsSync(repo.path) is false
				spawnCommands.push ['git', 'clone', repo.url, repo.path]

			# Update
			else
				spawnCommands.push ['git', 'checkout', repo.branch]
				spawnCommands.push ['git', 'pull', 'origin', repo.branch]
				spawnOpts.cwd = repo.path

			# Re-link
			spawnCommands.push ['npm', 'link', 'docpad']

			# Handle
			cloneTasks.addTask (next) ->
				console.log "Fetching #{repo.name}"
				safeps.spawnMultiple spawnCommands, spawnOpts, (err,args...) ->
					if err
						console.log "Fetching #{repo.name} FAILED", err
						return next(err)
					else
						console.log "Fetched #{repo.name}"
					return next()

		# Run
		cloneTasks.run()

	status: (opts,next) ->
		{pluginsPath} = @config
		{skip,only} = (opts or {skip:null,only:null})

		@runner.addTask (next) ->
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

		@runner.addTask(next); @

	outdated: (opts,next) ->
		{npmEdgePath,pluginsPath} = @config
		{skip,only} = (opts or {skip:null,only:null})

		@runner.addTask (next) ->
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
							console.log stdout.replace(/^npm http .*/m, '')  if stdout
							console.log stderr  if stderr

						# Done
						nextFile(err,true)

				# Finish
				next
			)

		@runner.addTask(next); @

	standardize: (opts,next) ->
		{pluginsPath} = @config

		@runner.addTask (next) ->
			standardizeTasks = new TaskGroup(concurrency: 5).once('complete', next)

			# Scan Plugins
			balUtil.scandir(
				# Path
				pluginsPath

				# Skip files
				false

				# Handle directories
				(pluginPath,pluginRelativePath,nextFile) ->  nextFile(null,true); standardizeTasks.addTask (complete) ->
					# Prepare
					pluginName = pathUtil.basename(pluginRelativePath)

					safeps.spawnCommand 'git', ['mv','-f','-k','Contributing.md','CONTRIBUTING.md'], {cwd:pluginPath,output:true}, (err) ->
						return complete(err)  if err

						safeps.spawnCommand 'git', ['mv','-f','-k','History.md','HISTORY.md'], {cwd:pluginPath,output:true}, (err) ->
							return complete(err)  if err

							safeps.exec pathUtil.join(__dirname, 'download-meta.bash'), {cwd:pluginPath,output:true}, (err) ->
								return complete(err)  if err

								# Update the package.json file
								pluginPackagePath = pluginPath+'/package.json'
								pluginPackageData = require(pluginPackagePath)

								engines = (pluginPackageData.engines ?= {})
								peerDeps = (pluginPackageData.peerDependencies ?= {})
								devDeps = (pluginPackageData.devDependencies ?= {})

								devDeps.docpad = (peerDeps.docpad ?= engines.docpad ? '6')
								delete engines.docpad
								devDeps.projectz = '~0.3.9'

								pluginPackageData.license = 'MIT'
								pluginPackageData.badges = {
									"travis": true
									"npm": true
									"david": true
									"daviddev": true
									"gittip": "docpad"
									"flattr": "344188/balupton-on-Flattr"
									"paypal": "QB8GQPZAH84N6"
									"bitcoin": "https://coinbase.com/checkouts/9ef59f5479eec1d97d63382c9ebcb93a"
								}

								# Write the file
								pluginPackageDataString = JSON.stringify(pluginPackageData, null, '  ')
								safefs.writeFile pluginPackagePath, pluginPackageDataString, (err) ->
									return complete(err)  if err

									# Update the .travis.yml file
									travisPath = pluginPath+'/.travis.yml'
									travisData = fsUtil.readFileSync(travisPath).toString()
									travisData = travisData.replace('install: "npm install"', 'install: "npm install; npm install docpad; cd ./node_modules/docpad; npm install; cd ../.."')
									fsUtil.writeFile travisPath, travisData, (err) ->
										return complete(err)

										cakePath = pathUtil.join(pluginPath, 'node_modules', '.bin', 'cake')
										safeps.exec cakePath+' prepublish', {cwd:pluginPath,output:true}, (err) ->
											return complete(err)

				# Finish
				(err) ->
					return next(err)  if err
					return standardizeTasks.run()
			)

		@runner.addTask(next); @

	exec: (opts,next) ->
		{pluginsPath} = @config

		@runner.addTask (next) ->
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

					# Execute the command
					safeps.exec opts.command, {cwd:pluginPath, env: process.env}, (err, stdout, stderr) ->
						console.log "exec [#{opts.command}] on: #{pluginPath}"
						process.stdout.write stderr  if err
						process.stdout.write stdout
						console.log ''
						return nextFile(err, true)

				# Finish
				next
			)

		@runner.addTask(next); @

	test: (opts,next) ->
		{pluginsPath} = @config
		{skip,only,startFrom} = (opts or {})

		@runner.addTask (next) ->
			# Require Joe Testing Framework
			joe = require('joe')

			# Start playing eye of the tiger
			require('open')('http://youtu.be/2WrEmJpV2ic')

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
					if startFrom and startFrom > pluginName
						console.log("Skipping #{pluginName}")
						return
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
							nextFile(err, true)

				# Finish
				next
			)

		@runner.addTask(next); @

# -----------------
# Helpers

# Handle CSV values
splitCsvValue = (result) ->
	result or= ''
	result = result.split(',')  if result
	result or= null
	return result


# -----------------
# Commands

# App
app = new App({
	npmEdgePath: pathUtil.join(__dirname, 'node_modules', 'npmedge', 'bin', 'npmedge')
	pluginsPath: pathUtil.join(__dirname, 'plugins')
	skeletonsPath: pathUtil.join(__dirname, 'skeletons')
}).ensure()
defaultSkip = ['pygments','concatmin','iis','html2jade','html2coffee','tumblr','contenttypes']


## Commands

# Use [Commander](https://github.com/visionmedia/commander.js/) for command and option parsing
cli = require('commander')

# Extract out version out of our package and apply it to commander
cli.version(
	require('./package.json').version
)

# Options
cli
	.option('--only <only>', 'only run against these plugins (CSV)')
	.option('--skip <skip>', 'skip these plugins (CSV)')
	.option('--start <start>', 'start from this plugin name')

# exec
cli.command('exec <command>').description('execute a command for each plugin').action (command) ->
	app.exec({command})

# outdated
cli.command('outdated').description('check which plugins have outdated dependencies')
	.action ->
		app.status({
			only: splitCsvValue(cli.only)
			skip: splitCsvValue(cli.skip) or defaultSkip
			startFrom: cli.start
		})

# standardize
cli.command('standardize').description('ensure plugins live up to the latest standards').action ->
	app.standardize()

# clone
cli.command('clone').description('clone out new plugins and update the old').action ->
	app.clone()

# status
cli.command('status').description('check the git status of our plugins')
	.action ->
		app.status({
			only: splitCsvValue(cli.only)
			skip: splitCsvValue(cli.skip) or defaultSkip
			startFrom: cli.start
		})

# test
cli.command('test').description('run the tests')
	.action ->
		app.test({
			only: splitCsvValue(cli.only)
			skip: splitCsvValue(cli.skip) or defaultSkip
			startFrom: cli.start
		})

# Start the CLI
cli.parse(process.argv)