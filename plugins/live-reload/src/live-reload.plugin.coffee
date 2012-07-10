# Export Plugin
module.exports = (BasePlugin) ->
	# Define Plugin
	class LiveReloadPlugin extends BasePlugin
		# Plugin Name
		name: 'live-reload'

		# Are we enabled?
		# As for production environments we probably do not want this
		isEnabled: ->
			# Prepare
			docpad = @docpad

			# Check environment
			if docpad.getEnvironment() is 'production'
				return false
			else
				return true

		# Extend Collections
		# Used to inject our scripts block with our socket.io regenerate listener
		extendCollections: (opts) ->
			# Prepare
			return @  unless @isEnabled()
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
			return @  unless @isEnabled()
			{server} = opts

			# Initialise Now
			@socketApp = require('socket.io').listen(server).of('/docpad-live-reload')

			# Chain
			@

		# Generate After
		generateAfter: (opts) ->
			# Prepare
			return @  unless @isEnabled()

			# Notify client
			@socketApp?.emit('regenerated')

			# Chain
			@
