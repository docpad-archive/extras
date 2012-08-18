# Export Plugin Tester
module.exports = (testers) ->
	# Define Plugin Tester
	class MyTester extends testers.RendererTester
		# Configuration
		docpadConfig:
			logLevel: 7
			enabledPlugins:
				'cachr': true
				'eco': true