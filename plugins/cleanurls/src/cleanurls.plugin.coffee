# Export Plugin
module.exports = (BasePlugin) ->
	# Define Plugin
	class CleanUrlsPlugin extends BasePlugin
		# Plugin Name
		name: 'cleanUrls'

		# Parsing all files has finished
		parseAfter: (opts,next) ->
			# Prepare
			docpad = @docpad
			database = docpad.getDatabase()
			docpad.log 'debug', 'Creating clean urls'

			# Find everything with a html extension
			database.findAll(outPath: $endsWith: '.html').forEach (document) ->
				# Prepare
				documentUrl = document.get('url')

				# Extnesionless URL
				if /\.html$/i.test(documentUrl)
					relativeBaseUrl = '/'+document.get('relativeBase')
					document.addUrl(relativeBaseUrl)
					document.set(url: relativeBaseUrl)

				# Index URL
				if /index\.html$/i.test(documentUrl)
					relativeDirUrl = '/'+document.get('relativeDirPath')
					document.addUrl(relativeDirUrl)
					document.set(url: relativeDirUrl)

			# Done
			docpad.log 'debug', 'Created clean urls'
			next?()