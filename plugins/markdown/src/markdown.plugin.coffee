# Export Plugin
module.exports = (BasePlugin) ->
	# Requires
	marked = require 'marked'
	hl = require 'highlight.js'
	_ = require 'underscore'

	makesure = (name) ->
		if _.isString name
			ret = name.trim()
			return ret if _(hl.LANGUAGES).has ret

		null

	# Define Plugin
	class MarkdownPlugin extends BasePlugin
		# Plugin name
		name: 'markdown'

		# Render some content
		render: (opts,next) ->
			# Prepare
			{inExtension,outExtension} = opts

			# Check our extensions
			if inExtension in ['md','markdown'] and outExtension in [null,'html']
				# Default options
				options =
					gfm: true
					pedantic: false
					sanitize: true
					highlight: null

				# Merge options
				if @config.highlight
					options = _.extend options, @config,
						highlight: (code, language) ->
							lang = makesure language
							if lang
								return hl.highlight(lang, code).value
							else
								return hl.highlightAuto(code).value
				else
					options = _.extend options, @config


				marked.setOptions options

				# Render
				opts.content = marked opts.content

			# Done
			next()
