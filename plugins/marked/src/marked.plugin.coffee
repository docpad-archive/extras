# Export Plugin
module.exports = (BasePlugin) ->
	# Define Plugin
	class MarkedPlugin extends BasePlugin
		# Plugin name
		name: 'marked'

		# Plugin configuration
		config:
			markedOptions:
				pedantic: false
				gfm: true
				sanitize: true
				highlight: null

		# Render some content
		render: (opts,next) ->
			# Prepare
			config = @config
			{inExtension,outExtension} = opts

			# Check our extensions
			if inExtension in ['md','markdown'] and outExtension in [null,'html']
				# Requires
				marked = require('marked')
				marked.setOptions(config.markedOptions)

				# Render
				opts.content = marked(opts.content)

			# Done
			next()
