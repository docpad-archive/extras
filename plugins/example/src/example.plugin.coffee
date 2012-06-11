# Export Plugin
module.exports = (BasePlugin) ->
	# Define Plugin
	class ExamplePlugin extends BasePlugin
		# Plugin name
		name: 'example'

		# Setup the Console Interface
		consoleSetup: (opts,next) ->
			# Prepare
			{interface,program} = opts

			# Extend the CLI
			program
				.command('example-question')
				.description("we'll ask you a question")
				.action (command) ->
					interface.applyConfiguration(command)
					me.question(opts,interface.actionCompleted)
	der(content,templateData)

			# Done, return back to DocPad
			return next()

		# Ask the user a question
		question: (opts,next) ->
			# Prepare
			{interface,program} = opts

			# Get username
			program.promptSingleLine 'Type something?\n> ',  (input) ->
				console.log "You typed: #{input}"
				next()
