# Export Plugin
module.exports = (BasePlugin) ->
	# Define Plugin
	class MarkdownPlugin extends BasePlugin
		# Plugin name
		name: 'markdown'

		# Render some content
		render: (opts) ->
			# Prepare
			{inExtension,outExtension} = opts

			# Check our extensions
			if inExtension in ['md','markdown'] and outExtension in [null,'html']
				# Requires
				markdown = require('github-flavored-markdown')

				# Render
				opts.content = markdown.parse(opts.content)
