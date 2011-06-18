connect = require 'connect'

response = module.exports = require('http').ServerResponse.prototype

response.render = (name, context = {}, options = {}) ->
	for v of context
		@context[v] = context[v]
	out = Muse.view.render name, @context
	@statusCode = options.code or 200
	@end out
	
for code in [200, 404, 500]
	do (code)->
		response.render[code] =(name, context = {}, options = {})->
			options.code = code
			response.render name, context, options
			
response.redirect = (target, code) ->
	target = @req.headers.referer if target is 'back'
	target = @redirect.aliases[target] if target of @redirect.aliases
	
	@statusCode = code or 302
	@setHeader 'Location', target
	@end 'Redirecting.'

response.redirect.aliases = {}
response.redirect.alias =(s, t)->
	@aliases[s] = t

response.cookie =(name, value, options = {})->
	#Muse.log '@',@
	@setHeader 'Set-Cookie', connect.utils.serializeCookie name, value, options
	value
	
response.clearCookie =(name)->
	@cookie name, '', expires: new Date(0)
	
response.send = (data, options={})->
	@setHeader 'Content-Type', options.type or 'text/html'
	@end(data)