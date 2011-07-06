module.exports =(options)->
	cradle = require 'cradle'
	
	model = @
	
	unless options.mock
		@client = new cradle.Connection options.host, options.port, options.cradle
		
		@db = @client.database options.db
		
		
		@_get =(id, cb)->
			unless id
				return cb({error: 'no id supplied'})
			model.db.get id, (err, doc)->
				if err
					return cb(err)
				else
					return cb null, model.new(doc)
	
		@_view =(view, opts, cb)->
			model.db.view view, opts, (err, rows)->
				if err
					return cb(err)
				else
					return cb null, _.map(rows, (row)->model.new(row.value))
		
		@::save = @::_save =(cb)->
			#cradle likes to have a callback
			model.db.save @attrs, (err, resp)=>
				unless err
					@attrs._id = resp.id
					@attrs._rev = resp.rev
				cb(err, @) if cb
				
	else
		docs = {}
		views = {}
		@_get = (id, cb)->
			if id of docs
				callback null, docs[id]
			else
				callback {error: 'not found'}
				
		@_view = (view, opts, callback)->
			if view of views
				if o = JSON.stringify(opts) of views[view]
					callback null, views[view][o]
				else
					callback null, []
			else
				callback {error: 'not found'}
				
		@::save = @::_save = (cb) ->
			unless @attrs._id
				@attrs.id = Muse.util.token(20)
			unless @attrs._rev
				@attrs._rev = 0
			else
				@attrs._rev += 1
				
		@mock =
			get:(ob)->
				docs[ob._id] = ob
			view:(view, opts, resp)->
				views[view]={}
				views[view][JSON.stringify(opts)]=resp
				
			

	@::save_or_die=(next, callback)->
		@_save (err, resp)->
			if err
				return next new Error "Error saving document: #{JSON.stringify err}"
			return callback(resp) if callback

	# fetch by id
	# if not found, throw 404
	# if other error, throw 500
	# else call callback with fetched object
	@get_or_die=(id, next, callback)->
		@get id, (err, obj)->
			if err
				return next() if err.error == 'not_found' and err.reason == 'missing'
				return next new Error "Error fetching document: #{JSON.stringify err}"
			return callback obj

	@view_or_die=(view, opts, next, callback)->
		@view view, opts, (err, obj)->
			if err
				return next new Error "Error fetching view #{view}: #{JSON.stringify err}"
			return callback obj

			
	
