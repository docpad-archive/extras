# Export Plugin
module.exports = (BasePlugin) ->
	# Define Plugin
	class MarkdownPlugin extends BasePlugin
		# Plugin name
		name: 'markdown'

		# Constructor
		constructor: (opts) ->
			# Prepare
			super

			# Mention deprecation
			@docpad.log 'warn', """
				\nThe markdown plugin is now deprecated in favor of the marked plugin, it will continue to work but will no longer be maintained.
				You can read more about this change here: https://github.com/bevry/docpad-extras/pull/15
				When you are ready to upgrade, run:
					npm uninstall docpad-plugin-markdown
					npm install --save docpad-plugin-marked
				"""

		# Render some content
		render: (opts,next) ->
			# Prepare
			{inExtension,outExtension} = opts

			# Check our extensions
			if inExtension in ['md','markdown'] and outExtension in [null,'html']
				# Requires
				markdown = require('github-flavored-markdown')

				# Render
				opts.content = markdown.parse(opts.content)

			# Done
			next()