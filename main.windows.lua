local function parseError(msg)
	if msg:match("exit") or msg:match("interrupted!") then
		return true
	elseif not msg:match("reload") then
		print(msg)
	end
	io.write("\n")
	return false
end

local function cut(s,pattern,delpattern,i)
	if type(s) ~= "string" then error("bad argument #1 to 'string.cut' (string expected, got "..type(t)..")") end
	if type(pattern) ~= "string" then error("bad argument #2 to 'string.cut' (string expected, got "..type(t)..")") end
	local i2 = 0
	if delpattern == nil then delpattern = true end
	if tonumber(i) ~= nil then i2 = i-1 end
	local cutstring = {}
	repeat
		local i1 = i2
		i2 = s:find(pattern,i1+1)
		if i2 == nil then i2 = s:len()+1 end
		if delpattern then
			table.insert(cutstring,s:sub(i1+1,i2-1))
		else
			table.insert(cutstring,s:sub(i1,i2-1))
		end
	until i2 == s:len()+1
	return cutstring
end

local function getScriptDir(source) --requires: cut
	if source == nil then
		source = debug.getinfo(1).source
	end
	local pwd = ""
	local pwd1 = (io.popen("echo %cd%"):read("*l")):gsub("\\","/")
	local pwd2 = source:sub(2):gsub("\\","/")
	if pwd2:sub(2,3) == ":/" then
		pwd = pwd2:sub(1,pwd2:find("[^/]*%.lua")-1)
	else
		local path1 = cut(pwd1:sub(4),"/")
		local path2 = cut(pwd2,"/")
		for i = 1,#path2-1 do
			if path2[i] == ".." then
				table.remove(path1)
			else
				table.insert(path1,path2[i])
			end
		end
		pwd = pwd1:sub(1,3)
		for i = 1,#path1 do
			pwd = pwd..path1[i].."/"
		end
	end
	return pwd
end

rootpath,cut,getScriptDir = getScriptDir(),nil,nil
rootpathwin = rootpath:gsub('/','\\')

for filename in io.popen("dir /b \""..rootpathwin.."modules\\*.lua\""):lines() do
	xpcall(loadfile(rootpath.."modules/"..filename),parseError)
end

--------------------------------

function buildwordgenmechanics()
	local lettermechanics = {}
	for filename in io.popen("dir /b \""..rootpathwin.."dictionnaries\""):lines() do
		print('Reading "'..filename..'" dictionnary...')
		local language = filename:sub(1,filename:find('%.')-1)
		if lettermechanics[language] == nil then
			lettermechanics[language] = {}
		end
		local file = io.open(rootpath.."dictionnaries/"..filename,'r')
		lettermechanics[language].words = '\n'..file:read('a')
		local wordcount = select(2,lettermechanics[language].words:gsub('\n',''))+1
		file:seek('set')
		local counter,clock = 0,os.clock()
		print('0%...')
		for word in file:lines() do
			counter = counter+1
			if os.clock() >= clock+0.5 then
				clock = os.clock()
				print(string.format('%.1f%%...',100*counter/wordcount))
			end
			if not word:find('[^a-zA-Z-]') then
				for i = 1,(#word)-1 do
					pchar,cchar,fchar = word:sub(i-1,i-1):lower(),word:sub(i,i):lower(),word:sub(i+1,i+1):lower()
					if pchar == '' then
						pchar = 'none'
					end
					if lettermechanics[language][cchar] == nil then
						lettermechanics[language][cchar] = {}
					end
					if lettermechanics[language][cchar][fchar] == nil then
						lettermechanics[language][cchar][fchar] = {}
					end
					if lettermechanics[language][cchar][fchar].following == nil then
						lettermechanics[language][cchar][fchar].following = 0
					end
					if lettermechanics[language][cchar].followingtotal == nil then
						lettermechanics[language][cchar].followingtotal = 0
					end
					lettermechanics[language][cchar][fchar].following = lettermechanics[language][cchar][fchar].following+1
					lettermechanics[language][cchar].followingtotal = lettermechanics[language][cchar].followingtotal+1
					if lettermechanics[language][cchar][pchar] == nil then
						lettermechanics[language][cchar][pchar] = {}
					end
					if lettermechanics[language][cchar][pchar].preceding == nil then
						lettermechanics[language][cchar][pchar].preceding = {}
					end
					if lettermechanics[language][cchar][pchar].preceding[fchar] == nil then
						lettermechanics[language][cchar][pchar].preceding[fchar] = 0
					end
					if lettermechanics[language][cchar][pchar].precedingtotal == nil then
						lettermechanics[language][cchar][pchar].precedingtotal = 0
					end
					lettermechanics[language][cchar][pchar].preceding[fchar] = lettermechanics[language][cchar][pchar].preceding[fchar]+1
					lettermechanics[language][cchar][pchar].precedingtotal = lettermechanics[language][cchar][pchar].precedingtotal+1
				end
			end
		end
		print('100%')
		file:close()
	end
	print("Analyzing word generation mechanics...")
	for lang,langtable in pairs(lettermechanics) do
		for cchar,cchartable in pairs(langtable) do
			if cchar ~= 'words' then
				cchartable.following = {chars = {}, probs = {[0] = 0}}
				for fchar,fchartable in pairs(cchartable) do
					if not table.find({'preceding','following','followingtotal'},fchar) then
						if fchartable.preceding ~= nil then
							if cchartable.preceding == nil then
								cchartable.preceding = {}
							end
							cchartable.preceding[fchar] = {chars = {}, probs = {[0] = 0}}
							for pchar,pcharocc in pairs(fchartable.preceding) do
								table.insert(cchartable.preceding[fchar].chars,pchar)
								table.insert(cchartable.preceding[fchar].probs,pcharocc/fchartable.precedingtotal+cchartable.preceding[fchar].probs[#cchartable.preceding[fchar].probs])
							end
							cchartable.preceding[fchar].probs[0] = nil
						end
						if fchar ~= 'none' and fchartable.following ~= nil then
							table.insert(cchartable.following.chars,fchar)
							table.insert(cchartable.following.probs,fchartable.following/cchartable.followingtotal+cchartable.following.probs[#cchartable.following.probs])
						end
						cchartable[fchar] = nil
					end
				end
				cchartable.following.probs[0] = nil
				cchartable.followingtotal = nil
			end
		end
	end
	print('Done!')
	sleep(1.5)
	return lettermechanics
end

function generateword(len,lang,method,firstletter)
	method = method or '111'
	firstletter = firstletter or string.char(math.random(97,122))
	local words = {}
	if method:sub(1,1) == '1' then
		words[1] = firstletter
		for l = 1,len-1 do
			words[1] = words[1]..string.char(math.random(97,122))
		end
	end
	if method:sub(2,2) == '1' then
		words[2] = firstletter
		for l = 1,len-1 do
			local rand,i = math.random(),1
			while rand > lettermechanics[lang][words[2]:sub(#words[2],#words[2])].following.probs[i] do
				i = i+1
			end
			words[2] = words[2]..lettermechanics[lang][words[2]:sub(#words[2],#words[2])].following.chars[i]
		end
	end
	if method:sub(3,3) == '1' then
		words[3] = firstletter
		for i = 1,len-1 do
			if words[3]:sub(i-1,i-1) == '' then
				pchar = 'none'
			else
				pchar = words[3]:sub(i-1,i-1)
			end
			local rand,i,nextchar = math.random(),1,string.char(math.random(97,122))
			if lettermechanics[lang][words[3]:sub(#words[3],#words[3])] ~= nil then
				if lettermechanics[lang][words[3]:sub(#words[3],#words[3])].preceding[pchar] ~= nil then
					while rand > lettermechanics[lang][words[3]:sub(#words[3],#words[3])].preceding[pchar].probs[i] do
						i = i+1
					end
					nextchar = lettermechanics[lang][words[3]:sub(#words[3],#words[3])].preceding[pchar].chars[i]
				elseif lettermechanics[lang][words[3]:sub(#words[3],#words[3])].following ~= nil then
					while rand > lettermechanics[lang][words[3]:sub(#words[3],#words[3])].following.probs[i] do
						i = i+1
					end
					nextchar = lettermechanics[lang][words[3]:sub(#words[3],#words[3])].following.chars[i]
				end
			end
			words[3] = words[3]..nextchar
		end
	end
	return words
end

lettermechanics = buildwordgenmechanics()
local language,minlen,maxlen,wordgenmethod,maxattempts = 'english',6,12,'001',2000

repeat
	clear()
	io.write('0.Stop script\n1.Generate random words\n2.Test word generation methods\n3.Settings\n4.Explanation\n\n~ Choice: ')
	local input = io.read()
	if input == '1' then
		input = nil
		repeat
			local length = math.random(minlen,maxlen)
			if tonumber(input) ~= nil and tonumber(input) >=1 then
				length = tonumber(input)
			end
			local words = generateword(length,language,wordgenmethod)
			if words[1] then
				print(' Random: '..words[1])
			end
			if words[2] then
				print(' Follow: '..words[2])
			end
			if words[3] then
				print('Precede: '..words[3])
			end
			print()
			io.write('~ Word length (0 to go back): ')
			input = io.read()
		until input == '0'
		input = nil
	elseif input == '2' then
		local n,length = 1,minlen
		repeat
			print('Generating '..n..' existing word'..string.sub('s',1,n-1)..'...')
			local savedi = {0,0,0}
			for j = 1,n do
				local tempmethod,i,letter = wordgenmethod,0,string.char(math.random(97,122))
				repeat
					i = i+1
					local words = generateword(length,language,tempmethod,letter)
					if words[1] and lettermechanics[language].words:find('\n'..words[1]:gsub('-','%%-')..'\n') then
						tempmethod = '0'..tempmethod:sub(2)
						savedi[1] = savedi[1]+i
						print('Random: found "'..words[1]..'" in '..i..' attempt'..string.sub('s',1,savedi[3]-1))
					end
					if words[2] and lettermechanics[language].words:find('\n'..words[2]:gsub('-','%%-')..'\n') then
						tempmethod = tempmethod:sub(1,1)..'0'..tempmethod:sub(3)
						savedi[2] = savedi[2]+i
						print('Follow: found "'..words[2]..'" in '..i..' attempt'..string.sub('s',1,savedi[3]-1))
					end
					if words[3] and lettermechanics[language].words:find('\n'..words[3]:gsub('-','%%-')..'\n') then
						tempmethod = tempmethod:sub(1,2)..'0'
						savedi[3] = savedi[3]+i
						print('Precede: found "'..words[3]..'" in '..i..' attempt'..string.sub('s',1,savedi[3]-1))
					end
				until tempmethod == '000' or i == maxattempts
				if tempmethod ~= '000' and i == maxattempts then
					print('Maximum amount of attempts reached.')
				end
			end
			if n > 1 then
				print('\nAverages:')
				if toboolean(savedi[1]) then
					print('Random: '..savedi[1]/n..' attempt'..string.sub('s',1,math.ceil(savedi[1]/n)-1))
				end
				if toboolean(savedi[2]) then
					print('Follow: '..savedi[2]/n..' attempt'..string.sub('s',1,math.ceil(savedi[2]/n)-1))
				end
				if toboolean(savedi[3]) then
					print('Precede: '..savedi[3]/n..' attempt'..string.sub('s',1,math.ceil(savedi[3]/n)-1))
				end
			end
			io.write('\nAmount and length of words to find (amount,length)(0 to go back): ')
			inputs = string.cut(io.read(),', *')
			if tonumber(inputs[1]) and tonumber(inputs[1]) >= 0 then
				n = tonumber(inputs[1])
			end
			if tonumber(inputs[2]) and tonumber(inputs[2]) >= 1 then
				length = tonumber(inputs[2])
			end
		until n == 0
		input = nil
	elseif input == '3' then
		repeat
			clear()
			io.write('0.Back to menu\n1.Words language: '..language..'\n2.Minimum/maximum word length: '..minlen..'-'..maxlen..'\n3.Word generation method ([random][following][preceding]): '..wordgenmethod..'\n4.Maximum amount of attempts: '..maxattempts..'\n5.Rebuild word generation mechanics\n\n~ Choice: ')
			input = io.read()
			if input == '1' then
				repeat
					io.write('~ Words language: ')
					language = io.read()
				until table.find(lettermechanics,language,'k')
				input = nil
			elseif input == '2' then
				repeat
					io.write('~ Minimum word length (>=2): ')
					minlen = tonumber(io.read())
				until minlen ~= nil and minlen >= 2 and minlen%1 == 0
				repeat
					io.write('~ Maximum word length (>='..minlen..'): ')
					maxlen = tonumber(io.read())
				until maxlen ~= nil and maxlen >= 2 and minlen%1 == 0
				input = nil
			elseif input == '3' then
				repeat
					io.write('~ Word generation method ([random][follow][precede]): ')
					wordgenmethod = io.read()
					if tonumber(wordgenmethod) ~= nil then
						if #wordgenmethod == 1 and tonumber(wordgenmethod) >= 1 and tonumber(wordgenmethod) <= 7 then
							wordgenmethod = tobits(tonumber(wordgenmethod))
						end
					end
				until #wordgenmethod == 3 and wordgenmethod:gsub('[01]*','') == '' and wordgenmethod ~= '000'
				input = nil
			elseif input == '4' then
				repeat
					io.write('~ Maximum amount of attempts (>=1 or inf): ')
					input = io.read()
					if input == 'inf' then
						maxattempts = math.huge
					else
						maxattempts = tonumber(input)
					end
				until maxattempts ~= nil and maxattempts >= 1
				input = nil
			elseif input == '5' then
				buildwordgenmechanics()
				input = nil
			end
		until input == '0'
		input = nil
	elseif input == '4' then
		io.write('\nThis script reads the dictionnaries of words provided in the "dictionnaries" folder and analyzes how every word is constructed in two different ways:\n	Follow: Checks for the probability of a letter coming right after another letter\n	Precede: Checks for the probability of a letter coming right after another letter when it is preceded by a specific letter\n	Random: All letters have the same proabability of being generated\n~ Press enter to go back... ')
		io.read()
	end
until input == '0'