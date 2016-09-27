# Requires
pathUtil = require('path')
fsUtil = require('fs')
scandir = require('scandirectory')
safefs = require('safefs')
safeps = require('safeps')
eachr = require('eachr')
commander = require('commander')
CSON = require('cson')
{TaskGroup} = require('taskgroup')



# -----------------
# App

class App
	runner: null
	config: null
	logger: null

	constructor: (@config) ->
		# Prepare
		me = @

		# Logger
		level    = if @config.debug then 7 else 6
		@logger  = require('caterpillar').createLogger({level:level})
		filter   = require('caterpillar-filter').createFilter()
		human    = require('caterpillar-human').createHuman()
		@logger.pipe(filter).pipe(human).pipe(process.stdout)

		# Runner
		@runner = new TaskGroup('runner').run().done (err) ->
			console.log(err.stack)  if err

	log: (args...) ->
		logger = (@logger or console)
		logger.log.apply(logger, args)

	ensure: (opts,next) ->
		{skeletonsPath, pluginsPath} = @config

		@runner.addGroup 'ensure', ->
			@addTask 'plugins', (complete) -> safefs.ensurePath(pluginsPath, complete)
			@addTask 'skeletons', (complete) -> safefs.ensurePath(skeletonsPath, complete)

		@runner.addTask('ensure complete callback', next)  if next
		@

	clone: (opts,next) ->
		me = @
		{skeletonsPath, pluginsPath} = @config
		exchange = null

		@runner.addGroup 'clone', ->
			# Exchange
			@addTask 'exchange', (complete) ->
				CSON.load __dirname+'/exchange.cson', (err, result) ->
					return complete(err)  if err
					exchange = result

			# Skeletons
			@addTask 'skeletons', (complete) ->
				me.log 'info', "Cloning latest skeletons"

				cloneRepos = []
				for own key,repo of exchange.skeletons
					repoShortname = repo.repo.toLowerCase().replace(/^.+\/(.+\/.+)\.git$/, '$1').replace('/', '-').replace('docpad-skeleton-', '').replace('.docpad', '')
					cloneRepos.push(
						name: key
						url: repo.repo
						path: "#{skeletonsPath}/#{repoShortname}"
						branch: repo.branch
					)

				# Clone the repos
				me.cloneRepos({repos: cloneRepos}, complete)

			# Plugins
			@addTask 'plugins', (complete) ->
				me.log 'info', "Fetching latest plugins"
				require('feedr').create(cache:false).readFeed {url:"https://api.github.com/orgs/docpad/repos?page=1&per_page=100", parse:'json'}, (err,repos) ->
					# Check
					return next(err)  if err

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
					me.log 'info', "Cloning #{repos.length} latest plugins"

					# Clone the repos
					me.cloneRepos({repos: cloneRepos}, complete)

		@runner.addTask('clone complete callback', next)  if next
		@

	cloneRepos: (opts,next) ->
		# Prepare
		me = @
		cloneTasks = new TaskGroup('clone repos', {concurrency:1}).done(next)

		# Clone each one
		eachr opts.repos, (repo) ->
			# Prepare
			spawnCommands = []
			spawnOpts = {}
			spawnOpts.cwd = repo.path

			safefs.ensurePath repo.path, (err) ->
				return next(err)  if err

				# New
				if fsUtil.existsSync(repo.path+'/.git') is false
					spawnCommands.push ['git', 'init']
					spawnCommands.push ['git', 'remote', 'add', 'origin', repo.url]

				# Update
				spawnCommands.push ['git', 'fetch', 'origin']
				spawnCommands.push ['git', 'checkout', repo.branch]
				spawnCommands.push ['git', 'pull', 'origin', repo.branch]

				# Re-link
				spawnCommands.push ['npm', 'link', 'docpad']

				# Handle
				cloneTasks.addTask "init repo #{repo}", (next) ->
					me.log 'info', "Fetching #{repo.name} / #{repo.branch}"
					safeps.spawnMultiple spawnCommands, spawnOpts, (err,args...) ->
						if err
							me.log 'info', "Fetching #{repo.name} FAILED", err
							return next(err)
						else
							me.log 'info', "Fetched #{repo.name}"
						return next()

		# Run
		cloneTasks.run()

	status: (opts,next) ->
		me = @
		{pluginsPath} = @config
		{skip,only} = (opts or {skip:null,only:null})

		@runner.addTask 'status', (next) ->
			# Scan Plugins
			scandir({
				# Path
				path: pluginsPath

				# Skip files
				fileAction: false

				# Handle directories
				dirAction: (pluginPath,pluginRelativePath,nextFile) ->
					# Prepare
					pluginName = pathUtil.basename(pluginRelativePath)

					# Skip
					if skip and (pluginName in skip)
						me.log('info', "Skipping #{pluginName}")
						return
					if only and (pluginName in only) is false
						me.log('info', "Skipping #{pluginName}")
						return

					# Execute the plugin's tests
					options = {cwd:pluginPath, env:process.env}
					safeps.spawnCommand 'git', ['status'], options, (err,stdout,stderr) ->
						# Log
						if stdout and stdout.indexOf('nothing to commit') is -1
							me.log 'info', pluginPath  if stdout or stderr
							me.log 'info', stdout  if stdout
							me.log 'info', stderr  if stderr

						# Done
						nextFile(err,true)

				# Finish
				next: (err,list,tree) ->
					return next(err)
			})

		@runner.addTask('status complete callback', next)  if next
		@

	outdated: (opts,next) ->
		me = @
		{pluginsPath} = @config
		{skip,only} = (opts or {skip:null,only:null})

		@runner.addTask 'outdated', (next) ->
			# Scan Plugins
			scandir({
				# Path
				path: pluginsPath

				# Skip files
				fileAction: false

				# Handle directories
				dirAction: (pluginPath,pluginRelativePath,nextFile) ->
					# Prepare
					pluginName = pathUtil.basename(pluginRelativePath)

					# Skip
					if skip and (pluginName in skip)
						me.log('info', "Skipping #{pluginName}")
						return
					if only and (pluginName in only) is false
						me.log('info', "Skipping #{pluginName}")
						return

					# Execute the plugin's tests
					options = {cwd: pluginPath}
					safeps.spawnCommand 'npm', 'outdated', options, (err,stdout,stderr) ->
						# Log
						# if stdout and stdout.indexOf('is specified') isnt -1
						# 	if stdout or stderr
						# 		output = pluginPath
						# 		output += '\n'+stdout.replace(/^npm http .*/m, '')  if stdout
						# 		output += '\n'+stderr  if stderr
						me.log 'info', stdout, stderr

						# Done
						nextFile(err, true)

				# Finish
				next: next
			})

		@runner.addTask('outdated complete callback', next)  if next
		@

	standardize: (opts,next) ->
		me = @
		{pluginsPath} = @config
		{skip,only} = (opts or {skip:null,only:null})

		@runner.addTask 'standardize', (next) ->
			standardizeTasks = new TaskGroup(concurrency:1).done(next)

			# Scan Plugins
			scandir({
				# Path
				path: pluginsPath

				# Skip files
				fileAction: false

				# Handle directories
				dirAction: (pluginPath,pluginRelativePath,nextFile) ->  nextFile(null,true); standardizeTasks.addTask "standardize #{pluginPath}", (complete) ->
					# Prepare
					pluginName = pathUtil.basename(pluginRelativePath)

					# Skip
					if skip and (pluginName in skip)
						me.log('info', "Skipping #{pluginName}")
						return
					if only and (pluginName in only) is false
						me.log('info', "Skipping #{pluginName}")
						return

					# Log
					me.log 'info', "Standardizing #{pluginName}"

					me.log 'debug', "Standardize #{pluginName}: rename contributing"
					safeps.spawnCommand 'git', ['mv','-f','-k','Contributing.md','CONTRIBUTING.md'], {cwd:pluginPath,output:true}, (err) ->
						return complete(err)  if err

						me.log 'debug', "Standardize #{pluginName}: rename history"
						safeps.spawnCommand 'git', ['mv','-f','-k','History.md','HISTORY.md'], {cwd:pluginPath,output:true}, (err) ->
							return complete(err)  if err

							me.log 'debug', "Standardize #{pluginName}: download meta files"
							safeps.exec pathUtil.join(__dirname, 'download-meta.bash'), {cwd:pluginPath,output:true}, (err) ->
								return complete(err)  if err

								# Update the package.json file
								pluginPackagePath = pluginPath+'/package.json'
								pluginPackageData = require(pluginPackagePath)

								engines = (pluginPackageData.engines ?= {})
								deps = (pluginPackageData.dependencies ?= {})
								peerDeps = (pluginPackageData.peerDependencies ?= {})
								devDeps = (pluginPackageData.devDependencies ?= {})

								#if deps['taskgroup']
								#	deps['taskgroup'] = '~4.2.0'
								# ^ can't do this, as it is a API change, so we have to manually update plugins using older taskgroups

								devDeps.docpad = (peerDeps.docpad ?= engines.docpad ? '6')
								delete engines.docpad
								devDeps['projectz'] = '^0.5.0'
								if devDeps['coffee-script']
									devDeps['coffee-script'] = '^1.9.1'
								if devDeps['joe']
									devDeps['joe'] = '^1.6.0'

								pluginPackageData.bugs.url = "https://github.com/docpad/docpad-plugin-#{pluginName}/issues"
								pluginPackageData.repository.url = "https://github.com/docpad/docpad-plugin-#{pluginName}.git"
								pluginPackageData.license = 'MIT'
								pluginPackageData.badges = {
									"travis": true
									"npm": true
									"npmdownloads": true
									"david": true
									"daviddev": true
									"gratipay": "docpad"
									"flattr": "344188/balupton-on-Flattr"
									"paypal": "QB8GQPZAH84N6"
									"bitcoin": "https://coinbase.com/checkouts/9ef59f5479eec1d97d63382c9ebcb93a"
									"wishlist": "http://amzn.com/w/2F8TXKSNAFG4V"
								}
								pluginPackageData.cakeConfiguration = {
									"COFFEE_SRC_PATH": "src"
								}

								me.log 'debug', "Standardize #{pluginName}: write package"
								pluginPackageDataString = JSON.stringify(pluginPackageData, null, '  ')
								safefs.writeFile pluginPackagePath, pluginPackageDataString, (err) ->
									return complete(err)  if err

									me.log 'debug', "Standardize #{pluginName}: install new deps"
									safeps.spawn ['npm', 'install'], {cwd:pluginPath,output:true,outputPrefix:'>	'}, (err) ->
										return complete(err)  if err

										me.log 'debug', "Standardize #{pluginName}: projectz"
										projectzPath = pathUtil.join(pluginPath, 'node_modules', '.bin', 'projectz')
										safeps.spawn [projectzPath, 'compile'], {cwd:pluginPath,output:true,outputPrefix:'>	'}, (err) ->
											return complete(err)  if err

											safeps.spawnCommand 'git', ['commit', '-am', 'updated base files'], {cwd:pluginPath,output:true}, (err,stdout) ->
												return complete()  if err and stdout.indexOf('nothing to commit') isnt -1
												return complete(err)  if err

												safeps.spawnCommand 'git', ['push', 'origin', 'master'], {cwd:pluginPath,output:true}, (err) ->
													return complete(err)

				# Finish
				next: (err) ->
					return next(err)  if err
					return standardizeTasks.run()
			})

		@runner.addTask('standardize complete callback', next)  if next
		@

	exec: (opts,next) ->
		me = @
		{pluginsPath} = @config

		@runner.addTask 'exec', (next) ->
			# Scan Plugins
			scandir({
				# Path
				path: pluginsPath

				# Skip files
				fileAction: false

				# Handle directories
				dirAction: (pluginPath,pluginRelativePath,nextFile) ->
					# Prepare
					pluginName = pathUtil.basename(pluginRelativePath)

					# Execute the command
					safeps.exec opts.command, {cwd:pluginPath, env: process.env}, (err, stdout, stderr) ->
						me.log 'info', "exec [#{opts.command}] on: #{pluginPath}"
						process.stdout.write stderr  if err
						process.stdout.write stdout
						me.log 'info', ''
						return nextFile(err, true)

				# Finish
				next: next
			})

		@runner.addTask('exec complete callback', next)  if next
		@

	test: (opts,next) ->
		me = @
		{pluginsPath} = @config
		{skip,only,startFrom} = (opts or {})

		@runner.addTask 'test', (next) ->
			# Require Joe Testing Framework
			joe = require('joe')

			# Start playing eye of the tiger
			# require('open')('http://youtu.be/2WrEmJpV2ic')

			# Exchange
			joe.suite 'docpad-extras', (suite, test) ->
				test 'exchange', (done) ->
					CSON.load __dirname+'/exchange.cson', (err, result) ->
						done(err)

				suite 'plugins', (suite, test, done) ->
					# Scan Plugins
					scandir({
						# Path
						path: pluginsPath

						# Skip files
						fileAction: false

						# Handle directories
						dirAction: (pluginPath,pluginRelativePath,nextFile) ->
							# Prepare
							pluginName = pathUtil.basename(pluginRelativePath)

							# Skip
							if startFrom and startFrom > pluginName
								me.log('info', "Skipping #{pluginName}")
								return
							if skip and (pluginName in skip)
								me.log('info', "Skipping #{pluginName}")
								return
							if only and (pluginName in only) is false
								me.log('info', "Skipping #{pluginName}")
								return
							if fsUtil.existsSync(pluginPath+'/test') is false
								me.log('info', "Skipping #{pluginName}")
								return

							# Test the plugin
							test pluginName, (done) ->
								options = {output:true,cwd:pluginPath+'/test'}
								safeps.spawn 'npm link docpad', options, (err) ->
									# Error
									return nextFile(err)  if err

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
									else
										spawnCommands.push('npm run compile')
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
												# me.log 'info', "Testing #{pluginName} FAILED"
												# args.forEach (arg) -> me.log('info', arg)  if arg
												done(joeError)
											else
												done()
										else
											done()

										# All done
										nextFile(err, true)

						# Finish
						next: done
					})

				test 'complete', -> next()

		@runner.addTask('test complete callback', next)  if next
		@

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
	.option('-d, --debug', 'output debug messages')

# exec
cli.command('exec <command>').description('execute a command for each plugin').action (command) ->  process.nextTick ->
	app.exec({command})

# outdated
cli.command('outdated').description('check which plugins have outdated dependencies')
	.action ->  process.nextTick ->
		app.outdated({
			only: splitCsvValue(cli.only)
			skip: splitCsvValue(cli.skip) or defaultSkip
			startFrom: cli.start
		})

# standardize
cli.command('standardize').description('ensure plugins live up to the latest standards').action ->  process.nextTick ->
	app.standardize()

# clone
cli.command('clone').description('clone out new plugins and update the old').action ->  process.nextTick ->
	app.clone()

# status
cli.command('status').description('check the git status of our plugins')
	.action ->  process.nextTick ->
		app.status({
			only: splitCsvValue(cli.only)
			skip: splitCsvValue(cli.skip) or defaultSkip
			startFrom: cli.start
		})

# test
cli.command('test').description('run the tests')
	.action ->  process.nextTick ->
		app.test({
			only: splitCsvValue(cli.only)
			skip: splitCsvValue(cli.skip) or defaultSkip
			startFrom: cli.start
		})

# Start the CLI
cli.parse(process.argv)

# App
app = new App({
	pluginsPath: pathUtil.join(__dirname, 'plugins')
	skeletonsPath: pathUtil.join(__dirname, 'skeletons')
	debug: cli.debug
}).ensure()
defaultSkip = ['pygments','concatmin','iis','html2jade','html2coffee','robotskirt','tumblr','contenttypes']
