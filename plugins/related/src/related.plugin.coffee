# Export Plugin
module.exports = (BasePlugin) ->
	# Define Relations Plugin
	class RelationsPlugin extends BasePlugin
		# Plugin Name
		name: 'relations'

		# Has inside
		howManyItemsInside: (aArray,bArray) ->
			count = 0
			for aItem in aArray
				for bItem in bArray
					if aItem is bItem
						++count
						break
			return count

		# Parsing all files has finished
		parseAfter: (opts,next) ->
			# Requires
			balUtil = require('bal-util')

			# Prepare
			me = @
			docpad = @docpad
			logger = @logger
			documents = docpad.getCollection('documents')
			targetedDocuments = if @config.collectionName then docpad.getCollection(@config.collectionName) else documents
			docpad.log 'debug', 'Generating relations'

			# Cycle through all our documents
			targetedDocuments.forEach (document) ->
				# Prepare
				tags = document.get('tags') or []

				# Create a live child collection of the related documents
				relatedDocuments = documents
					.findAll(
						tags: '$in': tags
						id: $ne: document.id
					).
					live(true)
					.setComparator (a,b) ->
						return me.howManyItemsInside(a,tags) < me.howManyItemsInside(b,tags)

				# Save
				document.relatedDocuments = relatedDocuments

			# All done
			docpad.log 'debug', 'Generated relations'
			return next()

		# Render Before
		renderBefore: (opts,next) ->
			# Prepare
			docpad = @docpad
			documents = docpad.getCollection(@config.collectionName or 'documents')

			# Cycle through all our documents
			documents.forEach (document) ->
				relatedDocumentsArray = document.relatedDocuments?.toJSON() or []
				document.set(relatedDocuments: relatedDocumentsArray)

			# All done
			return next()