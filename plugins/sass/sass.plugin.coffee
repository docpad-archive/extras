# Export Plugin
module.exports = (BasePlugin) ->
	# Define Plugin
	class SassPlugin extends BasePlugin
		# Plugin name
		name: 'sass'

		# Plugin priority
		priority: 725

		# Render some content
		render: (opts,next) ->
			# Prepare
			{inExtension,outExtension,templateData,file} = opts

			# Check extensions
			if inExtension in ['sass','scss'] and outExtension is 'css'
				# Requires
				sass = require('sass')

				# Render
				opts.content = sass.render(opts.content, {
					filename: file.get('fullPath')
				})

			# Done, return back to DocPad
			return next()