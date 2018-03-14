function toboolean(v)
	if type(v) == "boolean" then
		return v
	elseif type(v) == "number" then
		if v >= 1 then return true end
	elseif type(v) == "string" then
		if v == "true" or tonumber(v) == 1 then return true end
	end
	return false
end

function tobits(n)
	local t = {} -- will contain the bits
	while n > 0 do
		remainder = math.fmod(n,2)
		table.insert(t,1,math.floor(remainder))
		n = (n-remainder)/2
	end
	return table.concat(t)
end

_tostring = _tostring or tostring
function tostring(...)
	local args = {table.unpack({...})}
	local strings = {_tostring(args[1])}
	for i = 2,#args do
		table.insert(strings,_tostring(args[i]))
	end
	return table.unpack(strings)
end

_tonumber = _tonumber or tonumber
function tonumber(...)
	local args = {table.unpack({...})}
	local numbers = {_tonumber(args[1])}
	for i = 2,#args do
		table.insert(numbers,_tonumber(args[i]))
	end
	return table.unpack(numbers)
end

string._byte = string._byte or string.byte
function string.byte(s,i,j)
	local ascii = {string._byte(s,i,j)}
	if ascii[1] == nil then
		return -1
	end
	return table.unpack(ascii)
end
 
function string.cut(s,pattern,delpattern,i)
	if type(s) ~= "string" then error("bad argument #1 to 'string.cut' (string expected, got "..type(t)..")") end
	if type(pattern) ~= "string" then error("bad argument #2 to 'string.cut' (string expected, got "..type(t)..")") end
	local i2,i3 = 0,0
	delpattern = delpattern or true
	if tonumber(i) ~= nil then i2,i3 = i-1,i-1 end
	local cutstring = {}
	repeat
		local i1 = i3
		i2,i3 = s:find(pattern,i1+1)
		if i2 == nil then i2 = s:len()+1 end
		if delpattern then
			table.insert(cutstring,s:sub(i1+1,i2-1))
		else
			table.insert(cutstring,s:sub(i1,i2-1))
		end
	until i2 == s:len()+1
	return cutstring
end

function alphabetical(s1,s2,returnstring) --need to add ability to sort negative numbers
	if not (type(s1) == "string" or type(s1) == "number") then error("bad argument #1 to 'alphabetical' (string expected, got "..type(s1)..")") end
	if not (type(s2) == "string" or type(s2) == "number") then error("bad argument #2 to 'alphabetical' (string expected, got "..type(s2)..")") end
	local t,f = 0,0 -- true,false
	if returnstring then t,f = s1,s2
	else t,f = true,false
	end
	if not tostring(s1) and not tostring(s2) then return f
	elseif not tostring(s2) then return t
	elseif not tostring(s1) then return f
	else s1,s2 = tostring(s1,s2)
	end
	local low1,low2 = s1:lower(),s2:lower()
	for i = 1,math.max(s1:len(),s2:len()) do
		local l1,l2 = low1:byte(i,i),low2:byte(i,i)
		local r1,r2 = s1:byte(i,i),s2:byte(i,i)
		if tonumber(low1:sub(i,i)) ~= nil and tonumber(low2:sub(i,i)) ~= nil then
			l1,l2 = tonumber(low1:match("%d+",i),low2:match("%d+",i))
			i = math.max(low1:find("%d+"),low2:find("%d+"))
		end
		if l1 < l2 or r1 < r2 then return t
		elseif l2 < l1 or r2 < r1 then return f
		elseif i == low2:len() then return f
		elseif i == low1:len() then return t
		end
	end
end

function table.shift(t,n)
	local indexes,sign = {},(n/math.abs(n))
	for k,v in pairs(t) do
		if tonumber(k) ~= nil then
			table.insert(indexes,k)
		end
	end
	-- if n > 0 then for 1,#indexes; elseif n < 0 then for #indexes,1,-1
	if #indexes > 0 then
		for i = math.max(1,sign*(#indexes)),math.max(1,-sign*(#indexes)),-sign do
			t[i+n] = t[i]
			t[i] = nil
		end
	end
	return t
end

function table.find(t,value,kv)
	if type(t) ~= "table" then error("bad argument #1 to 'table.find' (table expected, got "..type(t)..")") end
	if type(value) == nil then error("bad argument #2 to 'table.find' (value expected, got "..type(value)..")") end
	if type(kv) ~= "string" or #kv ~= 1 or not kv:match('[kv]') then kv = 'v' end
	local indexes,subtables = {},{}
	for k,v in pairs(t) do
		if (kv == 'k' and k == value) or (kv == 'v' and v == value) then
			return k
		elseif type(v) == "table" then
			table.insert(subtables,k)
		end
	end
	for k,v in pairs(subtables) do
		local subindex = table.find(t[v],value,kv)
		if subindex then
			return v..'.'..subindex
		end
	end
	return false
end

function table.index(t,chainkey)
end

function cls()
	print()
	for i = 1,10 do
		print('.')
	end
	print()
end

function sleep(n)	-- seconds
	local start = os.clock()
	while os.clock()-start <= n do end
end

function orderedPairs(t)
	return orderedNext, t, "__nil"
end

function orderedNext(t,state)
	if t.__orderedIndex == nil then
		local indexes = {[0] = "__nil"}
		for k in pairs(t) do
			table.insert(indexes,k)
		end
		table.sort(indexes,alphabetical)
		t.__orderedIndex = indexes
	end
	local i = table.find(t.__orderedIndex,state)+1
	if i > #t.__orderedIndex then
		t.__orderedIndex = nil
		return nil
	else
		return t.__orderedIndex[i], t[t.__orderedIndex[i]]
	end
end