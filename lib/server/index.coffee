http = require 'http'
connect = require 'connect'

qs = require 'qs'
url = require 'url'

http.ServerResponse.prototype = require './response'		
http.IncomingMessage.prototype = require './request'

server = module.exports = connect.createServer()

server.use (req, res, next)->
	res.setHeader 'X-Powered-By', 'Muse'
	req.res = res
	res.req = req
	res.context =
		request: req
		response: res
	
	req.query ?= {}
	if '?' in req.url
		req.query = qs.parse url.parse(req.url).query
		
	req.parse
		
	next()
	
server.configure = (env, fn) ->
	unless fn?
		if typeof env is 'function'
			fn = env
			env = null
	
	if env? and env != Muse.ENV
		return
	fn.call(server)
	
server.error =(fn)->
	server.on 'listening', -> 
		server.use fn
		
server.start =(args...)->
	Muse.paradigm.start(server)
	server.use Muse.router.middleware
	server.listen args...      