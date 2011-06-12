fs = require 'fs'
engine = null
views = {}

loadDir = (dir, path = '') ->
	files = fs.readdirSync(dir+'/'+path)
	for f in files
		name = if path then path + '/' + f else f
		if fs.statSync(dir+'/'+name).isDirectory()
			loadDir(dir, name)
		else
			if m = name.match /^(.*).coffee$/
				views[m[1]] = require dir+'/'+name
				views[m[1]].name ?= m[1]

exports.load = (dir) ->
	engine = require('./engines/coffeekup').using(require dir+'/helpers')
	loadDir dir
	
exports.render = (name, context) ->
	unless name of views
		Muse.err "I don't have a view called '#{name}'."
	views[name].render context

exports.renderer = (name, context, options) ->
	(req, res) ->
		res.render name, context, options
	

exports.View = class View
	constructor : (options) ->
		return unless options?
		if typeof options is 'function'
			options =
				template: options
				
		@inherit = options.inherits if options.inherits
		
		@yields = {}
		if options.yield?
			for yield of options.yield
				@yields[yield] = engine.compile options.yield[yield]
				
		@context = options.context
		
		@template = engine.compile options.template if options.template

	
	render : (context) ->
		context.template_chain ?= []
		context.template_chain.push @name
		
		blocks = context._blocks ?= {}
		
		for yield of @yields
			unless blocks[yield]?
				try
					blocks[yield] = @yields[yield] context
				catch e
					Muse.err "Error caught rendering #{@name}:#{yield}."
					throw e
		
		if @inherit
			views[@inherit].render context
		else
			try
				@template context
			catch e
				Muse.err "Error caught rendering #{@name}."
				throw e
		
			
	yield : (block, fn) ->
		unless block of @blocks
			@blocks[block] = engine.compile fn