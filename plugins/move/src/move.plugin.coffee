# Export Plugin
module.exports = (BasePlugin) ->
	# Define Plugin
	class MovePlugin extends BasePlugin
		# Plugin name
		name: 'move'

		# Plugin priority
		priority: 700

		# Render some content
		render: (opts,next) ->
			# Prepare
			{inExtension,outExtension} = opts

			# Check our extensions
			if inExtension in ['move'] and outExtension in ['js',null]
				# Requires
				move = require('move-panta')

				# Render
				opts.content = move.compile(opts.content)

			# Done, return back to DocPad
			return next()