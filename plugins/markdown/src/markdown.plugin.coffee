# Export Plugin
module.exports = (BasePlugin) ->
	# Define Plugin
	class MarkdownPlugin extends BasePlugin
		# Plugin name
		name: 'markdown'

		# Render some content
		render: (opts,next) ->
			# Prepare
			{inExtension,outExtension} = opts

			# Check our extensions
			if inExtension in ['md','markdown'] and outExtension in [null,'html']
				# Requires
				marked = require 'marked'

				marked.setOptions({
					gfm: true
					pedantic: false
					sanitize: true
					highlight: null
				})

				# Render
				opts.content = marked(opts.content)

			# Done
			next()