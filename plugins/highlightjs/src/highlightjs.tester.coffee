module.exports = (testers) ->
    class MyTester extends testers.RendererTester
        # Configuration
        docpadConfig:
            enabledPlugins:
                'highlightjs': true
                'markdown': true
                'eco': true
