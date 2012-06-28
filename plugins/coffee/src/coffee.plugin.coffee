# Export Plugin
module.exports = (BasePlugin) ->
	# Define Plugin
	class CoffeePlugin extends BasePlugin
		# Plugin name
		name: 'coffee'

		# Plugin priority
		priority: 700


		# =============================
		# Renderers

		# Render CoffeeKup
		renderCoffeeKup: (opts,next) ->
			# Prepare
			{templateData,content} = opts
			ck = require('coffeecup')

			# Render
			opts.content = ck.render(
				content,
				templateData,
				(@config.coffeekup or @config.coffeecup or {})
			)

			# Done
			next()

		# Render HTML To CoffeeKup
		renderHTMLToCoffeKup: (opts,next) ->
			# Prepare
			{templateData,content} = opts
			html2ck = require('html2coffeekup')

			# Render asynchronously
			outputStream = {
				content: ''
				write: (data) ->
					@content += data
			}
			html2ck.convert content, outputStream, (err) ->
				# Check for error
				return next(err)  if err
				# Apply
				opts.content = outputStream.content
				# Done, return back to DocPad
				return next()

		# Render CoffeeScript to JavaScript
		renderCoffeeScriptToJavaScript: (opts,next) ->
			# Prepare
			{content} = opts
			coffee = require('coffee-script')

			# Render
			opts.content = coffee.compile(content)

			# Done
			next()

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

			# CoffeeKup
			if inExtension in ['coffeekup','coffeecup','ck'] or (inExtension is 'coffee' and !(outExtension in ['js','css']))
				# Render and complete
				@renderCoffeeKup(opts,next)

			# HTML to CoffeeKup
			else if inExtension is 'html' and outExtension in ['coffeekup','ck','coffee']
				# Render and complete
				@renderHTMLToCoffeeKup(opts,next)

			# CoffeeScript to JavaScript
			else if inExtension is 'coffee' and outExtension is 'js'
				# Render and complete
				@renderCoffeeScriptToJavaScript(opts,next)

			# JavaScript to CoffeeScript
			else if inExtension is 'js' and outExtension is 'coffee'
				# Render and complete
				@renderJavaScriptToCoffeeScript(opts,next)

			# Something else
			else
				# Nothing to do, return back to DocPad
				return next()
