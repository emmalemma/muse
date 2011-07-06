client_script =->
	`var __slice = Array.prototype.slice;`

	window.Muse = "πMUSE"
	
	findtag =(target, tagname)->
		if target.tagName == tagname
			return target
		else if target.parentNode
			return findtag target.parentNode, tagname
		return null
	
	atag =(target)->findtag(target, 'A')
	formtag =(target)->findtag(target, 'FORM')
		
	if Muse.config.paradigm
		Muse.paradigm = 
			live: off
			socket: io.connect()
			connect:->
				Muse.paradigm.live = on
				Muse.paradigm.headers['user-agent'] = navigator.userAgent
				Muse.paradigm.socket.emit 'headers', Muse.paradigm.headers
			disconnect:->
				Muse.paradigm.live = off
			message:(data)->
				@callback @parse(data)
			
			calls:{}
			
			callback: (call) ->
				unless call.id of @calls
					return console.log "No such call #{call.id}."
				
				call.cb = @calls[call.id]
				delete @calls[call.id]
				
				call.cb.apply @, call.args
			
			call: (name, args..., callback) ->
				id = Muse.util.token(5)
				unless typeof callback is 'function'
					args.push callback
					callback =->
				@calls[id] = callback
				@socket.emit 'π', id, name, args
			
			history: window.history
			
			browser:
				template_chain:[]
				session: null
			
				init:->
				
				
				onclick:(e)->
					if anchor = atag e.target
						#did not click an anchor
						
						if anchor.href.split('#')[0] == window.location.href.split('#')[0]
							#clicked a hash link
							return undefined
						
						Muse.paradigm.browser.get anchor.href
					
						e.preventDefault()
						return false
					else if (e.target.tagName is 'INPUT') and e.target.type == 'submit' and form = formtag e.target
						e.preventDefault()
						inputs = (input for input in form.getElementsByTagName('input'))
						
						for textarea in form.getElementsByTagName('textarea')
							inputs.push textarea
							
						for select in form.getElementsByTagName('select')
							input = name: select.name
							for option in select.getElementsByTagName('option')
								if option.selected
									input.value = option.value
							inputs.push input
							
						if form.method is 'get'
							queryString = "?" + ("#{encodeURIComponent(input.name or ('submit' if input.type == 'submit'))}=#{encodeURIComponent(input.value)}" for input in inputs).join('&')
							Muse.paradigm.browser.get form.action + queryString
						else
							body = {}
							for input in inputs
								body[input.name] = input.value
							Muse.paradigm.browser.post form.action, body
					else
						return undefined
						
				get:(url, state = true)->
					document.title = 'Loading...'
					if state
						Muse.paradigm.history.pushState {template_chain: []}, 'Loading...', url
					Muse.paradigm.call 'Muse.paradigm.browser.get', url, @template_chain, @callback
					@reload_timer = setTimeout @reload, @timeout
					
				post:(url, body, state = true)->
					document.title = 'Loading...'
					if state
						Muse.paradigm.history.pushState {template_chain: []}, 'Loading...', url
					Muse.paradigm.call 'Muse.paradigm.browser.post', url, @template_chain, body, @callback
					@reload_timer = setTimeout @reload, @timeout
				
				reload:->document.location = document.location
				timeout:3000
				reload_timer:null
				
				callback:(resp)->
					clearTimeout Muse.paradigm.browser.reload_timer
					switch resp.action
						when 'yield'
							Muse.paradigm.browser.template_chain = resp.template_chain
							for block of resp.blocks
								el = document.getElementById("yield:#{block}")
								el.innerHTML = null
								el.innerHTML = resp.blocks[block]
								scripts = el.getElementsByTagName 'script'
								
								Muse.paradigm.browser.run_scripts scripts
	
							Muse.ready()
						when 'render'
							document.innerHTML = null
							document.innerHTML = resp.html
							Muse.paradigm.browser.run_scripts document.getElementsByTagName('script')
						when 'redirect'
							document.location = resp.target
					
					document.title = resp.title or "Title"
					Muse.paradigm.history.replaceState {template_chain: resp.template_chain}, document.title, resp.redirect?.url
							
				#Script tags added by innerHTML don't get executed... Thus this hack.
				run_scripts:(scripts)->
					for script in scripts
						clone = document.createElement 'script'
						if script.src
							continue if script.src is '/paradigm.js'
							do (clone) ->
								clone.src = script.src
								Muse.push_script clone.src
								clone.onload =-> Muse.pop_script clone.src
								
						clone.type = script.type or 'text/javascript'
						clone.innerText = script.innerText if script.innerText
						
						parent = script.parentElement
						parent.insertBefore clone, script
						parent.removeChild script
				routes: "πROUTES"
				
				
		Muse.paradigm.socket.on 'connect', Muse.paradigm.connect		
		Muse.paradigm.socket.on 'disconnect', Muse.paradigm.disconnect
		Muse.paradigm.socket.on 'πb', Muse.paradigm.callback.bind(Muse.paradigm)
	
	if Muse.config.paradigm.browser and Muse.paradigm.history
		document.addEventListener 'click', Muse.paradigm.browser.onclick
		firstPop = true
		window.addEventListener 'popstate', ->
			if firstPop
				return firstPop = false
			Muse.paradigm.browser.get(document.location.href, false)
			
		Muse.paradigm.browser.init()
		
	document.onready = Muse.ready


client_muse =
	config:
		paradigm: 
			enable: yes
			browser: yes
			
	util:
		token: Muse.util.token
		
	ready_stack: []
	onready: (fn)->
		@ready_stack.push fn
	ready:->	
		Muse.readiness = true
		if Muse.script_stack?.length
			console.log 'called ready, but scripts still loading'
			return

		for fn in Muse.ready_stack
			try
				fn()
			catch e
				console.log 'ready error:',e
			
		Muse.ready_stack = []
		Muse.readiness = false
	readiness: true
		
	script_stack: []
	push_script: (src) -> @script_stack.push src
	pop_script: (src) ->
		if  (i = @script_stack.indexOf(src)) >= 0
			@script_stack.splice(i, i+1)
		unless @script_stack.length
			#We only call ready if it's been called already
			@ready() if @readiness
			

code = ""

exports = module.exports =(req, res)->
	res.send ";(#{code})();", type: 'text/javascript'

client_routes = exports.routes = {}
exports.build =->
	code = client_script.toString()
	code = code.replace '"πMUSE"', Muse.util.fnJSON client_muse
	code = code.replace '"πROUTES"', JSON.stringify client_routes
	
	code = code.replace /"ƒ|ƒ"/g, ''
	code = code.replace /\\n/g, '\n'
	
	

	