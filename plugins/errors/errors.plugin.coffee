# Export Plugin
module.exports = (BasePlugin) ->
  express = require('express')
  path = require('path')
  fs = require('fs')

  # Define Plugin
  class Errors extends BasePlugin
    # Plugin name
    name: 'errors'

    files: {}

    findClosest: (code) ->
      for key, value of @files
        if Number(key) == code
          return value

      return null

    generateAfter: ->
      fileList = fs.readdirSync(@docpad.config.outPath)

      for file in fileList
        if file.match /^[0-9]{3}\.html/
          code = file.match /^([0-9]{3})\.html/
          @files[code[1]] = path.join(@docpad.config.outPath, file)

    serverAfter: (opts) ->
      {server} = (opts)
      self = @

      server.use (req, res, next) ->
        file = self.findClosest(404)
        # Assume 404 for now
        if path.existsSync file
          data = fs.readFileSync(file, 'utf8')
          res.writeHead(404, 'Not Found')
          res.write(data)
        else
          res.writeHead(404, 'Not Found')
          res.write('404 NOT FOUND')

        res.end()

      server.use (err, req, res, next) ->
        file = self.findClosest(500)
        if path.existsSync file
          res.writeHead(500, 'Internal Server Error')
          data = fs.readFileSync(file, 'utf8')
          res.write(data)
        else
          res.writeHead(500, 'Internal Server Error')
          res.write('500 INTERNAL SERVER ERROR')

        res.end()