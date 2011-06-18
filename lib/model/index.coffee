
copy =(s,t)->
	for k of s
		if s[k]? and typeof s[k] is 'object'
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

validators = exports.validators =
	with:(schema)->
		try
			return schema.call(@)
		catch e
			if e.type is 'undefined_method' and e.arguments[1] is this
				throw new Error "I don't know how to validate as '#{e.arguments[0]}'."
			else throw e
			
	_:(options)->
		validate =-> null
		validate.__proto__ = options
		options.type = '_'
		return validate
	
	array:(cmp...)->
		if typeof cmp[0] is 'object'
			options = cmp.shift()
		else
			options = {}
		
		unless cmp?
			cmp = options
			options = {}
			
		validate = (value) ->
			unless typeof value is 'object' and typeof value.length is 'number'
				return 'must be an array'
			errors = null
			for key of value
				err = []
				for c in cmp
					err.push c(value[key])
					unless err[err.length-1]
						err = null
						break
				if err
					errors ?= {}
					errors[key] = err.join(' or ')
			return errors
		
		options.type = 'array'
		options.cmp = cmp
		validate.__proto__ = options
		validate
	
	in:(options, cmp)->
		options ?= {}
		unless cmp?
			cmp = options
			options = {}
			
		unless typeof cmp is 'object' and typeof cmp.length is 'number'
			throw new Error 'Comparison for @in must be an array.'
			return
			
		validate = (value) ->
			err = []
			for c in cmp
				if typeof c is 'function'
					err.push c(value)
				else
					err.push "must be `#{c}`" if c != value
					
				unless err[err.length-1]
					err = null
					break
					
			return err.join(' or ') if err
		
		options.type = 'in'
		validate.__proto__ = options
		validate
	
	object:(options, cmp)->
		options ?= {}
		
		unless cmp?
			cmp = options
			options = {}
			
		unless typeof cmp is 'object'
			throw new Error 'Comparison for @object must be an object.'
			return
		
		if typeof cmp.length is 'number'
			return validators.array options, cmp...
		
			
		regexes = {}
		for key of cmp
			if match = /^m\/(.*)\/([gim]*)$/.exec key
				regexes[key] = new RegExp match[1],match[2]
		
		validate = (value) ->
			unless typeof value is 'object' and value.constructor is Object
				return 'must be an object'
		
			errors = null
			
			for key of value
				unless key of cmp
					if cmp.__?
						err = cmp.__(value[key])
						if err
							errors ?= {}
							errors[key] = err
					else if regexes
						err = []
						for rk of regexes
							if regexes[rk].test key
								err.push cmp[rk](value[key])
								unless err[err.length-1]
									err = null
									break
							else
								err.push "not allowed by #{rk}"
						if err
							errors ?= {}
							errors[key] = err.join(' or ')
					else
						errors ?= {}
						errors[key] = 'not allowed'
				else
					unless typeof cmp[key] is 'function'
						throw new Error "Schema error: #{key} is not a validation. Did you forget an @?"
					err = cmp[key](value[key])
					if err
						errors ?= {}
						errors[key] = err
			for key of cmp
				continue if key is '__' or key of regexes
				unless key of value or cmp[key].optional?
					errors ?= {}
					errors[key] = 'required'
					
			return errors
		
		options.type = 'object'
		options.cmp = cmp
		validate.__proto__ = options
		validate
		
	string:(options = {})->
		
		matchers = 
			email: /^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,4}$/i
			url: /((https?:\/\/)?([-\w]+\.[-\w\.]+)+\w(:\d+)?(\/([-\w\/_\.]*(\?\S+)?)?)*)/
			phone: /^\(?([0-9]{3})\)?[-. ]?([0-9]{3})[-. ]?([0-9]{4})$/
			zip: /^\d{5}(?:-\d{4})?$/
			
		if options.matches?	
			if typeof options.matches is 'string'
				options.match_name ?= options.matches
				options.matches = matchers[options.matches]
			unless typeof options.matches is 'function' and options.matches.constructor is RegExp
				throw new Error "Schema error: @string match `#{options.matches}` is not a RegExp or known matcher."
	
		validate = (value) ->
			unless typeof value is 'string'
				return 'must be a string'
			else if options.matches 
				unless options.matches.test(value)
					return "must match #{options.match_name or options.matches}"
			null
		
		options.coerce ?=(value)->value.toString()
		options.type = 'string'
		validate.__proto__ = options
		validate

	integer:(options = {})->
		validate = (value) ->
			unless typeof value is 'number' and parseInt(value) == value and not isNaN(value)
				return 'must be an integer'
				
		options.coerce ?=(value)->parseInt(value)
		
		options.type = 'integer'
		validate.__proto__ = options
		validate
		
				
	boolean: (options = {})->
		
		validate =(value)->
			unless typeof value == 'boolean'
				return "must be a boolean"
				
		options.coerce ?=(value)->value and true
		options.type = 'boolean'
		validate.__proto__ = options
		validate
	
	date: (options = {})->
		validate = (value)->
			if isNaN (new Date(value).valueOf())
				return "must be a valid date"
					
		options.coerce ?=(value)->new Date(value)
		options.type = 'date'
		validate.__proto__ = options
		validate
					

validators.__defineGetter__ '__', validators._

at_validation = validators.object
at_validation.__proto__ = validators

class Attributes
	constructor:(attrs, @values = {})->
		for key of attrs
			if attrs[key].type is 'object'
				@addSubAttrs key, attrs[key]
			else
				@addAttr key, attrs[key]
	
	set:(values)->
		for key of values
			if @hasOwnProperty(key)
				@[key] = values[key]
			else if @__?
				@addAttr key, @__
				@[key] = values[key]
			else
				throw new Error "Cannot set attribute '#{key}'."
	
	addAttr:(key, validate)->
		if key is '__'
			@__ = validate
			return
		if validate.coerce
			@__defineSetter__ key, (val)->
				val = validate.coerce(val)
				unless error = validate(val)
					@values[key] = val
				else
					throw new Error "key: #{key}, value: #{val} " + JSON.stringify(error)
		else
			@__defineSetter__ key, (val)->
				unless error = validate(val)
					@values[key] = val
				else
					throw new Error "key: #{key}, value: #{val} " + JSON.stringify(error)
			
		@__defineGetter__ key, ->@values[key]
		
	addSubAttrs:(key, opts)->
		@values[key] = {}
		attrs = new Attributes(opts.cmp, @values[key])
		@__defineGetter__ key, ->attrs
		@__defineSetter__ key, (val)->attrs.set val
		


exports.Model = class Model
	constructor: (params)->
		# @_attrs = new Attributes(@schema)
		# 	@__defineGetter__ 'attrs', ->@_attrs
		# 	@__defineSetter__ 'attrs', (val)->@_attrs.set val
		
		@attrs = {}
		copy @defaults, @attrs
		@set params
	
	flat_errors:->
		flatten=(key, obj)->
			unless typeof obj is 'object'
				return obj
			out = {}
			for k of obj
				if key
					new_key = key + '.' + k
				else new_key = k
				if typeof obj[k] is 'object'
					copy flatten(new_key, obj[k]), out
				else
					out[new_key] = obj[k]
			out
			
		flatten(null, @errors)
	
	set:(params, validate = true)->
		copy params, @attrs
		@validate() if validate
		
	validate:->
		@errors = @validation(@attrs)
		@valid = not @errors
		
	toString:->@attrs.toString()
	
	
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
	post:(fields, body)->
		Muse.log 'posting',fields, body
		for path in fields
			opt = @options(path)
			continue unless opt
			
			if opt.coerce
				body[path] = opt.coerce(body[path])
				
			if path.indexOf('.') > 0
				parts = path.split('.')
				o = @attrs
				while p = parts.shift()
					unless parts.length
						if typeof o[p] is 'object'
							o[p] = JSON.parse(body[path])
						else
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
		if path of @validation.cmp
			o = @validation.cmp[path]
			
		else if path.indexOf('.') > 0
			path = path.split('.')
			o = @validation
			while p = path.shift()
				if o.type is 'object'
					o = o.cmp
					
				unless o[p]?
					return undefined
				
				o = o[p]
		return o?.__proto__
		
	@schemize:(schema)->
		@::schema = at_validation.with schema
		@::validation = at_validation.object @::schema
	
	@makeSetters:->
	
	@use:(adapter, options)->
		require('./adapters/'+adapter).call(@, options)


exports.Mock =->
	_use = exports.Model.use
	exports.Model.use =(adapter, options)->
		options.mock = true
		_use.call(@, adapter, options)

exports.load=(dir)->
	fs = require 'fs'
	files = fs.readdirSync dir
	for file in files
		model = require dir+'/'+file
		for ex of model
			exports[ex] = model[ex]
		
