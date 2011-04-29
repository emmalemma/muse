
exports.matchers = matchers =
	string: (options)->
		options ?= {}
		(key, value)->
			return options if typeof value == 'undefined' and options.optional
			unless typeof value == 'string'
					@error key, "must be a string."
			else
				if value.length == 0
					unless options.blank
						@error key, "may not be blank."
				else if options.length and value.length != options.length
					@error key, "must be #{options.length} characters."
				else if options.min and value.length < options.min
					@error key, "must be longer than #{options.min-1} characters."
				else if options.max and value.length > options.max
					@error key, "must be shorter than #{options.min+1} characters."
				else if options.matches and not options.matches.test(value)
						@error key, "must match #{options.matches}."
			options
			
	integer: (options)->
		options ?= {}
		(key, value)->
			return options if typeof value == 'undefined' and options.optional
			if typeof value == 'string' and value.match /^\d+$/
				@attrs[key] = value = parseInt(value)
			unless typeof value == 'number' and value % 1 == 0
				@error key, "must be an integer."	
			else
				if options.min and value < options.min
					@error key, "must be greater than #{options.min-1}."
				else if options.max and value > options.max
					@error key, "must be less than #{options.max+1}."
			options
				
	object: (options)->
		options ?= {}
		(key, value)->
			return options if typeof value == 'undefined' and options.optional
			unless typeof value == 'object'
				@error key, "must be an object."
				
				
	array: (options)->
		options ?= {}
		(key, value)->
			return options if typeof value == 'undefined' and options.optional
			unless typeof value == 'object' and typeof value.length == 'number'
				@error key, "must be an array."
				
	boolean: (options)->
		options ?= {}
		(key, value)->
			return options if typeof value == 'undefined' and options.optional
			unless typeof value == 'boolean'
				@attrs[key] = value and true
#				@error key, "must be a boolean."
				
	oneof: (array, options)->
		options ?= {}
		(key, value)->
			return options if typeof value == 'undefined' and options.optional
			unless value in array
				@error key, "must be one of #{array.join(', ')}."
				
	date: (options)->
		options ?= {}
		(key, value)->
			return options if typeof value == 'undefined' and options.optional
			if isNaN (new Date(value).valueOf())
				@error key, "must be a valid date."
				
	email: /^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,4}$/i
	url: /((https?:\/\/)?([-\w]+\.[-\w\.]+)+\w(:\d+)?(\/([-\w\/_\.]*(\?\S+)?)?)*)/
	phone: /^\(?([0-9]{3})\)?[-. ]?([0-9]{3})[-. ]?([0-9]{4})$/
	zip: /^\d{5}(?:-\d{4})?$/
	
	optional: 'optional'
	required: 'required'
	blank: 'blank'
	
functions= ['string','integer','oneof','date','boolean','array','object']
constants= ['email','url','phone','zip','optional','required','blank']

extractor=(key)->
	(options)->
		options ?= {}
		options.type = key
		options
	
extractors = {}
for fn in functions
	extractors[fn] = extractor fn
for cn in constants
	extractors[cn] = cn
	
extract=(key, obj)->
	exts = undefined
	for k of obj
		if typeof obj[k] == 'object'
			if obj[k]._options?
				ext = obj[k]._options[key]
				ext?.type = obj[k]._type
			else
				ext = extract(key, obj[k])
			if typeof ext != 'undefined'
				if typeof obj[k].length == 'number'
					ext = [ext[0]]
				else
					exts ?= {}
					
				exts[k] = ext
	exts
	
copy =(s,t)->
	for k of s
		if s[k].constructor == Object
			t[k] = {}
			copy s[k], t[k]
		else if s[k].constructor == Array
			t[k] = []
			copy s[k], t[k]
		else if s[k].constructor == Date
			t[k] = new Date s[k]
		else
			t[k] = s[k]

exports.Model = class Model
	constructor: (params, validate=true)->
		@attrs = {}
		copy @Defaults, @attrs
		@set(params, validate)
		
	set:(params, validate=true)->
		console.log "copying", params, "to", @attrs
		copy params, @attrs
		console.log "attrs now", @attrs
		@validate() if validate
		
	get:(path)->
		if path of @attrs
			return @attrs[path]
			
		else if path.indexOf('.') > 0
			path = path.split('.')
			o = @attrs
			while p = path.shift()
				unless o[p]?
					return undefined
				else
					o = o[p]
			return o
		
	# Save from a form
	# pass in list of fields to be extracted from body and put into form
	post:(fields, body)->
		for path in fields
			opt = @options(path)
			continue unless opt
			
			if opt.type is 'integer'
				body[path] = parseInt(body[path])
				if isNaN(body[path])
					body[path] = 0
				
			if path.indexOf('.') > 0
				parts = path.split('.')
				o = @attrs
				while p = parts.shift()
					unless parts.length
						if typeof o[p] is 'object'
							o[p] = JSON.parse(body[path])
						else
							console.log 'setting',o,p,'to',body[path]
							o[p] = body[path]
					else 
						unless o[p]?
							o[p] = {}
						o = o[p]
			else
				if typeof @attrs[path] is 'object'
					@attrs[path] = JSON.parse(body[path])
				else
					@attrs[path] = body[path]
					
		@validate()
		
	options:(path)->
		if path of @_options
			o = @_options[path]
			
		else if path.indexOf('.') > 0
			path = path.split('.')
			o = @_options
			while p = path.shift()
				unless o[p]?
					return undefined
				else
					o = o[p]
		
		if typeof o?[1] == 'object'
			return o[1]
		return o
		
	save:(cb)->
		@_save(cb)
		
	save_or_die:(next, callback)->
		@_save (err, resp)->
			if err
				return next new Error "Error saving document: #{JSON.stringify err}"
			return callback(resp) if callback
		
	# fetch by id
	# if not found, throw 404
	# if other error, throw 500
	# else call callback with fetched object
	@get_or_die:(id, next, callback)->
		@get id, (err, obj)->
			if err
				return next() if err.error == 'not_found' and err.reason == 'missing'
				return next new Error "Error fetching document: #{JSON.stringify err}"
			return callback obj
			
	@view_or_die:(view, opts, next, callback)->
		@view view, opts, (err, obj)->
			if err
				return next new Error "Error fetching view #{view}: #{JSON.stringify err}"
			return callback obj
		
	@initialize:->
		@compile_validation()
		@compile_options()
		@compile_defaults()
		#@compile_form()
		
		
	@schemize:(scheme)->
		@scheme = scheme
		@initialize()
		
	@compile_options:->
		`with(extractors){
			exec = "options = ("+this.scheme.toString()+")()";
			eval(exec);
		}`
		
		@::_options = options
		return
		
	@compile_defaults:->
		@::Defaults = extract('default', @::Options)
		
	@compile_form:->
		@::form = extract('form', @::Options)
		
	@compile_validation:->
		`with(matchers){
			exec = "this.validation = ("+this.scheme.toString()+")()";
			eval(exec);
		}`
		
		@::errors = {}
		@::valid = true
		@::error = (name, err) ->
			@valid = false
			if @errors[name]
				@errors[name].push err
			else @errors[name] = [err]
			
		model = @
		
		@::validate =->
			_err = false
			@errors = {}
			@valid = true
			
			match = (src, comp, path) =>
				if typeof comp == "object"
					#If it's an arroy
					if typeof comp.length == "number"
						unless typeof src == "object" and typeof src.length == "number"
							unless typeof src == 'undefined' and comp.length > 0 and comp[comp.length-1].optional
								@error path, "must be an array."
						else
							matcher = comp[0]
							for i of src
								match(src[i], matcher, path+"[#{i}]")
					else
						unless typeof src == "object"
							unless typeof src == "undefined" and comp.optional
								@error path, "must be an object."
						else
							for key of comp
								continue if key == '__'
								if path
									newpath = path + '.' + key
								else
									newpath = key
								match(src[key], comp[key], newpath)
							for key of src
								unless key of comp
									if comp['__']
										match(src[key], comp['__'], path+'.'+key)
									else unless key in ['prototype', '__super__']
										@error path, "Extra field #{key} not permitted."
				else if typeof comp == "function"
					comp.call(@, path, src)
					
			match(@attrs, model.validation, null)
			return @errors unless @valid
			
	@use:(adapter, options)->
		require('./adapters/'+adapter).call(@, options)
				
exports.load=(dir)->
	fs = require 'fs'
	files = fs.readdirSync dir
	for file in files
		model = require dir+'/'+file
		for ex of model
			exports[ex] = model[ex]
		
