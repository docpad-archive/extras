# Export Plugin
module.exports = (BasePlugin) ->
	# Define Plugin
	class CoffeekupPlugin extends BasePlugin
		# Plugin name
		name: 'coffeekup'

		# Plugin config
		# Only on the development environment, should we format the coffeecup output
		config:
			coffeecup:
				format: false
			environments:
				development:
					coffeecup:
						format: true


		# =============================
		# Renderers

		# Render CoffeeKup
		renderCoffeeKup: (opts,next) ->
			# Prepare
			{templateData,content} = opts
			ck = require('coffeecup')
			ckOptions = require('bal-util').deepExtendPlainObjects({}, @config.coffeekup, @config.coffeecup)

			# Render
			opts.content = ck.render(
				content,
				templateData,
				ckOptions
			)

			# Done
			next()

		# =============================
		# Events

		# Render
		# Called per document, for each extension conversion. Used to render one extension to another.
		render: (opts,next) ->
			# Prepare
			{inExtension,outExtension} = opts

			# CoffeeKup
			if inExtension is 'coffee' and (outExtension in ['js','css']) is false
				# Render and complete
				@renderCoffeeKup(opts,next)

			# Something else
			else
				# Nothing to do, return back to DocPad
				return next()
