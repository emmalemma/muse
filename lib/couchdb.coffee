module.exports =->
	cradle = require 'cradle'
	@client = new cradle.Connection options.host, options.port, options.cradle
		
	@db = @client.database options.db
	model = @
	@get =(id, cb)->
		model.db.get id, (err, doc)->
			if err
				return cb(err)
			else
				return cb null, new model(doc)
				
	@view =(view, opts, cb)->
		model.db.view view, opts, (err, rows)->
			if err
				return cb(err)
			else
				return cb null, _.map(rows, (row)->new model(row.value))
				
	@::save =(cb)->
		cb ?= (->) #cradle likes to have a callback
		model.db.save @attrs._id, @attrs._rev, @attrs, cb