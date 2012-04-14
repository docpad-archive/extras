# Export Plugin
module.exports = (BasePlugin) ->
	# Requires
	fs   = require('fs')
	path = require('path')
	_    = require('underscore')
	
	# Define Plugin
	class Images extends BasePlugin
		# Plugin name
		name: 'images'

		# Render some content
		render: (opts,next) ->
			# Prepare
			{inExtension,outExtension,templateData,content,file} = opts

			# Check our extension
			if outExtension is 'html'
				name = file.basename
				if name?
					# Create a folder for images if one doesn't exist
					if not path.existsSync('./src/public/images/' + name)
						fs.mkdirSync('./src/public/images/' + name)
				
					# Create an array of paths to images
					dirs = fs.readdirSync('./src/public/images/' + name)
				
					# Filter out .DS_Store files on OS X
					if dirs[0] is '.DS_Store' then dirs = dirs.splice(1)
					
					# Create full paths and assign to file.images
					# this will be available as '@document.images' in templates
					images = _.map(dirs, (dir) -> return '/images/' + name + '/' + dir)
					document.set({images})
			
			# Done, return back to DocPad
			return next?()
