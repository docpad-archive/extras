# Export Plugin
module.exports = (BasePlugin) ->
	# Define Plugin
	class TextPlugin extends BasePlugin
		# Plugin name
		name: 'text'

		# Get the text
		getText: (source,store) ->
			# Prepare fetch
			key = 'store.'+source.replace(/[#\{\(\n]/g,'').trim()

			# Fetch the value
			try
				result = eval(key)
			catch err
				result = source

			# Return
			result

		# Populate text
		populateText: (source,store) ->
			# Prepare
			me = @

			# Replace our text elements
			result = source.replace /\<t(ext)?\>([^\<]+)\<\/t(ext)?\>/g, (str, group1, key, group3) ->
				value = me.getText(key,store)
				if value isnt key
					# facilate deep elements
					value = me.populateText(value,store)
				return value

			# Return
			return result

		# Render the document
		renderDocument: (opts,next) ->
			# Prepare
			me = @
			{templateData,file} = opts

			# Only run on text content
			if file.isText()
				# Populate the text element
				opts.content = me.populateText(opts.content,templateData)

				# Done
				return next()
			else
				return next()
