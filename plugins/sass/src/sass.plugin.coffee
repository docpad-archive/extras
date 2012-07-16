# Export Plugin
module.exports = (BasePlugin) ->
	# Requires
	balUtil = require('bal-util')

	# Define Plugin
	class SassPlugin extends BasePlugin
		# Plugin name
		name: 'sass'

		# Plugin config
		config:
			outputStyle: 'expanded'
			environments:
				production:
					outputStyle: 'compressed'

		# Prevent underscore
		extendCollections: (opts) ->
			# Prepare
			config = @config
			config.renderUnderscoreStylesheets ?= false
			docpad = @docpad

			# Prevent underscore files from being written if desired
			if config.renderUnderscoreStylesheets is false
				@underscoreStylesheets = docpad.getDatabase().findAllLive(filename: /^_\w+\.(?:scss|sass)$/)
				@underscoreStylesheets.on 'add', (model) ->
					model.set({
						render: false
						write: false
					})

		# Render some content
		render: (opts,next) ->
			# Prepare
			config = @config
			{inExtension,outExtension,file} = opts

			# If SASS/SCSS then render
			if inExtension in ['sass','scss'] and outExtension in ['css',null]
				# Fetch useful paths
				fullDirPath = file.get('fullDirPath')

				# Prepare the command and options
				commandOpts = {stdin:opts.content}
				command = [inExtension, '--stdin', '--no-cache']
				if fullDirPath
					command.push('--load-path')
					command.push(fullDirPath)
				if config.compass
					command.push('--compass')
				if config.outputStyle
					command.push('--style')
					command.push(config.outputStyle)

				# Spawn the appropriate process to render the content
				balUtil.spawn command, commandOpts, (err,stdout,stderr,code,signal) ->
					return next(err)  if err
					opts.content = stdout
					return next()

			else
				# Done, return back to DocPad
				return next()