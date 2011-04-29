module.exports =(options)->
	cradle = require 'cradle'
	@client = new cradle.Connection options.host, options.port, options.cradle
		
	@db = @client.database options.db
	model = @
	@get =(id, cb)->
		unless id
			return cb({error: 'no id supplied'})
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
				
	@::save = @::_save =(cb)->
 		#cradle likes to have a callback
		model.db.save @attrs, (err, resp)=>
			unless err
				@attrs._id = resp.id
				@attrs._rev = resp.rev
			cb(err, resp) if cb
			
	
