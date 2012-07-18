# Export Plugin
module.exports = (BasePlugin) ->
	# Define Plugin
	class CoffeescriptPlugin extends BasePlugin
		# Plugin name
		name: 'coffeescript'


		# =============================
		# Renderers

		# Render CoffeeScript to JavaScript
		renderCoffeeScriptToJavaScript: (opts,next) ->
			# Prepare
			{content} = opts
			coffee = require('coffee-script')

			# Render
			opts.content = coffee.compile(content)

			# Done
			next()


		# =============================
		# Events

		# Render
		# Called per document, for each extension conversion. Used to render one extension to another.
		render: (opts,next) ->
			# Prepare
			{inExtension,outExtension} = opts

			# CoffeeScript to JavaScript
			if inExtension is 'coffee' and outExtension in ['js',null]
				# Render and complete
				@renderCoffeeScriptToJavaScript(opts,next)

			# Something else
			else
				# Nothing to do, return back to DocPad
				return next()
