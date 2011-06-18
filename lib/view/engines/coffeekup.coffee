coffeekup = require 'coffeekup'
markdown = require('markdown').parse
locals =
	partial: (name, options = {}) ->
		for option of options
			ck_options.context[option] = options[option]
		text Muse.view.render name, ck_options.context, partial: true
		
	yield: (name, fn) ->
		blocks = (context = ck_options.context)._blocks
		
		div id: "yield:#{name}", ->
			if name of blocks
				text blocks[name]
				delete blocks[name]
			else
				if typeof fn is 'string'
					text fn
				else if typeof fn is 'function'
					fn.call(context)
	# Utility method that does nothing
	ignore:->
		
	# Markdown support
	md:(temp, options={})->
		out = ck_options.context._fn.markdown temp
		unless options.safe
			out = out.replace ck_options.context.markdown_regex, (tag, slash, tagname)-> return if ck_options.context.markdown_whitelist[tagname] then "<#{slash}#{tagname}>" else ''
		text out
		
	# Comment tag that passes through to HTML
	comment:(args...,fn)->
		text '<!--'+args
		if typeof fn == 'function' then fn() else text fn
		text '-->'
	
context =
	_fn:
		markdown: require('markdown').parse

exports.using =(helpers)->
	helpers.locals.__proto__ = locals
	helpers.context.__proto__ = context
	compile:(text)->
		template = coffeekup.compile text,
			locals: helpers.locals
		(context)->
			context.__proto__ = helpers.context
			template(context: context)
