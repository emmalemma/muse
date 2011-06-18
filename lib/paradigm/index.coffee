js = exports.js = require './js'
browser = exports.browser = require './browser'
socket =
	io: require 'socket.io'

exports.io = io = null

calls =
	"Muse.paradigm.browser.get"		: browser.get
	"Muse.paradigm.browser.post"	: browser.post

call =(id, name, args)->
	Muse.log 'client called',id, name, args
	unless name of calls
		return Muse.err 'No such call.'
		
	args.push callback(@, id)
	
	calls[name].apply @, args

callback =(client, id)->
	(args...)->
		client.emit 'πb', id: id, args: args

connect =(client)->
	Muse.log 'paradigm client connected' #, client
	client.on 'π', call
	client.on 'headers', (headers)->
		client.headers = headers

init =->
	io.sockets.on 'connection', connect
	io.sockets.on 'π', call

exports.start =(server)->
	js.build()
	io = socket.io.listen(server)
	init()