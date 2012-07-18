# Export Plugin
module.exports = (BasePlugin) ->
	# Define Plugin
	class Html2coffeePlugin extends BasePlugin
		# Plugin name
		name: 'html2coffee'


		# =============================
		# Renderers

		# Render HTML To Coffee
		renderHTMLToCoffee: (opts,next) ->
			# Prepare
			{templateData,content} = opts
			html2coffee = require('html2coffeekup')

			# Render asynchronously
			outputStream = {
				content: ''
				write: (data) ->
					@content += data
			}
			html2coffee.convert content, outputStream, (err) ->
				# Check for error
				return next(err)  if err
				# Apply
				opts.content = outputStream.content
				# Done, return back to DocPad
				return next()


		# =============================
		# Events

		# Render
		# Called per document, for each extension conversion. Used to render one extension to another.
		render: (opts,next) ->
			# Prepare
			{inExtension,outExtension} = opts

			# HTML to Coffee
			if inExtension is 'html' and outExtension is 'coffee'
				# Render and complete
				@renderHTMLToCoffee(opts,next)

			# Something else
			else
				# Nothing to do, return back to DocPad
				return next()
