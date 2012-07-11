# Export Plugin
module.exports = (BasePlugin) ->
	# Define Plugin
	class HerokuPlugin extends BasePlugin
		# Plugin name
		name: "heroku"

		# Files
		files:
			"config.json": """
				{"version":"latest"}
				"""

			"Procfile": """
				web: node server.js
				"""

			"server.js": """
				require('docpad').createInstance(function(err,docpadInstance){
					if (err)  return console.log(err.stack);
					docpadInstance.action('generate server',function(err){
						if (err)  return console.log(err.stack);
						console.log('OK');
					});
				});
				"""

		# Setup the Console Interface
		consoleSetup: (opts,next) ->
			# Prepare
			{docpadInterface,commanderInstance} = opts

			# Extend the CLI
			program
				.command('heroku ')
				.description("deploy to heroku")
				.action (command) ->
					docpadInterface.applyConfiguration(command)
					me.question(opts,docpadInterface.actionCompleted)

			# Done, return back to DocPad
			return next()


		# Ask the user a question
		question: (opts,next) ->
			# Prepare
			{docpadInterface,program} = opts

			# Get username
			program.promptSingleLine 'Type something?\n> ',  (input) ->
				console.log "You typed: #{input}"
				next()
