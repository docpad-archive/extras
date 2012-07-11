# Export Plugin
module.exports = (BasePlugin) ->
	# Define Plugin
	class HoganPlugin extends BasePlugin
		# Plugin name
		name: 'hogan'

		# Render some content
		render: (opts,next) ->
			# Prepare
			{inExtension,templateData} = opts

			# Check extensions
			if inExtension is 'hogan'
				# Requires
				hogan = require('hogan.js')

				# Render
				opts.content = hogan.compile(opts.content).render(templateData)

			# Done, return back to DocPad
			return next()