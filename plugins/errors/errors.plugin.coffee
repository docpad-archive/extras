# Export Plugin
module.exports = (BasePlugin) ->
  express = require('express')
  path = require('path')
  fs = require('fs')

  # Conformes to http://www.w3.org/Protocols/rfc2616/rfc2616-sec10.html
  CODE =
    '400': 'Bad Request'
    '401': 'Unauthorized'
    '402': 'Payment Required'
    '403': 'Forbidden'
    '404': 'Not Found'
    '405': 'Method Not Allowed'
    '406': 'Not Acceptable'
    '407': 'Proxy Authentication Required'
    '408': 'Request Timeout'
    '409': 'Conflict'
    '410': 'Gone'
    '411': 'Length Required'
    '412': 'Precondition Failed'
    '413': 'Request Entity Too Large'
    '414': 'Request-URI Too Long'
    '415': 'Unsupported Media Type'
    '416': 'Requested Range Not Satisfiable'
    '417': 'Expectation Failed'
    '500': 'Internal Server Error'
    '501': 'Not Implemented'
    '502': 'Bad Gateway'
    '503': 'Service Unavailable'
    '504': 'Gateway Timeout'
    '505': 'HTTP Version Not Supported'

  # Define Plugin
  class Errors extends BasePlugin
    # Plugin name
    name: 'errors'

    files: {}

    prefixMatch: (n1, n2) ->
      n1 = Number(n1)
      n2 = Number(n2)

      n1 = Math.floor(n1/100)
      n2 = Math.floor(n2/100)

      return (n1 == n2)

    findClosest: (code) ->
      match = null
      for key, value of CODE
        if @files.hasOwnProperty(key) && code >= Number(key)
          match = key
          # exact match exit
          if Number(key) == code
            break

      if match == null
        for key, value of @files
          match = key
        unless match
          match = code

      return match

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
        code = self.findClosest(404)
        # Assume 404 for now
        if self.files.hasOwnProperty(code) && path.existsSync self.files[code]
          data = fs.readFileSync(self.files[code], 'utf8')
          res.writeHead(code, CODE[code])
          res.write(data)
        else
          res.writeHead(code, CODE[code])
          res.write(code + ' ' + CODE[code])

        res.end()

      server.use (err, req, res, next) ->
        code = self.findClosest(500)
        if self.files.hasOwnProperty(code) && path.existsSync self.files[code]
          res.writeHead(code, CODE[code])
          data = fs.readFileSync(self.files[code], 'utf8')
          res.write(data)
        else
          res.writeHead(code, CODE[code])
          res.write(code + ' ' + CODE[code])

        res.end()