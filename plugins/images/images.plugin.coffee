module.exports = (BasePlugin) ->
	
	fs   = require 'fs'
	path = require 'path'
	_    = require 'underscore'
		
	class Images extends BasePlugin
		
		name: 'images'

		render: ({inExtension, outExtension, template, file}, next) ->
			
			if outExtension is 'html'
				name = file.basename
				if name isnt undefined
				
					# create a folder for images if one doesn't exist
					if not path.existsSync('./src/public/images/' + name)
						fs.mkdirSync('./src/public/images/' + name)
				
					# create an array of paths to images
					dirs = fs.readdirSync('./src/public/images/' + name)
				
					# filter out .DS_Store files on OS X
					if dirs[0] is '.DS_Store' then dirs = dirs.splice(1)
					
					# create full paths and assign to file.images
					# this will be available as '@document.images' in templates
					file.images = _.map(dirs, (dir) -> return '/images/' + name + '/' + dir)
			
			return next?()
