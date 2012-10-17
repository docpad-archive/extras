# Requires
rs = require 'robotskirt'

# Export Plugin
module.exports = (BasePlugin) ->
	# Define Plugin
	class SundownPlugin extends BasePlugin
		# Plugin name
		name: 'sundown'

		# Plugin configuration
		config:
			sundownOptions:
				EXT_AUTOLINK: true
				EXT_FENCED_CODE: true
				EXT_LAX_SPACING: true
				EXT_NO_INTRA_EMPHASIS: true
				EXT_SPACE_HEADERS: true
				EXT_STRIKETHROUGH: true
				EXT_SUPERSCRIPT: true
				EXT_TABLES: true
				HTML_SKIP_HTML: false
				HTML_SKIP_STYLE: false
				HTML_SKIP_IMAGES: false
				HTML_SKIP_LINKS: false
				HTML_EXPAND_TABS: false
				HTML_SAFELINK: false
				HTML_TOC: false
				HTML_HARD_WRAP: false
				HTML_USE_XHTML: true
				HTML_ESCAPE: false
			smartypants: true
			highlight: false

		# sigleton parser
		_parser: null

		# Render some content
		render: (opts,next) ->
			# Prepare
			config = @config
			parser = @_parser
			{inExtension,outExtension} = opts

			# Check our extensions
			if inExtension in ['md','markdown'] and outExtension in [null,'html']
				if !parser
					renderer = new rs.HtmlRenderer()
					# highlight
					renderer.blockcode= config.highlight if config.highlight

					# user inline
					if config.inline
						renderer.normal_text= (src) ->
							blocks = []
							hash= (text)->
								text = text.replace(/(^\n+|\n+$)/g,"")
								"\n\n~K" + (blocks.push(text)-1) + "K\n\n"

							unhash= (src)->
								src.replace /\n\n~K([0-9]+)K\n\n/g, (whole, m1)->
									blocks[m1]

							out = config.inline(src, hash)
							out = unhash( out ) if blocks.length > 0 
							out

					# make options for robotscript
					opts = config.sundownOptions
					for name of opts
						if opts[name]
							if name.indexOf('EXT_') == 0
								extOpts = extOpts || []
								extOpts.push( rs[ name ] )
							if name.indexOf('HTML_') == 0
								htmlOpts = htmlOpts || []
								htmlOpts.push( rs[ name ] )

					@_parser = parser = new rs.Markdown(renderer, extOpts, htmlOpts);
				# end parser construction 

				# Render
				opts.content = parser.render(opts.content)

				#SmartyPants
				if config.smartypants
					opts.content = rs.smartypantsHtml(opts.content) 

			# Done
			next()
