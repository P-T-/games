local hooks={}
hook={
	sel={},
	rsel={},
	meta={},
	created={},
	hooks=hooks,
}
local hook=hook
local function nxt(tbl)
	local n=1
	while tbl[n] do
		n=n+1
	end
	return n
end

function tpairs(tbl)
	local s={}
	local c=1
	for k,v in pairs(tbl) do
		s[c]=k
		c=c+1
	end
	c=0
	return function()
		c=c+1
		return s[c],tbl[s[c]]
	end
end

local ed
function hook.stop()
	ed=true
end
function hook.queue(name,...)
	local callback=hook.callback
	hook.callback=nil
	if type(name)~="table" then
		name={name}
	end
	local p={}
	for _,nme in pairs(name) do
		for k,v in tpairs(hooks[nme] or {}) do
			if v then
				ed=false
				hook.name=nme
				p={v(...)}
				if callback then
					callback(unpack(p))
				end
				if ed then
					hook.del(v)
				end
			end
		end
	end
	return unpack(p)
end
function hook.new(name,func,meta)
	if type(name)~="table" then
		name={name}
	end
	for _,nme in pairs(name) do
		hook.meta[nme]=meta
		hooks[nme]=hooks[nme] or {}
		table.insert(hooks[nme],func)
	end
	return func
end
function hook.del(name)
	if type(name)~="table" then
		name={name}
	end
	for _,nme in pairs(name) do
		if type(nme)=="function" then
			for k,v in pairs(hooks) do
				for n,l in pairs(v) do
					if l==nme then
						hooks[k][n]=nil
					end
				end
			end
		else
			hooks[nme]=nil
		end
	end
end

