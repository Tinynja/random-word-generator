local filesystem = {}

if io.popen('ver'):read('a'):lower():match('windows') then

	function filesystem.getscriptdir(source) --requires: string.cut
		if source == nil then
			source = debug.getinfo(1).source
		end
		local pwd = ""
		local pwd1 = (io.popen("echo %cd%"):read("*l")):gsub("\\","/")
		local pwd2 = source:sub(2):gsub("\\","/")
		if pwd2:sub(2,3) == ":/" then
			pwd = pwd2:sub(1,pwd2:find("[^/]*%.lua")-1)
		else
			local path1 = string.cut(pwd1:sub(4),"/")
			local path2 = string.cut(pwd2,"/")
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

	function filesystem.listfiles(path)
		local filelist = '\n_notafile\n'..io.popen('dir /b "'..path:gsub('/','\\')..'"'):read('a')
		local function func(s, var)
			local i = select(2,s:find('\n'..var))+2
			if s:find('\n',i) then
				return s:sub(i,s:find('\n',i)-1)
			else
				return nil
			end
		end
		return func, filelist, '_notafile'
	end

elseif io.popen('cat /etc/*-release | grep -oim 1 linux'):read('a'):lower():match('linux') then

	function filesystem.getscriptdir(source) --requires: string.cut
		if source == nil then
			source = debug.getinfo(1).source
		end
		local pwd = "/"
		local pwd1 = io.popen("pwd"):read("*l")
		local pwd2 = source:sub(2)
		if pwd2:sub(1,1) == "/" then
			pwd = pwd2:sub(1,pwd2:find("[^/]*%.lua")-1)
		else
			local path1 = string.cut(pwd1:sub(2),"/")
			local path2 = string.cut(pwd2,"/")
			for i = 1,#path2-1 do
				if path2[i] == ".." then
					table.remove(path1)
				else
					table.insert(path1,path2[i])
				end
			end
			for i = 1,#path1 do
				pwd = pwd..path1[i].."/"
			end
		end
		return pwd
	end

	function filesystem.listfiles(path)
		local filelist = '\n_notafile\n'..io.popen('ls -1 '..path):read('a')
		local function func(s, var)
			local i = select(2,s:find('\n'..var))+2
			if s:find('\n',i) then
				return s:sub(i,s:find('\n',i)-1):gsub('.*/','')
			else
				return nil
			end
		end
		return func, filelist, '_notafile'
	end

else

	error('This script can currently only be run on Windows or Linux.')

end


return filesystem