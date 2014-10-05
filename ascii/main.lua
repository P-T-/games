require("hook")

local resume
local yield=coroutine.yield
function pull(n)
	hook.new(n,function(...)
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
	local cn=math.random(0,letters-1)
	local o=--[[math.random(0,1)==0 and]] 65 --[[or 97]]
	local cs=o+math.max(math.min(cn-math.random(0,3),22),0)
	local cv=o+cn
	current={
		question=string.char(cv),
		answers={},
		answered={},
		answer=cv
	}
	for l1=cs,cs+3 do
		table.insert(current.answers,string.format("%02x",l1))
	end
end

local letters
local cbarlen
local function main()
	math.randomseed(os.time()*1000)
	letters=4
	cbarlen=0
	pmap={}
	while true do
		new(math.floor(letters))
		local cn
		while not cn do
			local x,y,bt=pull("mouse_down")
			local w,h=graphics.getDimensions()
			local bw=math.floor(w/6)
			local bh=math.floor(bw/1.2)
			for l1=1,4 do
				local c=math.floor((l1/5)*w)
				if x>c-(bw/2) and y>200-(bh/2) and x<c+(bw/2) and y<c+(bh/2) then
					if current.answer==tonumber(current.answers[l1],16) then
						cn=l1
						letters=math.min(letters+0.5,24)
					elseif not current.answered[l1] then
						current.answered[l1]=string.char(tonumber(current.answers[l1],16))
						letters=math.max(letters-0.5,4)
					end
					break
				end
			end
		end
		current.done=cn
		wait(2)
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

function love.draw()
	local w,h=graphics.getDimensions()
	graphics.setBackgroundColor(255,255,255)
	graphics.setColor(0,0,0)
	centerText(current.question,0,10,w,100)
	local bw=math.floor(w/6)
	local bh=math.floor(bw/1.2)
	for l1=1,4 do
		if not current.done or current.done==l1 then
			local c=math.floor((l1/5)*w)
			graphics.setColor(20,20,20)
			graphics.rectangle("fill",c-(bw/2),200-(bh/2),bw,bh)
			graphics.setColor(200,200,200)
			centerText(current.answers[l1],c-(bw/2),200-(bh/2),bw,40)
			if current.answered[l1] then
				graphics.setColor(200,20,20)
				centerText(current.answered[l1],c-(bw/2),250-(bh/2),bw,40)
			end
		end
	end
	graphics.setColor(20,200,20)
	graphics.rectangle("fill",50,300,cbarlen,50)
end

