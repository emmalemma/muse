
_log=(level)->
	(args...)->
		console.log "#{level} at #{Muse.util.line(2).replace('.coffee','.coffee->js')}:"
		console.log args...

for level in ["LOG","DEBUG","ERR","WARN"]
	module.exports[level.toLowerCase()] = _log(level)