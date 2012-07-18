# Export Plugin
module.exports = (BasePlugin) ->
	# Define Plugin
	class LivereloadPlugin extends BasePlugin
		# Plugin configuration
		name: 'livereload'

		# Plugin configuration
		# Only enable us on the development environment
		config:
			enabled: false
			environments:
				development:
					enabled: true

		# Populate Collections
		# Used to inject our scripts block with our socket.io regenerate listener
		populateCollections: (opts) ->
			# Prepare
			docpad = @docpad
			scriptsBlock = docpad.getBlock('scripts')

			# Script
			scriptsBlock.add(
				[
					'/socket.io/socket.io.js',
					"""
						var socket = io.connect('/docpad-live-reload');
						socket.on('regenerated',function(){
							document.location.reload();
						});
					"""
				],
				{
					defer: false
				}
			)

			# Chain
			@

		# Setup After
		# Start our socket.io
		serverAfter: (opts) ->
			# Prepare
			{server} = opts

			# Initialise Now
			@socketApp = require('socket.io').listen(server).of('/docpad-live-reload')

			# Chain
			@

		# Generate After
		generateAfter: (opts) ->
			# Prepare

			# Notify client
			@socketApp?.emit('regenerated')

			# Chain
			@
