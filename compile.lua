local lfs=require("lfs")
local function list(dir)
	local o={}
	for fn in lfs.dir(dir or ".") do
		if fn~="." and fn~=".." then
			o[fn]=true
		end
	end
	return o
end
local function isDir(dir)
	local dat=lfs.attributes(dir)
	return dat and dat.mode=="directory"
end
local function exists(dir)
	return lfs.attributes(dir)~=nil
end
local function split(file)
	local t={}
		for dir in file:gmatch("[^/]+") do
			t[#t+1]=dir
		end
	return t
end
local function combine(filea,fileb)
	local o={}
	for k,v in pairs(split(filea)) do
		table.insert(o,v)
	end
	for k,v in pairs(split(fileb)) do
		table.insert(o,v)
	end
	return filea:match("^/?")..table.concat(o,"/")..fileb:match("/?$")
end
for k,v in pairs(list()) do
	if isDir(k) then
		if exists(combine(k,"main.lua")) then
			os.execute("rm "..k..".love")
			os.execute("cd "..k.." && zip -r -9 "..k..".love * && mv "..k..".love ..")
		end
	end
end


