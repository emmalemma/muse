tags = ['doctype', 'tag','div','h2','text','ul','li','a','clear','html','head','meta','title','style','body','section','header', 'h1', 'p']

tag_fn = (tagname) ->
	(args...) ->
		_buffer = @_buffer
		
		if typeof args[0] is 'string'
			content = args.shift()
			
		if typeof args[0] is 'object'
			options = args[0]
		
		attrs = ''
		for key of options
			attrs += " #{key}=\"#{options[key]}\""
		
		if typeof args[args.length-1] is 'function'
			@_chain.push "<#{tagname}#{attrs}>"
			@_buffer = ''
			content = args[args.length-1].call @_context
			@_chain.pop()
		
		@_buffer = _buffer + "<#{tagname}#{attrs}>#{content}</#{tagname}>"


tag_fns =
	coffeescript:(fn)->
		"<script>;(" + fn.toString() + ")();</script>"

for tag in tags
	tag_fns[tag] = tag_fn(tag)

log_error =(chain)->
	console.error "Template error in tag body"
	indents = 0
	for link in chain
		console.error Array.prototype.join.call({length:indents+1},'   '), link
		indents += 1



execute = exports.execute = (template, context = {}, add_locals) ->
	
	code = template.toString()
	exec = ";("+code+").call(context)"
	
	locals = tag_fns
	locals._buffer = ''
	locals._chain = []
	locals._context = context
	
	for local of add_locals
		locals[local] = add_locals[local]
	
	`with (locals)
	{
		try {
			var output = eval(exec);
		} catch (e) {
			log_error(_chain);
			throw new Error("Template error: "+e.message);
		}
		
	};`
	
	return output
