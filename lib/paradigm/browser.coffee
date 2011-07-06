js = require './js'
http = require 'http'
url = require 'url'

ParadigmBrowserResponse = class ParadigmBrowserResponse extends http.ServerResponse
	end: (data) ->
		@callback
			action: 'end'
			data: data
		
	constructor:(options)->
		super options
		for o of options
			@[o] = options[o]
		
	render: (name, context = {}, options = {}) ->
			for v of context
				@context[v] = context[v]
			out = Muse.view.render name, @context, template_chain: @templates
			unless out
				@templates.shift()
				out = Muse.view.render name, @context, template_chain: @templates
				
			response = unless out
					action: 'noop'
				else if typeof out is 'object'
					action: 'yield'
					blocks: out.blocks
					template_chain: out.template_chain
				else if typeof out is 'string'
					action: 'render'
					html: out
			if @redirect_to
				response.redirect = url: @redirect_to
			#Because we're not calling end(), we need to save the session manually
			@req.session.save => @callback response
		
	redirect: (target, code) ->
		target = @req.headers.referer if target is 'back'
		target = @redirect.aliases[target] if target of @redirect.aliases
		
		
		if target.indexOf '://'
			return @req.session.save => @callback action: 'redirect', target: target
		
		@req.headers.referer = @req.url
		
		#Because we're not calling end(), we need to save the session manually
		@req.session.save => exports.get target, @templates, @callback, headers: @req.headers

ParadigmBrowserResponse.prototype.redirect.aliases = {}
ParadigmBrowserResponse.prototype.redirect.alias =(s, t)->
		@aliases[s] = t
	
ParadigmBrowserRequest = class ParadigmBrowserRequest extends http.IncomingMessage
	constructor:(options)->
		super options
		for o of options
			@[o] = options[o]
	cookie:(args...)->
		Muse.log 'cookie',args


exports.get =(loc, templates, callback, redirect)->
	parts = url.parse(loc)
	path = parts.pathname + (parts.search or '')
	
	res = new ParadigmBrowserResponse
		method: 'GET'
		httpVersionMajor: 1
		callback: callback
		templates: templates
	if redirect?
		res.redirect_to = path
		
	req = new ParadigmBrowserRequest
		method: 'GET'
		url: path
		headers:
			redirect?.headers or @headers
		connection: @
	
	Muse.server.handle req, res, =>
		@headers.referer = parts.href

exports.post =(path, templates, body, callback, redirect)->
	path = url.parse(path).pathname
	res = new ParadigmBrowserResponse
		method: 'POST'
		httpVersionMajor: 1
		callback: callback
		templates: templates
	if redirect?
		Muse.log 'redirected to',redirect
		res.redirect_to = path

	req = new ParadigmBrowserRequest
		method: 'POST'
		url: path
		headers:
			redirect?.headers or @headers
		connection: @
		body: body

	Muse.server.handle req, res, =>
		@headers.referer = path.href