module.exports = (testers) ->
	class MyTester extends testers.RendererTester
		# Configuration
		docpadConfig:
			enabledPlugins:
				'highlightjs': true
				'marked': true
				'eco': true
