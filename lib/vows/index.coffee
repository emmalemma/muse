vows = require 'vows'
should = require 'should'
assert = require 'assert'

context_for =(route, sit, request, controller)->

	resp = (a for a of request.Response)[0]
	Response = request.Response[resp]
	
	mock_request=
		param:(k)->@params[k]
		session: {}
	
	request.Request.__proto__ = mock_request
	
	
	context =
		topic:->
			topic = this
			res = {}
			wrong_callback=(call)-> (args...)->topic.callback(null,call,args...)
			res.render = wrong_callback 'render'
			res.redirect = wrong_callback 'redirect'
			res.next = wrong_callback 'next'
			res[resp] =(args...)->
				return topic.callback(null,resp,args...)
				topic.callback(null, args...)
			
			controller[route](request.Request, res, res.next)
			return undefined
			
		'callback':(call,args...)->assert.equal call, resp, "Expected #{resp}, called #{call}"
		
	switch resp
		when 'render'
			context.renders=
				topic:(call, args...)->
					this.callback args...
					
				'the right template':(template, context)->
					template.should.equal Response.template

				'the right context':(template, context)->
					assert.deepEqual context, Response.context
	context


exports.load=(dir)->
	fs = require 'fs'
	files = fs.readdirSync dir
	for file in files
		if file.match /.coffee$/
			controller = require dir+'/'+file
			for ex of controller
				add_controller ex, controller[ex]
	suite.run()
	
suite = vows.describe('Controller')

add_controller = (name, routes) ->
	batch = {}
	batch[name] = controller = {}
	suite.addBatch batch
	
	for route of routes
		controller['.'+route] = context = {}
		for sit of routes[route]
			context[sit] = context_for(route, sit, routes[route][sit], Muse.controller[name])