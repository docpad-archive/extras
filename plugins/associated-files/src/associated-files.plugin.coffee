# Export Plugin
module.exports = (BasePlugin) ->
	# Define Associated Files Plugin
	class AssociatedFilesPlugin extends BasePlugin
		# Plugin Name
		name: 'associated-files'

		# DocPad is ready now
		# Lets use this time to extend our file model
		docpadReady: (opts) ->
			# Prepare
			{docpad} = opts
			{DocumentModel} = docpad
			pathUtil = require('path')
			fsUtil = require('fs')

			# Fetch our configuration
			associatedFilesPath = @config.associatedFilesPath
			createAssociatedFilesPath = @config.createAssociatedFilesPath

			# Extend our prototype
			DocumentModel::getAssociatedFilesPath = ->
				documentAssociatedFilesPath = @get('associatedFilesPath') or @get('basename')
				documentAssociatedFilesPathNormalized = @getPath(documentAssociatedFilesPath, associatedFilesPath)
				unless documentAssociatedFilesPathNormalized.slice(-1) in ['\\','/']
					documentAssociatedFilesPathNormalized += '/'
				return documentAssociatedFilesPathNormalized
			DocumentModel::getAssociatedFiles = (sorting,paging) ->
				# Prepare
				document = @
				documentAssociatedFilesPath = document.getAssociatedFilesPath()

				# Fetch our associated files, and cache
				associatedFilesCollection = docpad.getFilesAtPath(documentAssociatedFilesPath, sorting, paging)

				# Return
				return associatedFilesCollection

			# All done
			null