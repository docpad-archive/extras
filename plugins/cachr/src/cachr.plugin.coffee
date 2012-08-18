# Export Plugin
module.exports = (BasePlugin) ->
	# Requires
	balUtil = require('bal-util')
	request = require('request')
	pathUtil = require('path')
	fsUtil = require('fs')

	# Define Plugin
	class CachrPlugin extends BasePlugin
		# Plugin Name
		name: 'cachr'

		# Default Configuration
		config:
			refreshCache: false
			urlPrefix: '/_docpad/plugins/cachr'
			pathPrefix: pathUtil.join('_docpad', 'plugins', 'cachr')

		# URLs to Cache
		urlsToCache: null  # Object
		urlsToCacheLength: 0


		# -----------------------------
		# Helpers

		# Queue Remote Url Sync
		# Mapped to templateData.cachr
		# Takes a remote url and queues it for caching
		queueRemoteUrlSync: (sourceUrl) ->
			# Prepare
			docpad = @docpad
			config = @config

			# Generate a path to return immediatly
			name = require('crypto').createHash('md5').update(sourceUrl).digest('hex')+pathUtil.extname(sourceUrl).replace(/[\?\#].*$/,'')
			details =
				name: name
				sourceUrl: sourceUrl
				cacheUrl: "#{config.urlPrefix}/#{name}"
				cachePath: pathUtil.resolve(docpad.config.outPath, config.pathPrefix, name)

			# Store it for saving later
			@urlsToCache[sourceUrl] = details
			@urlsToCacheLength++

			# Return the cached url
			return details.cacheUrl


		# Save Remote Url
		# Store a remote url
		# next(err,details)
		cacheRemoteUrl: (details,next) ->
			# Prepare
			docpad = @docpad
			attempt = 1

			# Get the file
			viaRequest = ->
				# Log
				docpad.log 'debug', "Cachr is fetching [#{details.sourceUrl}] to [#{details.cachePath}]"

				# Fetch and Save
				request {uri:details.sourceUrl, encoding:null}, (err, response, body) ->
					if err
						++attempt
						if attempt is 3
							# give up, and delete out cachePath if it exists
							docpad.log 'debug', "Cachr is gave up fetching [#{details.sourceUrl}] to [#{details.cachePath}]"
							balUtil.exists details.cachePath, (exists) ->
								if exists
									balUtil.unlink details.cachePath, (err2) ->
										return next(err)
								else
									return next(err)
						else
							return viaRequest()  # try again
					else
						# success
						docpad.log 'debug', "Cachr fetched [#{details.sourceUrl}] to [#{details.cachePath}]"
						# write
						balUtil.writeFile details.cachePath, body, (err) ->
							return next(err)  # forward

			# Check if we should get the data from the cache or do a new request
			if @config.refreshCache
				viaRequest()
			else
				# Check if we should get the data from the cache or do a new request
				balUtil.isPathOlderThan details.cachePath, 1000*60*5, (err,older) ->
					# Check
					return next(err)  if err

					# The file doesn't exist, or exists and is old
					if older is null or older is true
						# Refresh
						return viaRequest()
					# The file exists and relatively new
					else
						# So we don't care
						return next()

			# Chain
			@


		# -----------------------------
		# Events

		# Render Before
		# Map the templateData functions
		renderBefore: ({templateData}, next) ->
			# Prepare
			cachr = @
			@urlsToCache = {}
			@urlsToCacheLength = 0

			# Apply
			templateData.cachr = (sourceUrl) ->
				return cachr.queueRemoteUrlSync(sourceUrl)

			# Next
			next()

			# Chain
			@


		# Write After
		# Store all our files to be cached
		writeAfter: ({templateData}, next) ->
			# Prepare
			cachr = @
			docpad = @docpad
			config = @config
			urlsToCache = @urlsToCache
			urlsToCacheLength = @urlsToCacheLength
			cachrPath = pathUtil.resolve(docpad.config.outPath, config.pathPrefix)
			failures = 0

			# Check
			unless urlsToCacheLength
				return next()

			# Log
			docpad.log 'debug', "Cachr is caching #{urlsToCacheLength} files..."

			# Ensure Path
			balUtil.ensurePath cachrPath, (err) ->
				# Check
				return next(err)  if err

				# Async
				tasks = new balUtil.Group (err) =>
					docpad.log (if failures then 'warn' else 'debug'), 'Cachr finished caching', (if failures then "with #{failures} failures" else '')
					return next()

				# Store all our files to be cached
				balUtil.each urlsToCache, (details,sourceUrl) ->
					tasks.push (complete) ->
						cachr.cacheRemoteUrl details, (err) ->
							if err
								docpad.log 'warn', "Cachr failed to fetch: #{sourceUrl}"
								docpad.error(err)
								++failures
							return complete()

				# Fire the tasks together
				tasks.async()

				# Chain
				@

			# Chain
			@