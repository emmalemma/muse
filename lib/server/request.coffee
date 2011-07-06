request = module.exports = require('http').IncomingMessage.prototype

request.param =(name, value)->
	@params?[name] or @query?[name] or @body?[name] or value
	