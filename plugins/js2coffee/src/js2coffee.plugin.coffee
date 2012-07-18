# Export Plugin
module.exports = (BasePlugin) ->
	# Define Plugin
	class Js2coffeePlugin extends BasePlugin
		# Plugin name
		name: 'js2coffee'


		# =============================
		# Renderers

		# Render JavaScript to CoffeeScript
		renderJavaScriptToCoffeeScript: (opts,next) ->
			# Prepare
			{templateData,content} = opts
			js2coffee = require('js2coffee/lib/js2coffee.coffee')

			# Render
			opts.content = js2coffee.build(content)

			# Done
			next()


		# =============================
		# Events

		# Render
		# Called per document, for each extension conversion. Used to render one extension to another.
		render: (opts,next) ->
			# Prepare
			{inExtension,outExtension} = opts

			# JavaScript to CoffeeScript
			if inExtension is 'js' and outExtension is 'coffee'
				# Render and complete
				@renderJavaScriptToCoffeeScript(opts,next)

			# Something else
			else
				# Nothing to do, return back to DocPad
				return next()
