connect = require 'connect'

router = module.exports =
	controller: (options, controllers) ->
		unless controllers?
			controllers = options
			options = {}
		for controller of controllers
			@route options, controllers[controller], Muse.controller[controller]
		
	route: (options, routes, controller = null) ->
		unless routes?
			routes = options
			options = {}
		for route of routes
			stack = []
			for method of routes[route]
				call = routes[route][method]
				
				stack.push method
				if call is method
					continue
					
				if controller and typeof call is 'string'
					call = controller[call]
				
				if rx = route.match /^m\|(.*)$/
					route = new RegExp(rx[1])
				
				for method in stack
					@[method].bind(@) route, call
					
				stack = []
	
	parse_routes: (@__proto__) ->
		@_routes.call this
	
	load: (file)->
		@_routes = require(file)
		@middleware = connect.router @parse_routes.bind(this)
	
	middleware:->
		throw new Error "No routes defined."
		
	resource:(name, options = {})->
		url = options.url ?= '/'
		names = options.plural ?= name + 's'
		
		controllers = {}
		
		propername = name
		propername[0] = propername[0].toUpperCase()
		
		if options.before?
			controllers[propername] = {}
			controllers[propername]["m|#{url}#{name}(.*)"] = all: options.before
			@controller controllers
			
		controllers[propername] = {}
		controllers[propername]["#{url}#{names}"] = {get: 'list', post:'create'}
		controllers[propername]["#{url}#{name}/:id"] = {get: 'show', post:'update'}
		controllers[propername]["#{url}#{name}/:id/destroy"] = {post: 'destroy'}
		
		@controller controllers
			
		
router.controllers = router.controller
router.routes = router.route

(file)->
	routes = require file
	parse_routes =(app)->
		list = []

		assign =(path, cb)->
			if rx = path.match /^m\|(.*)$/
				path = new RegExp(rx[1])

			for method in list
				Muse.log 'routing',method,path,'to',cb
				if typeof cb is 'object'
					app[method] path, cb...
				else
					app[method] path, cb
			list = []

		Routes = context.parse(routes)

		assign_all=(route_path, methods)->
			for method, action of methods
				list.push method

				if typeof action is 'function'
					assign route_path, action

				else if typeof action is 'string'
					if action == method
						continue

					fn = controller[action]
					if typeof fn is 'function'
						assign route_path, fn
					else
						Muse.err "Route callback #{controller_name}.#{action} is not a function."
						assign route_path, -> Muse.err "Route callback #{controller_name}.#{action} is not a function."	
				else if typeof action is 'object'
					if typeof action.length is 'number' #probably means this is an array
						assign route_path, _.map(action, (fn)->if typeof(fn) == 'string' then controller[fn] else fn)
						# for fn in action
						# 									if typeof fn is 'function'
						# 										assign route_path, fn
						# 									else if typeof fn is 'string'
						# 										fn = controller[fn]
						# 										if typeof fn is not 'function'
						# 											Muse.err "Route callback #{controller_name}.#{fn} is not a function."
						# 											break 
						# 										else
						# 										assign route_path, fn
		for controller_name of Routes
			if controller_name[0] == '/' or controller_name.match(/^m\|.*$/) #it's a root-level route
				assign_all controller_name, Routes[controller_name]
			else
				controller = Muse.controller[controller_name]

				unless controller
					Muse.err "No controller file found for route #{controller_name}."
					continue

				list = []
				for route_path of Routes[controller_name]
					assign_all route_path, Routes[controller_name][route_path]
					
	Muse.server.use connect.router parse_routes
	(app)->
		app.get '/index', (req, res)->
			
			Muse.log 'hi!'



