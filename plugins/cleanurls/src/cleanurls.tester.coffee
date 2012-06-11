# Export Plugin Tester
module.exports = (testers) ->
	# Define My Tester
	class MyTester extends testers.ServerTester

		testServer: (next) ->
			# Prepare
			tester = @
			expect = testers.expect
			request = testers.request
			fs = require('fs')

			# Create the server
			super

			# Test
			@suite 'cleanurls', (suite,test) ->
				# Prepare
				baseUrl = "http://localhost:#{tester.docpad.config.port}"
				outExpectedPath = tester.config.outExpectedPath

				test 'server should serve URLs without an extension', (done) ->
					request "#{baseUrl}/welcome.html", (err,response,actual) ->
						throw err  if err
						fs.readFile "#{outExpectedPath}/welcome.html", (err,expected) ->
							throw err  if err
							expect(actual.toString()).to.equal(expected.toString())
							done()