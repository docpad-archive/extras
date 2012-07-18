# Export Plugin Tester
module.exports = (testers) ->
	# Define My Tester
	class MyTester extends testers.RendererTester
		# Configuration
		docpadConfig:
			enabledPlugins:
				'associatedfiles': true
				'eco': true