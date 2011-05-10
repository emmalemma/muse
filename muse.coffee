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
exports.csrf = require './lib/middleware/csrf'


exports.util = require './lib/util'

exports.template = require './lib/template'

exports.controller = require './lib/controller'

exports.vows = require './lib/vows'

for log of exports.util.logger
	exports[log] = exports.util.logger[log]