require("hook")

local resume
local yield=coroutine.yield
function pull(...)
	hook.new({...},function(...)
		resume(...)
		hook.stop()
	end)
	return yield()
end

function wait(tme)
	local t=0
	hook.new("update",function(dt)
		t=t+dt
		if t>=tme then
			hook.stop()
			resume()
		end
	end)
	return yield()
end

local graphics=love.graphics
local current
local pmap

local function new(letters)
	letters=letters-1
	local min
	for l1=0,letters do
		pmap[l1]=pmap[l1] or 0
		min=math.min(pmap[l1],min or pmap[l1])
	end
	local smap={}
	for l1=0,letters do
		if pmap[l1]==min then
			table.insert(smap,l1)
		end
		pmap[l1]=pmap[l1]-min
	end
	local cn=smap[math.random(1,#smap)]
	pmap[cn]=pmap[cn]+1
	local o=--[[math.random(0,1)==0 and]] 65 --[[or 97]]
	local cs=o+math.max(math.min(cn-math.random(0,3),22),0)
	local cv=o+cn
	current={
		question=string.char(cv),
		answers={},
		answered={},
		answer=cv,
		walpha=0,
		alpha=0,
		green=200,
	}
	for l1=cs,cs+3 do
		table.insert(current.answers,string.format("%02x",l1))
	end
	for l1=0,255,10 do
		current.alpha=l1
		current.walpha=l1
		wait(0.01)
	end
	current.alpha=255
	current.walpha=255
end

local letters
local cbarlen
local function main()
	math.randomseed(os.time()*1000)
	letters=4
	cbarlen=0
	pmap={}
	new(4)
	while true do
		local cn
		while not cn do
			local x,y,bt=pull("mouse_down","key_down")
			local w,h=graphics.getDimensions()
			local function check(l)
				if current.answer==tonumber(current.answers[l],16) then
					cn=l
					letters=math.min(letters+0.5,24)
				elseif not current.answered[l] then
					current.answered[l]=string.char(tonumber(current.answers[l],16))
					letters=math.max(letters-0.5,4)
				end
			end
			if hook.name=="mouse_down" and bt=="l" then
				local bw=math.floor(w/6)
				local bh=math.floor(bw/1.2)
				for l1=1,4 do
					local c=math.floor((l1/5)*w)
					if x>c-(bw/2) and y>200-(bh/2) and x<c+(bw/2) and y<c+(bh/2) then
						check(l1)
						break
					end
				end
			elseif hook.name=="key_down" then
				local key=tonumber(x)
				if key and key>0 and key<5 then
					check(key)
				end
			end
		end
		current.done=cn
		for l1=255,0,-20 do
			current.walpha=l1
			current.green=l1
			wait(0.01)
		end
		current.walpha=0
		current.green=0
		wait(1)
		for l1=255,0,-10 do
			current.alpha=l1
			wait(0.01)
		end
		new(math.floor(letters))
	end
end

resume=coroutine.wrap(main)

function love.load()
	love.window.setMode(800,400)
	resume()
end

function love.mousepressed(x,y,bt)
	hook.queue("mouse_down",x,y,bt)
end

function love.keypressed(k,r)
	hook.queue("key_down",k,r)
end

function love.update(dt)
	hook.queue("update",dt)
	letters=math.max(letters-(dt/30),4)
	local w,h=graphics.getDimensions()
	cbarlen=(cbarlen+((w-100)*(letters/24)*(dt*2)))/(1+(dt*2))
end

local font=setmetatable({},{__index=function(s,n)
	s[n]=love.graphics.newFont(n)
	return s[n]
end})

local function centerText(txt,x,y,w,size)
	love.graphics.setFont(font[size])
	love.graphics.printf(txt,x,y,w,"center")
end

local function roundedRectangle(x,y,w,h,r)
	r=r or 10
	love.graphics.rectangle("fill",x+r,y,w-r*2,r)
	love.graphics.rectangle("fill",x+r,y+h-r,w-r*2,r)
	love.graphics.rectangle("fill",x,y+r,w,h-r*2)
	love.graphics.arc("fill",x+r,y+r,r,math.pi,math.pi*1.5)
	love.graphics.arc("fill",x+w-r,y+r,r,math.pi/-2,0)
	love.graphics.arc("fill",x+w-r,y + h-r,r,0,math.pi/2)
	love.graphics.arc("fill",x+r,y+h-r,r,math.pi/2,math.pi)
end

function love.draw()
	local w,h=graphics.getDimensions()
	graphics.setBackgroundColor(255,255,255)
	graphics.setColor(20,20,20,current.alpha)
	centerText(current.question,0,10,w,100)
	local bw=math.floor(w/6)
	local bh=math.floor(bw/1.2)
	for l1=1,4 do
		local c=math.floor((l1/5)*w)
		graphics.setColor(20,20,20,current.done==l1 and current.alpha or current.walpha)
		roundedRectangle(c-(bw/2),200-(bh/2),bw,bh)
		graphics.setColor(current.done==l1 and current.green or 200,200,current.done==l1 and current.green or 200,current.done==l1 and current.alpha or current.walpha)
		centerText(current.answers[l1],c-(bw/2),200-(bh/2),bw,40)
		if current.answered[l1] then
			graphics.setColor(200,20,20,current.done==l1 and current.alpha or current.walpha)
			centerText(current.answered[l1],c-(bw/2),250-(bh/2),bw,40)
		end
	end
	graphics.setColor(20,200,20)
	roundedRectangle(50,300,cbarlen,50)
end


