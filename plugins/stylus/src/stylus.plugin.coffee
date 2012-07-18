# Export Plugin
module.exports = (BasePlugin) ->
	# Define Plugin
	class StylusPlugin extends BasePlugin
		# Plugin name
		name: 'stylus'

		# Plugin config
		config:
			useNib: true
			compress: true
			environments:
				development:
					compress: false

		# Render some content
		render: (opts,next) ->
			# Prepare
			{inExtension,outExtension,content,file} = opts

			# Check extensions
			if inExtension in ['styl','stylus'] and outExtension in ['css',null]
				# Load stylus
				stylus = require('stylus')

				# Create our style
				style = stylus(opts.content)
					.set('filename', file.get('fullPath'))
					.set('compress', @config.compress)

				# Use nib if we want to
				if @config.useNib
					nib = require('nib')
					style.use nib()

				# Render our style
				style.render (err,output) ->
					# Check for errors, and return to docpad if so
					return next(err)  if err
					# Apply result
					opts.content = output
					# Done, return to docpad
					return next()

			# Some other extension
			else
				# Nothing to do, return back to DocPad
				return next()

