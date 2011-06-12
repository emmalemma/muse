exports.token=token=(length)->
	#dead simple random token generator using builtin base36
	if length > 32
		return token(32) + token(length-32)
		
	length ||= 15
	
	min = Math.pow(36, length-1)
	max = Math.pow(36, length)-1
			
	n = Math.floor(Math.random()*(max-min))+min
	n.toString(36)

#Offset is the number of calls back to get the line number for.
#i.e. 1 if calling line directly, 2 if calling line() in Muse.log
#where you want the line number of the log call.
exports.line=(offset=1)->
	stack = new Error().stack.split('\n')
	caller = stack[offset+1]
	if m = caller.match /at (.*)$/
		return m[1]
	else
		Muse.err "Can't parse this stack:", stack
		return 'UNKNOWN'
	
exports.logger = require './logger'