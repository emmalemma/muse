# N-request persistence
# Defaults to one request (similar to Rails flash)
# Relies on Session middleware.
# `req.scratch key, value, persist=1`
# `req.scratch key => value` for that and `persist` subsequent requests.
_ = require('underscore')._

settings=
	persist: 1
	
module.exports =(persist)->
	settings.persist = persist if persist
	(req, res, next)->
		#Initialize scratchpad if it doesn't exist.
		req.session.scratchpad ?= {}
		#Store the current scratchpad while we process this request.
		req.scratchpad = _.clone req.session.scratchpad
		#Decrement the current session scratchpad, expire any values that are depleted.
		for key of req.session.scratchpad
			req.session.scratchpad[key].persist -= 1 if req.session.scratchpad[key].persist > 0
			if req.session.scratchpad[key].persist == 0
				delete req.session.scratchpad[key]
				
		#Add the `scratch` method to the request.
		req.scratch =(key, value, persist)->
			if typeof value != 'undefined'
				req.session.scratchpad[key] = req.scratchpad[key] = {value: value, persist: persist or settings.persist}
				return value
				
			else if persist and req.scratchpad[key]? #if we have undefined value and positive persist, assume they want to keep persisting that attribute
				req.session.scratchpad[key] = {value:req.scratchpad[key].value, persist:persist}
				
			else
				return req.scratchpad[key]?.value
				
		#Utility for repersisting values
		#equivalent to `scratch key, undefined, persist`
		req.rescratch =(key, persist)->
			if req.scratchpad[key]?
				req.session.scratchpad[key] = {value:req.scratchpad[key].value, persist:persist}
				
		#Utility for clearing scratch
		#(Functionally) equivalent to `scratch key, value, 0`
		req.unscratch =(key)->
			delete req.session.scratchpad[key]
			
		#Utility to not decrement scratch count for this request (e.g., ajax call)
		req.noscratch =()->
			req.session.scratchpad = req.scratchpad
			
		next()