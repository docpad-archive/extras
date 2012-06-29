# Export Plugin
module.exports = (BasePlugin) ->
	# Define Associated Files Plugin
	class AssociatedFilesPlugin extends BasePlugin
		# Plugin Name
		name: 'associated-files'

		# Template data to insert
		getTemplateData: ->
			# Prepare
			@associatedFilesPath ?= pathUtil.resolve(@docpad.getConfig().filesPath[0], @config.associatedFilesPath)

			# Return the templateData to apply
			templateData =

				# Fetch the live collection of associated files for the document
				getAssociatedFilesCollection: (documentAssociatedFilesDirectory) ->
					# Prepare
					document = @document
					documentAssociatedFilesDirectory or= @document.get('associatedFilesDirectory') or @document.get('basename')
					documentAssociatedFilesPath = pathUtil.resolve(associatedFilesPath, documentAssociatedFilesDirectory)

					# Fetch our associated files, and cache
					associatedFilesCollection = document.associatedFilesCollection or documents.findAllLive({
						fullPath: $startsWith: documentAssociatedFilesPath
					})

					# Return
					associatedFilesCollection

				# Fetch the live collection of associated files for the document (as an array)
				getAssociatedFiles: (documentAssociatedFilesDirectory) ->
					# Return
					@getAssociatedFilesCollection(documentAssociatedFilesDirectory).toJSON()
