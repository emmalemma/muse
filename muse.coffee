exports.model = require('./lib/model')
exports.Model = exports.model.Model

exports.pollute = (modules) ->
	for name of modules
		global[name] = modules[name]
		
exports.config =
	load: (file)->
		load = @load
		exports.config = require file
		exports.load = load
		
exports.scratch = require './lib/middleware/scratch'