module.exports = (BasePlugin) ->
	# Requires
	html5 = require('html5')
	jsdom = require('jsdom')
	balUtil = require('bal-util')
	hljs = require('highlight.js')

	# Highlight an element
	# next(err)
	highlightElement = (opts) ->
		# Prepare
		{window,element,escape,replaceTab,next} = opts
		parentNode = element
		childNode = element
		source = false
		language = false

		# Is our code wrapped  inside a child node?
		childNode = element
		while childNode.childNodes.length and String(childNode.childNodes[0].tagName).toLowerCase() in ['pre','code']
			childNode = childNode.childNodes[0]

		# Is our code wrapped in a parentNode?
		parentNode = element
		while parentNode.parentNode.tagName.toLowerCase() in ['pre','code']
			parentNode = parentNode.parentNode

		# Check if we are already highlighted
		return next()  if /highlighted/.test(parentNode.className)

		# Grab the source and language
		source = balUtil.removeIndentation(childNode.innerHTML)
		language = String(childNode.getAttribute('lang') or parentNode.getAttribute('lang')).replace(/^\s+|\s+$/g,'')
		unless language
			if childNode.className.indexOf('no-highlight') isnt -1
				language = false
			else
				matches = childNode.className.match(/lang(?:uage)?-(\w+)/)
				if matches and matches.length is 2
					language = matches[1]
				else
					if parentNode.className.indexOf('no-highlight') isnt -1
						language = false
					else
						matches = parentNode.className.match(/lang(?:uage)?-(\w+)/)
						if matches and matches.length is 2
							language = matches[1]

		# Highlight
		if language isnt false
			# Correctly escape the source
			if escape isnt true
				# Unescape the output as highlightjs always escape
				source = source.replace(/&amp;/gm, '&').replace(/&lt;/gm, '<').replace(/&gt;/gm, '>')

			# Highlight
			language = String(language or '').toLowerCase()
			try
				hljs.tabReplace = replaceTab  if replaceTab
				if language and hljs.LANGUAGES[language]?
					result = hljs.highlight(language, source)
				else
					result = hljs.highlightAuto(source)
				language = result.language
				result = result.value
			catch err
				return next(err)  if err
		else
			language = 'no-highlight'
			result = source

		# Handle
		resultElWrapper = window.document.createElement('div')
		resultElWrapper.innerHTML = """
			<pre class="highlighted"><code class="#{language}">#{result}</code></pre>
			"""
		resultElInner = resultElWrapper.childNodes[0]
		parentNode.parentNode.replaceChild(resultElInner,parentNode)
		next()

		# Chain
		@


	# Define Plugin
	class HighlightjsPlugin extends BasePlugin
		# Plugin name
		name: 'highlightjs'

		# Plugin configuration
		config:
			replaceTab: null

		# Render the document
		renderDocument: (opts, next) ->
			{extension,file} = opts
			replaceTab = @config.replaceTab

			# Handle
			if file.type is 'document' and extension is 'html'
				# Create DOM from content
				jsdom.env(
					html: "<html><body>#{opts.content}</body></html>"
					#parser: html5
					features:
						QuerySelector: true
						MutationEvents: false
					done: (err,window) ->
						# Check
						return next(err)  if err

						# Find highlightable elements
						elements = window.document.querySelectorAll(
							'code pre, pre code, .highlight'
						)

						# Check
						if elements.length is 0
							return next()

						# Tasks
						tasks = new balUtil.Group (err) ->
							return next(err)  if err
							# Apply the content
							opts.content = window.document.body.innerHTML
							# Completed
							return next()
						tasks.total = elements.length

						# Syntax highlight those elements
						for value,key in elements
							element = elements.item(key)
							highlightElement({
								window: window
								element: element
								replaceTab: replaceTab
								next: tasks.completer()
							})

						# Done
						true
				)
			else
				return next()