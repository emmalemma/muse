request = module.exports = require('http').IncomingMessage.prototype

request.param =(name, value)->
	Muse.log 'params:',@params,@query,@body
	@params?[name] or @query?[name] or @body?[name] or value
	