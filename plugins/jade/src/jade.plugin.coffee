# Export Plugin
module.exports = (BasePlugin) ->
	# Define Plugin
	class JadePlugin extends BasePlugin
		# Plugin name
		name: 'jade'

		# Render some content
		render: (opts,next) ->
			# Prepare
			{inExtension,templateData,file} = opts

			# Check our extension
			if inExtension is 'jade'
				# Requires
				jade = require('jade')

				# Render
				opts.content = jade.compile(opts.content, {
					filename: file.get('fullPath')
				})(templateData)

			# Done, return back to DocPad
			return next()
