// Requires
const pathUtil = require('path')
const fsUtil = require('fs')
const readdirCluster = require('readdir-cluster')
const safefs = require('safefs')
const safeps = require('safeps')
const eachr = require('eachr')
const commander = require('commander')
const CSON = require('cson')
const feedr = require('feedr').create()
const { TaskGroup } = require('taskgroup')

// Prepare
const defaultSkip = ['pygments', 'concatmin', 'iis', 'html2jade', 'html2coffee', 'robotskirt', 'tumblr', 'contenttypes']

function readdir(path, next) {
	const paths = []
	function iterator(fullPath, relativePath, statObject) {
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

function rundir(path, iterator, next) {
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

function fetchTopic(topic, next) {
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

// -----------------
// App

class App {
	constructor(opts) {
		// Prepare
		this.runner = null
		this.logger = null
		this.config = opts

		// Logger
		const level = this.config.debug ? 7 : 6
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
	log(...args) {
		this.logger.log(...args)
	}

	// Action
	ensure(opts, next) {
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
	clone(opts, next) {
		const me = this
		const { skeletonsPath, pluginsPath } = this.config
		let exchange = require('./exchange.json')
		let unsupported = {}

		this.runner.addTaskGroup('clone', function (addTaskGroup, addTask) {
			// Unsupported
			addTask('unsupported', function (complete) {
				me.log('info', `Fetching unsupported items`)
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
				me.log('info', `Fetching latest plugins`)
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
				me.log('info', `Cloning latest skeletons`)

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
	cloneRepos(opts = {}, next) {
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
					const spawnCommands = []
					const spawnOpts = {}
					spawnOpts.cwd = repo.path

					// New
					if (fsUtil.existsSync(repo.path + '/.git') === false) {
						spawnCommands.push(['git', 'init'])
						spawnCommands.push(['git', 'remote', 'add', 'origin', repo.url])
					}

					// Update
					spawnCommands.push(['git', 'fetch', 'origin'])
					spawnCommands.push(['git', 'checkout', repo.branch])
					spawnCommands.push(['git', 'pull', 'origin', repo.branch])

					// Re-link
					spawnCommands.push(['npm', 'link', 'docpad'])

					// Handle
					me.log('info', `Fetching ${repo.name} / ${repo.branch}`)
					safeps.spawnMultiple(spawnCommands, spawnOpts, function (err, ...args) {
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

	status(opts = {}, next) {
		const me = this
		const { pluginsPath } = this.config
		const { skip, only } = opts

		this.runner.addTask('status', function (next) {
			rundir(pluginsPath, function ({ fullPath, relativePath, basename }, next) {
				const pluginName = basename, pluginPath = fullPath

				// Skip
				if (skip && skip.indexOf(pluginName) !== -1) {
					me.log('info', `Skipping ${pluginName}`)
					return
				}
				if (only && only.indexOf(pluginName) === -1) {
					me.log('info', `Skipping ${pluginName}`)
					return
				}

				// Execute the plugin's tests
				const options = { cwd: pluginPath, env: process.env }
				safeps.spawnCommand('git', ['status'], options, function (err, stdout, stderr) {
					// Log
					if (stdout && stdout.indexOf('nothing to commit') === -1) {
						if (stdout || stderr) {
							me.log('info', pluginPath)
							if (stdout) me.log('info', stdout)
							if (stderr) me.log('info', stderr)
						}
					}

					// Done
					next(err, true)
				})
			}, next)
		})

		if (next) this.runner.addTask('status complete callback', next)
		return this
	}

	outdated(opts = {}, next) {
		const me = this
		const { pluginsPath } = this.config
		const { skip, only } = opts

		this.runner.addTask('outdated', function (next) {
			rundir(pluginsPath, function ({ fullPath, relativePath, basename }, next) {
				const pluginName = basename, pluginPath = fullPath

				// Skip
				if (skip && skip.indexOf(pluginName) !== -1) {
					me.log('info', `Skipping ${pluginName}`)
					return
				}
				if (only && only.indexOf(pluginName) === -1) {
					me.log('info', `Skipping ${pluginName}`)
					return
				}

				// Execute the plugin's tests
				const options = { cwd: pluginPath }
				safeps.spawnCommand('npm', 'outdated', options, function (err, stdout, stderr) {
					// Log
					// if ( stdout && stdout.indexOf('is specified') isnt -1 ) {
					//   if ( stdout || stderr )  output = pluginPath
					//   if ( stdout ) output += '\n'+stdout.replace(/^npm http .*/m, '')
					//   if ( stderr ) output += '\n'+stderr
					// }
					me.log('info', stdout, stderr)

					// Done
					next(err, true)
				})
			}, next)
		})

		if (next) this.runner.addTask('outdated complete callback', next)
		return this
	}

	standardize(opts = {}, next) {
		const me = this
		const { pluginsPath } = this.config
		const { skip, only } = opts

		this.runner.addTask('standardize', function (next) {
			rundir(pluginsPath, function ({ fullPath, relativePath, basename }, next) {
				const pluginName = basename, pluginPath = fullPath
				const cmdOpts = { cwd: pluginPath, output: true }

				// Skip
				if (skip && skip.indexOf(pluginName) !== -1) {
					me.log('info', `Skipping ${pluginName}`)
					return
				}
				if (only && only.indexOf(pluginName) === -1) {
					me.log('info', `Skipping ${pluginName}`)
					return
				}

				// Log
				me.log('info', `Standardizing ${pluginName}`)
				me.log('debug', `Standardize ${pluginName}: rename contributing`)
				safeps.spawnCommand('git', ['mv', '-f', '-k', 'Contributing.md', 'CONTRIBUTING.md'], cmdOpts, function (err) {
					if (err) return complete(err)

					me.log('debug', `Standardize ${pluginName}: rename history`)
					safeps.spawnCommand('git', ['mv', '-f', '-k', 'History.md', 'HISTORY.md'], cmdOpts, function (err) {
						if (err) return complete(err)

						me.log('debug', `Standardize ${pluginName}: download meta files`)
						safeps.exec(pathUtil.join(__dirname, 'download-meta.bash'), cmdOpts, function (err) {
							if (err) return complete(err)

							// Update the package.json file
							const pluginPackagePath = pluginPath + '/package.json'
							const pluginPackageData = Object.assign({
								engines: {},
								dependencies: {},
								peerDependencies: {},
								devDependencies: {}
							}, require(pluginPackagePath))
							const { engines, dependencies, peerDependencies, devDependencies } = pluginPackageData

							// if deps['taskgroup']
							// 	deps['taskgroup'] = '~4.2.0'
							// ^ can't do this, as it is a API change, so we have to manually update plugins using older taskgroups

							if (engines.docpad) {
								peerDependencies.docpad = engines.docpad
								delete engines.docpad
							}
							peerDependencies.docpad = devDependencies.docpad = '6'

							devDependencies.projectz = '^1.1.0'
							if (devDependencies['coffee-script']) {
								devDependencies['coffee-script'] = '^1.9.1'
							}
							if (devDependencies.joe) {
								devDependencies.joe = '^1.6.0'
							}

							pluginPackageData.bugs.url = `https://github.com/docpad/docpad-plugin-${pluginName}/issues`
							pluginPackageData.repository.url = `https://github.com/docpad/docpad-plugin-${pluginName}.git`
							pluginPackageData.license = 'MIT'
							pluginPackageData.badges = {
								"list": [
									"travisci",
									"npmversion",
									"npmdownloads",
									"daviddm",
									"daviddmdev",
									"---",
									"patreon",
									"opencollective",
									"gratipay",
									"flattr",
									"paypal",
									"bitcoin",
									"wishlist",
									"---",
									"slackin"
								],
								"config": {
									"patreonUsername": "bevry",
									"opencollectiveUsername": "bevry",
									"gratipayUsername": "bevry",
									"flattrUsername": "balupton",
									"paypalURL": "https://bevry.me/paypal",
									"bitcoinURL": "https://bevry.me/bitcoin",
									"wishlistURL": "https://bevry.me/wishlist",
									"slackinURL": "https://slack.bevry.me"
								}
							}
							if (devDependencies['coffee-script']) {
								pluginPackageData.cakeConfiguration = {
									COFFEE_SRC_PATH: `src`
								}
							}

							me.log('debug', `Standardize ${pluginName}: write package`)
							pluginPackageDataString = JSON.stringify(pluginPackageData, null, '  ')
							safefs.writeFile(pluginPackagePath, pluginPackageDataString, function (err) {
								if (err) return complete(err)

								me.log('debug', `Standardize ${pluginName}: install new deps`)
								safeps.spawn(['npm', 'install'], { cwd: pluginPath, output: true, outputPrefix: '>	' }, function (err) {
									if (err) return complete(err)

									me.log('debug', `Standardize ${pluginName}: projectz`)
									projectzPath = pathUtil.join(pluginPath, 'node_modules', '.bin', 'projectz')
									safeps.spawn([projectzPath, 'compile'], { cwd: pluginPath, output: true, outputPrefix: '>	' }, function (err) {
										if (err) return complete(err)

										safeps.spawnCommand('git', ['commit', '-am', 'updated base files'], { cwd: pluginPath, output: true }, function (err, stdout) {
											if (err && stdout.indexOf('nothing to commit') !== -1) return complete()
											if (err) return complete(err)

											safeps.spawnCommand('git', ['push', 'origin', 'master'], { cwd: pluginPath, output: true }, function (err) {
												return complete(err)
											})
										})
									})
								})
							})
						})
					})
				})
			}, next)
		})

		if (next) this.runner.addTask('standardize complete callback', next)
		return this
	}

	exec(opts = {}, next) {
		const me = this
		const { pluginsPath } = this.config

		this.runner.addTask('exec', function (next) {
			rundir(pluginsPath, function ({ fullPath, relativePath }, next) {
				const pluginPath = fullPath
				safeps.exec(opts.command, { cwd: pluginPath, env: process.env }, function (err, stdout, stderr) {
					me.log('info', `exec [${opts.command}] on: ${pluginPath}`)
					if (err) process.stdout.write(stderr)
					process.stdout.write(stdout)
					me.log('info', '')
					return next(err)
				})
			}, next)
		})

		if (next) this.runner.addTask('exec complete callback', next)
		return this
	}

	test(opts = {}, next) {
		const me = this
		const { pluginsPath } = this.config
		const { skip, only, startFrom } = opts

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
					const result = require('./exchange.json')
				})

				test('paths', function (complete) {
					readdir(pluginsPath, function (err, paths) {
						if (err) return complete(err)
						pluginPaths = paths
						complete()
					})
				})

				suite('plugins', function (suite, test) {
					pluginPaths.forEach(function ({ fullPath, relativePath, basename }) {
						const pluginName = basename, pluginPath = fullPath

						// Skip
						if (startFrom && startFrom > pluginName) {
							me.log('info', `Skipping ${pluginName}`)
							return
						}
						if (skip && skip.indexOf(pluginName) !== -1) {
							me.log('info', `Skipping ${pluginName}`)
							return
						}
						if (only && only.indexOf(pluginName) === -1) {
							me.log('info', `Skipping ${pluginName}`)
							return
						}
						if (fsUtil.existsSync(pluginPath + '/test') === false) {
							me.log('info', `Skipping ${pluginName}`)
							return
						}

						// Test the plugin
						test(pluginName, function (done) {
							const options = { output: true, cwd: pluginPath + '/test' }
							safeps.spawn('npm link docpad', options, function (err) {
								// Error
								if (err) return next(err)

								// Prepare
								const cmdOpts = { output: true, cwd: pluginPath }

								// Commands
								const spawnCommands = []
								spawnCommands.push('npm link docpad')
								spawnCommands.push('npm install')
								if (fsUtil.existsSync(pluginPath + '/Cakefile')) {
									spawnCommands.push('cake compile')
								}
								else if (fsUtil.existsSync(pluginPath + '/Makefile')) {
									spawnCommands.push('make compile')
								} else {
									spawnCommands.push('npm run compile')
								}
								spawnCommands.push('npm test')

								// Spawn
								safeps.spawnMultiple(spawnCommands, cmdOpts, function (err, results) {
									// Output the test results for the plugin
									if (results.length === spawnCommands.length) {
										testResult = results[spawnCommands.length - 1]
										err = testResult[0]
										// args = testResult[1...]
										if (err) {
											const joeError = new Error(`Testing ${pluginName} FAILED`)
											// me.log('info', `Testing ${pluginName} FAILED`)
											// if (arg) args.forEach(function (arg) { me.log('info', arg) })
											done(joeError)
										}
										else {
											done()
										}
									}
									else {
										done()
									}

									// All done
									next(err)
								})
							})
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
}

// -----------------
// Helpers

// Handle CSV values
function splitCsvValue(result) {
	return result && result.split(',') || null
}


// -----------------
// Commands

// Use [Commander](https://github.com/visionmedia/commander.js/) for command and option parsing
cli = require('commander')

// Extract out version out of our package and apply it to commander
cli.version(
	require('./package.json').version
)

// Options
cli
	.option('--only <only>', 'only run against these plugins (CSV)')
	.option('--skip <skip>', 'skip these plugins (CSV)')
	.option('--start <start>', 'start from this plugin name')
	.option('-d, --debug', 'output debug messages')

// exec
cli.command('exec <command>').description('execute a command for each plugin').action(function (command) {
	process.nextTick(function () {
		app.exec({ command })
	})
})

// outdated
cli.command('outdated').description('check which plugins have outdated dependencies').action(function () {
	process.nextTick(function () {
		app.outdated({
			only: splitCsvValue(cli.only),
			skip: splitCsvValue(cli.skip) || defaultSkip,
			startFrom: cli.start
		})
	})
})

// standardize
cli.command('standardize').description('ensure plugins live up to the latest standards').action(function () {
	process.nextTick(function () {
		app.standardize()
	})
})

// clone
cli.command('clone').description('clone out new plugins and update the old').action(function () {
	process.nextTick(function () {
		app.clone()
	})
})

// status
cli.command('status').description('check the git status of our plugins').action(function () {
	process.nextTick(function () {
		app.status({
			only: splitCsvValue(cli.only),
			skip: splitCsvValue(cli.skip) || defaultSkip,
			startFrom: cli.start
		})
	})
})

// test
cli.command('test').description('run the tests').action(function () {
	process.nextTick(function () {
		app.test({
			only: splitCsvValue(cli.only),
			skip: splitCsvValue(cli.skip) || defaultSkip,
			startFrom: cli.start
		})
	})
})

// Start the CLI
cli.parse(process.argv)

// App
const app = new App({
	pluginsPath: pathUtil.join(__dirname, 'plugins'),
	skeletonsPath: pathUtil.join(__dirname, 'skeletons'),
	debug: cli.debug
}).ensure()
