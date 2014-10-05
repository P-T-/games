require("hook")
flux = require "flux"

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
local animation

local function new(letters)
	local cn=love.math.random(0,letters-1)
	local o=--[[math.random(0,1)==0 and]] 65 --[[or 97]]
	local cs=o+math.max(math.min(cn-love.math.random(0,3),22),0)
	local cv=o+cn
	current={
		question=string.char(cv),
		answers={},
		answered={},
		answer=cv,
		colors={}
	}
	for l1=cs,cs+3 do
		table.insert(current.answers,string.format("%02x",l1))
		table.insert(current.colors,{love.math.random(192,255),love.math.random(192,255),love.math.random(192,255)})
	end
end

local letters
local cbarlen
local function main()
	love.math.setRandomSeed(os.time()*1000)
	letters=4
	cbarlen=0
	pmap={}
	while true do
		new(math.floor(letters))
		if animation then wait(0.5) end --wait for animation to end, else if you go too quick it errors
		local cn
		while not cn do
			local x,y,bt=pull("mouse_down","key_down")
			local w,h=graphics.getDimensions()
			local bw=math.floor(w/6)
			local bh=math.floor(bw/1.2)
			local function check(l1)
				if current.answer==tonumber(current.answers[l1],16) then
					cn=l1
					letters=math.min(letters+0.5,24)
					
					local c=math.floor((l1/5)*w)
					animation = {
						x=c-(bw/2),
						y=200-(bh/2),
						w=bw,
						h=bh,
						color=current.colors[l1],
						alpha=255,
						text=current.answers[l1],
						tvars={c-(bw/2),200-(bh/2),bw,40}
					}
					flux.to(animation,1,{x=0,y=0,w=w,h=h})
						:oncomplete(function() graphics.setBackgroundColor(animation.color) end)
						:after(0.5,{alpha=0})
						:oncomplete(function() animation=nil end)
				elseif not current.answered[l1] then
					current.answered[l1]=string.char(tonumber(current.answers[l1],16))
					letters=math.max(letters-0.5,4)
				end
			end
			if hook.name=="mouse_down" then
				for l1=1,4 do
					local c=math.floor((l1/5)*w)
					if x>c-(bw/2) and y>200-(bh/2) and x<c+(bw/2) and y<c+(bh/2) then
						check(l1)
						break
					end
				end
			elseif hook.name=="key_down" then
				local key=tonumber(x)
				if key and (key>0 and key<5) then
					check(key)
				end
			end
		end
		wait(1)
		current.done=cn
	end
end

resume=coroutine.wrap(main)

function love.load()
	love.window.setMode(800,400)
	graphics.setBackgroundColor(255,255,255)
	resume()
end

function love.mousepressed(x,y,bt)
	hook.queue("mouse_down",x,y,bt)
end

function love.keypressed(k,r)
	hook.queue("key_down",k,r)
end

function love.update(dt)
	flux.update(dt)
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

function love.draw()
	local w,h=graphics.getDimensions()
	graphics.setColor(0,0,0)
	centerText(current.question,0,10,w,100)
	local bw=math.floor(w/6)
	local bh=math.floor(bw/1.2)
	for l1=1,4 do
		if not current.done or current.done==l1 then
			local c=math.floor((l1/5)*w)
			graphics.setColor(current.colors[l1])
			graphics.rectangle("fill",c-(bw/2),200-(bh/2),bw,bh)
			graphics.setColor(20,20,20)
			centerText(current.answers[l1],c-(bw/2),200-(bh/2),bw,40)
			if current.answered[l1] then
				graphics.setColor(200,20,20)
				centerText(current.answered[l1],c-(bw/2),250-(bh/2),bw,40)
			end
		end
	end
	graphics.setColor(20,200,20)
	graphics.rectangle("fill",50,300,cbarlen,50)
	if animation then
		graphics.setColor(animation.color[1],animation.color[2],animation.color[3],animation.alpha)
		graphics.rectangle("fill",animation.x,animation.y,animation.w,animation.h)
		graphics.setColor(20,20,20,animation.alpha)
		centerText(animation.text,unpack(animation.tvars))
	end
end


