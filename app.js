'use strict'

// Requires
const pathUtil = require('path')
const readdirCluster = require('readdir-cluster')
const safefs = require('safefs')
const safeps = require('safeps')
const eachr = require('eachr')
const commander = require('commander')
const feedr = require('feedr').create()
const { TaskGroup } = require('taskgroup')

function readdir (path, next) {
	const paths = []
	function iterator (fullPath, relativePath, statObject) {
		if (statObject.directory) {
			const basename = pathUtil.basename(relativePath)
			paths.push({ fullPath, relativePath, basename })
		}
		return false
	}
	readdirCluster(path, iterator, function (err) {
		if (err) return next(err)
		return next(null, paths.sort((a, b) => a.basename > b.basename))
	})
}

function rundir (path, iterator, next) {
	readdir(path, function (err, paths) {
		if ( err )  return next(err)
		const tasks = new TaskGroup('rundir').done(next)
		paths.forEach(function (path) {
			tasks.addTask(`rundir ${path.fullPath}`, function (complete) {
				iterator(path, complete)
			})
		})
		tasks.run()
	})
}

function fetchTopic (topic, next) {
	const feedOpts = {
		requestOptions: {
			headers: {
				Accept: 'application/vnd.github.mercy-preview+json'
			}
		},
		url: `https://api.github.com/search/repositories?page=1&per_page=100&q=topic%3A${topic}+org%3Adocpad`,
		parse: 'json'
	}
	return feedr.readFeed(feedOpts, next)
}

function splitCsvValue (result) {
	return (result && result.split(',')) || null
}


// -----------------
// App

class App {
	constructor (opts) {
		// Prepare
		this.runner = null
		this.logger = null
		this.config = opts

		// Logger
		const level = 6
		this.logger = require('caterpillar').create({ level })
		this.logger
			.pipe(require('caterpillar-filter').create())
			.pipe(require('caterpillar-human').create())
			.pipe(process.stdout)

		// Runner
		this.runner = new TaskGroup('runner').done(function (err) {
			if (err) {
				console.error(err.stack)
			}
			else {
				console.log('done')
			}
		})

		// Start after loaded
		process.nextTick(() => this.runner.run())
	}

	// Log alias
	log (...args) {
		this.logger.log(...args)
	}

	// Action
	ensure (opts, next) {
		const { skeletonsPath, pluginsPath } = this.config

		this.runner.addTaskGroup('ensure', function (addTaskGroup, addTask) {
			addTask('plugins', function (complete) {
				safefs.ensurePath(pluginsPath, complete)
			})
			addTask('skeletons', function (complete) {
				safefs.ensurePath(skeletonsPath, complete)
			})
		})

		if (next) this.runner.addTask('ensure completion callback', next)

		return this
	}

	// Action
	clone (opts, next) {
		const me = this
		const { skeletonsPath, pluginsPath } = this.config
		const exchange = require('./exchange.json')
		const unsupported = {}

		this.runner.addTaskGroup('clone', function (addTaskGroup, addTask) {
			// Unsupported
			addTask('unsupported', function (complete) {
				me.log('info', 'Fetching unsupported items')
				fetchTopic('unsupported', function (err, result) {
					if (err) return next(err)
					result.items.forEach(function (repo) {
						unsupported[repo.name] = true
					})
					me.log('info', `Fetched ${result.items.length} unsupported items`)
					complete()
				})
			})


			// Plugins
			addTask('plugins', function (complete) {
				me.log('info', 'Fetching latest plugins')
				fetchTopic('docpad-plugin', function (err, result) {
					// Check
					if (err) return next(err)
					me.log('info', `Fetched ${result.items.length} plugins`)

					// Add the ones we want
					const cloneRepos = []
					result.items.forEach(function (repo) {
						// Unsupported
						if (typeof unsupported[repo.name] !== 'undefined') {
							me.log('debug', `Skipping unsupported plugin: ${repo.name}`)
							return true
						}

						// Add to clone list
						const shortname = repo.name.replace(/^docpad-plugin-/, '')
						cloneRepos.push({
							name: repo.name,
							url: repo.clone_url,
							path: `${pluginsPath}/${shortname}`,
							branch: 'master'
						})
					})

					// Log
					me.log('info', `Cloning ${cloneRepos.length} plugins`)

					// Clone the repos
					me.cloneRepos({ repos: cloneRepos }, complete)
				})
			})

			// Skeletons
			addTask('skeletons', function (complete) {
				me.log('info', 'Cloning latest skeletons')

				const cloneRepos = []
				eachr(exchange.skeletons, function (repo, key) {
					// Unsupported
					if (typeof unsupported[repo.name] !== 'undefined') {
						me.log('debug', `Skipping unsupported skeleton: ${repo.name}`)
						return true
					}

					// Add to clone list
					const shortname = repo.repo.toLowerCase()
						.replace(/^.+\/(.+\/.+)\.git$/, '$1')
						.replace('/', '-')
						.replace('docpad-skeleton-', '')
						.replace('.docpad', '')
					cloneRepos.push({
						name: key,
						url: repo.repo,
						path: `${skeletonsPath}/${shortname}`,
						branch: repo.branch
					})
				})

				// Clone the repos
				me.cloneRepos({ repos: cloneRepos }, complete)
			})

		})

		if (next) this.runner.addTask('clone completion callback', next)

		return this
	}

	// Helper
	cloneRepos (opts = {}, next) {
		// Prepare
		const me = this
		const cloneTasks = new TaskGroup('clone repos').done(next)

		// Clone each one
		eachr(opts.repos, function (repo) {
			// Prepare
			cloneTasks.addTask(`init repo ${repo}`, function (next) {
				safefs.ensurePath(repo.path, function (err) {
					if (err) return next(err)

					// Prepare
					const repoOpts = {
						cwd: repo.path,
						branch: repo.branch,
						url: repo.url,
						remote: 'origin'
					}

					// Prepare
					safeps.initGitRepo(repoOpts, function (err) {
						if (err) {
							me.log('info', `Fetching ${repo.name} FAILED`, err)
							return next(err)
						}
						else {
							me.log('info', `Fetched ${repo.name}`)
						}
						return next()
					})
				})
			})
		})

		// Run
		cloneTasks.run()
	}

	status (opts = {}, next) {
		const me = this
		const { pluginsPath } = this.config
		const { only } = opts

		this.runner.addTask('status', function (next) {
			rundir(pluginsPath, function ({ fullPath, relativePath, basename }, next) {
				const pluginName = basename, pluginPath = fullPath

				// Skip
				if (only && only.indexOf(pluginName) === -1) {
					me.log('info', `Skipping ${pluginName} - not only`)
					return
				}

				// Execute the plugin's tests
				const options = { cwd: pluginPath }
				safeps.spawn(['git', 'status'], options, function (err, stdout, stderr) {
					// Log
					if ( !stdout || stdout.toString().indexOf('nothing to commit') === -1) {
						me.log('info', pluginPath)
						if (stdout) process.stdout.write(stdout)
						if (stderr) process.stderr.write(stderr)
					}

					// Done
					next(err)
				})
			}, next)
		})

		if (next) this.runner.addTask('status complete callback', next)
		return this
	}

	outdated (opts = {}, next) {
		const me = this
		const { pluginsPath } = this.config
		const { only } = opts

		this.runner.addTask('outdated', function (next) {
			rundir(pluginsPath, function ({ fullPath, relativePath, basename }, next) {
				const pluginName = basename, pluginPath = fullPath

				// Skip
				if (only && only.indexOf(pluginName) === -1) {
					me.log('info', `Skipping ${pluginName} - not only`)
					return
				}

				// Execute the plugin's tests
				me.log('info', pluginPath)
				const nodeVersion = require(pathUtil.join(pluginPath, 'package.json')).engines.node
				me.log('info', `Plugin ${basename} supports node ${nodeVersion}`)
				safeps.spawn(['npm', 'outdated'], { cwd: pluginPath, stdio: 'inherit' }, () => next())
			}, next)
		})

		if (next) this.runner.addTask('outdated complete callback', next)
		return this
	}

	standardize (opts = {}, next) {
		const me = this
		const { pluginsPath } = this.config
		const { only } = opts

		this.runner.addTask('standardize', function (next) {
			rundir(pluginsPath, function ({ fullPath, relativePath, basename }, complete) {
				const pluginName = basename, pluginPath = fullPath
				const cmdOpts = { cwd: pluginPath, stdio: 'inherit' }

				// Skip
				if (only && only.indexOf(pluginName) === -1) {
					me.log('info', `Skipping ${pluginName} - not only`)
					return
				}

				// Log
				me.log('info', `Standardizing ${pluginName} - commit the changes manually`)
				safeps.spawn(['bevry-base'], cmdOpts, next)
			}, next)
		})

		if (next) this.runner.addTask('standardize complete callback', next)
		return this
	}

	exec (opts = {}, next) {
		const me = this
		const { pluginsPath } = this.config

		this.runner.addTask('exec', function (next) {
			rundir(pluginsPath, function ({ fullPath, relativePath }, next) {
				const pluginPath = fullPath
				me.log('info', `exec [${opts.command}] on: ${pluginPath}`)
				safeps.exec(opts.command, { cwd: pluginPath, stdio: 'inherit' }, next)
			}, next)
		})

		if (next) this.runner.addTask('exec complete callback', next)
		return this
	}

	test (opts = {}, next) {
		const me = this
		const { pluginsPath } = this.config
		const { only, startFrom } = opts

		this.runner.addTask('test', function (next) {
			// Require Joe Testing Framework
			process.env.JOE_REPORTER = 'console'
			const joe = require('joe')
			let pluginPaths = null

			// Start playing eye of the tiger
			// require('open')('http://youtu.be/2WrEmJpV2ic')

			// Exchange
			joe.suite('docpad-extras', function (suite, test) {
				test('exchange', function () {
					require('./exchange.json')
				})

				test('paths', function (complete) {
					readdir(pluginsPath, function (err, paths) {
						if (err) return complete(err)
						pluginPaths = paths
						complete()
					})
				})

				suite('plugins', function (suite, test) {
					pluginPaths.forEach(function ({ fullPath, basename }) {
						const pluginName = basename, pluginPath = fullPath

						// Skip
						if (startFrom && startFrom > pluginName) {
							me.log('info', `Skipping ${pluginName} - before start`)
							return
						}
						if (only && only.indexOf(pluginName) === -1) {
							me.log('info', `Skipping ${pluginName} - not only`)
							return
						}

						// Test the plugin
						test(pluginName, function (next) {
							// Prepare
							const cmdOpts = { stdio: 'inherit', cwd: pluginPath }

							// Commands
							const commands = [
								['rm', '-Rf', 'node_modules', 'yarn.lock'],
								['npm', 'link', 'docpad'],
								['npm', 'install'],
								['npm', 'run', 'our:compile'],
								['npm', 'test'],
								['testen', '-s']
							]

							// Spawn
							safeps.spawnMultiple(commands, cmdOpts, next)
						})
					})
				})

				test('complete', function () {
					next()
				})
			})
		})

		if (next) this.runner.addTask('test complete callback', next)
		return this
	}

	cli () {
		// Use [Commander](https://github.com/visionmedia/commander.js/) for command and option parsing
		const app = this
		const cli = commander

		// Extract out version out of our package and apply it to commander
		cli.version(
			require('./package.json').version
		)

		// Options
		cli
			.option('--only <only>', 'only run against these plugins (CSV)')
			.option('--start <start>', 'start from this plugin name')

		// exec
		cli.command('exec <command>').description('execute a command for each plugin').action(function (command) {
			app.exec({ command })
		})

		// outdated
		cli.command('outdated').description('check which plugins have outdated dependencies').action(function () {
			app.outdated({
				only: splitCsvValue(cli.only),
				startFrom: cli.start
			})
		})

		// standardize
		cli.command('standardize').description('ensure plugins live up to the latest standards').action(function () {
			app.standardize()
		})

		// clone
		cli.command('clone').description('clone out new plugins and update the old').action(function () {
			app.clone()
		})

		// status
		cli.command('status').description('check the git status of our plugins').action(function () {
			app.status({
				only: splitCsvValue(cli.only),
				startFrom: cli.start
			})
		})

		// test
		cli.command('test').description('run the tests').action(function () {
			app.test({
				only: splitCsvValue(cli.only),
				startFrom: cli.start
			})
		})

		// Start the CLI
		cli.parse(process.argv)
	}
}

// -----------------
// Helpers

// App
new App({
	pluginsPath: pathUtil.join(__dirname, 'plugins'),
	skeletonsPath: pathUtil.join(__dirname, 'skeletons')
}).ensure().cli()
