# Export Plugin
module.exports = (BasePlugin) ->
	# Define Plugin
	class UglifyPlugin extends BasePlugin
		# Plugin name
		name: 'uglify'

		# Plugin config
		config:
			strict_semicolons: true

		# =============================
		# Renderers

		# apply uglify-js
		renderUglify: (opts,next) ->
			# Prepare
			{content,file} = opts
			uglifyjs = require "uglify-js"
			{parser,uglify} = uglifyjs

			# Render
			try
				ast = parser.parse content, @config.strict_semicolons
			catch err
				return next(err)
			
			ast = uglify.ast_mangle ast
			ast = uglify.ast_squeeze ast
			opts.content = uglify.gen_code ast

			# Done
			next()

		# =============================
		# Events

		# Render the document
		renderDocument: (opts,next) ->
			# Prepare
			{extension} = opts

			# javascript
			if extension is 'js'
				# Render and complete
				@renderUglify(opts,next)

			# Something else
			else
				# Nothing to do, return back to DocPad
				return next()
