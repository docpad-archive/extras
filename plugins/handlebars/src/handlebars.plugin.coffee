module.exports = (BasePlugin) ->

	# Define Plugin
	class HandlebarsPlugin extends BasePlugin

		# Plugin name
		name: 'handlebars'

		# Plugin priority
		priority: 725

		# Handlebars
		handlebars: null

		# Constructor
		constructor: ->
			# Prepare
			super
			docpad = @docpad
			config = @config
			handlebars = @handlebars = require('handlebars')

			# Add helpers, if defined in docpad.cson
			if @config.helpers
				for own name,helper of @config.helpers
					handlebars.registerHelper(name, helper)

		# Render some content
		render: (opts) ->
			# Prepare
			{inExtension,outExtension,templateData,file,content} = opts
			handlebars = @handlebars

			if inExtension in ['hb', 'hbs', 'handlebars']
				opts.content = handlebars.compile(content)(templateData)
