module.exports = (BasePlugin) ->
	# Requires
	jsdom = require('jsdom')
	balUtil = require('bal-util')
	hljs = require('highlight.js')

	isPreOrCode = (element) ->
		return false  unless element.tagName
		element.tagName in ['PRE','CODE']
	
	findLanguage = (element) ->
		classes = element.className
		# No highlighting
		return false  if classes.indexOf('no-highlight') isnt -1

		# Get all of the matching classes
		matches = classes.match(/lang(?:uage)?-\w+/g)
		# Return the last listed language class
		return matches.pop().match(/lang(?:uage)?-(\w+)/)[1] if matches

		# Auto-highlighting
		''	

	# Define Plugin
	class HighlightjsPlugin extends BasePlugin
		# Plugin name
		name: 'highlightjs'

		# Plugin configuration
		config:
			replaceTab: null
			sourceFilter: null
			aliases:
				coffee: 'coffeescript'
				rb: 'ruby'
				js: 'javascript'

		# Highlight an element
		highlightElement: (opts) ->
			# Prepare
			{window,element,replaceTab,sourceFilter,next} = opts
			replaceTab = @config.replaceTab
			aliases = @config.aliases
			sourceFilter = @config.sourceFilter

			# Is the element's code wrapped inside a child node?
			childNode = element
			while childNode.hasChildNodes() and isPreOrCode(childNode.childNodes[0])
				childNode = childNode.childNodes[0]

			# Is the element's code wrapped in a parent node?
			parentNode = element
			while isPreOrCode(parentNode.parentNode)
				parentNode = parentNode.parentNode

			# Skip if the element is already highlighted
			return next()  if parentNode.className.indexOf('highlighted') isnt -1

			# Grab the source code
			source = childNode.innerHTML

			# Discover the language
			language = childNode.getAttribute('lang') or parentNode.getAttribute('lang')

			language = language.trim() or findLanguage(childNode) or findLanguage(parentNode)

			# Highlight
			if language isnt false
				# Correctly escape the source
				if escape isnt true
					# Unescape the output as highlightjs always escape
					source = source.replace(/&amp;/gm, '&').replace(/&lt;/gm, '<').replace(/&gt;/gm, '>')

				# If a source filter is configured, run it
				if sourceFilter?
					if sourceFilter instanceof Function
						# sourceFilter = (source) ->
						source = sourceFilter(source, language)
					else if sourceFilter instanceof Array and sourceFilter.length is 2
						# sourceFilter = ['find' or RegExp, 'replace']
						source = source.replace(sourceFilter[0], sourceFilter[1])

				hljs.fixMarkup(source, replaceTab)  if replaceTab

				# Highlight
				language = language.toLowerCase()
				try
					# Correct aliases
					if language and aliases[language]
						language = aliases[language]

					# Perform the render
					if language and hljs.LANGUAGES[language]?
						result = hljs.highlight(language, source)
					else
						result = hljs.highlightAuto(source)

					# Extract the result
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

		# Render the document
		renderDocument: (opts, next) ->
			{extension,file} = opts
			plugin = @

			# Handle
			if file.type is 'document' and extension is 'html'
				# Create DOM from content
				jsdom.env(
					html: "<html><body>#{opts.content}</body></html>"
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
						return next()  if elements.length is 0

						# Tasks
						tasks = new balUtil.Group (err) ->
							return next(err)  if err
							# Apply the content
							opts.content = window.document.body.innerHTML
							# Completed
							return next()
						tasks.total = elements.length

						# Syntax highlight those elements
						for element in elements
							plugin.highlightElement({
								window: window
								element: element
								sourceFilter: sourceFilter
								next: tasks.completer()
							})

						# Done
						true
				)
			else
				return next()
