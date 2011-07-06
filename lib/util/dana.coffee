events = require 'events'

module.exports = class Dana extends events.EventEmitter
	
	constructor:(fn, args..., cb)->
		if cb? and typeof cb != 'function'
			args.push cb
			cb = null
		
		dana = @
				
		look =->
			if --count == 0
				fn args..., (err, doc)->
					if err
						dana.emit 'error', err
					else
						dana.emit 'success', doc
					cb(err, doc) if cb
		
		
		count = 1
		scan =(ob)->
			for i of ob
				if typeof ob[i].on is 'function'
					count++
					do (i)->
						ob[i].on 'success', (data)->
							ob[i] = data
							look()
						ob[i].on 'error', (e)->dana.emit 'error', e
				else if typeof ob[i] is 'object'
					scan ob[i]
		scan args
		
		process.nextTick look
		
		this
		
		
	dana:(fn)->
		d = new events.EventEmitter
		@on 'success', (data)->
			d.emit 'success', fn.call(data)
		@on 'error', (e)->
			d.emit 'error',e
		d
		
	@provide:(args..., call) ->
		d = new Dana call, args...
		d.on 'error', (e)->
			throw new Error 'Provision error.'
		d
			
	@wrap:(fn)->
		(args...)->
			d = new Dana fn, args...