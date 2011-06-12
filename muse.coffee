global.Muse = module.exports = {}

Muse.ENV = process.env.NODE_ENV

Muse.model = require('./lib/model')
Muse.Model = Muse.model.Model

Muse.pollute = (modules) ->
	for name of modules
		global[name] = modules[name]
		
Muse.config =
	load: (file)->
		load = @load
		Muse.config = require file
		Muse.load = load
		
Muse.scratch = require './lib/middleware/scratch'
Muse.csrf = require './lib/middleware/csrf'


Muse.util = require './lib/util'

Muse.view = require './lib/view'
Muse.View = Muse.view.View

Muse.controller = require './lib/controller'

Muse.router = require './lib/router'

Muse.vows = require './lib/vows'

Muse.paradigm = require './lib/paradigm'

Muse.server = require './lib/server'

for log of Muse.util.logger
	Muse[log] = Muse.util.logger[log]