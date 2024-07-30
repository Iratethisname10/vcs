local name = '[requires]';

local shortened = {
	['@notifs'] = 'interface/toastNotification.lua',

	['@utils'] = 'utils/Utility.lua',
	['@maid'] = 'utils/modules/Maid.lua',
	['@signal'] = 'utils/modules/Signal.lua',
	['@basics'] = 'utils/helpers/basics.lua',
	['@pathfindind'] = 'utils/modules/Pathfinding.lua'
};

local timeout = 15;
local githubPath = 'https://raw.githubusercontent.com/Iratethisname10/UnboundedYieldV2/main/';
local localFilePath = 'Unbounded Yield V2/';
local responseErrors = {'404: Not Found', '400: Invalid Request'};

local function printf(text: string, ...) return print(name, string.format(text, ...)); end;
local function warnf(text: string, ...) return warn(name, string.format(text, ...)); end;

local function getgenv() return _G; end;

getgenv().vcsCache = getgenv().vcsCache or {};
getgenv().vcsJSONCache = getgenv().vcsJSONCache or {};

local hash = function(data)
	return crypt.hash(string.format('$s/s\t %s\a﷽📙\n+2陷a%sa$%s􀏿','꧅',data,'?'),'sha256');
end;

getgenv().getJSON = getgenv().getJSON or function(scriptName: string)
	assert(typeof(scriptName) == 'string', 'scriptName has to be a string');

	local formatted = string.gsub(scriptName, '%s+', '');
	local extension = string.match(formatted, '.+%w+%p(%w+)');
	assert(extension == 'json', 'must be a json file');

	if (shortened[formatted]) then formatted = shortened[formatted]; end;

	local cached = getgenv().vcsJSONCache[formatted];
	if (cached) then
		printf('getting cached %s', formatted);
		return cached;
	end;

	local file = string.format('%s%s', localFilePath, formatted);
	if (isfile(file) and not getgenv().dontUseFile) then
		printf('getting %s from client', formatted);

		getgenv().vcsJSONCache[formatted] = file;
		printf('caching %s', formatted);

		return readfile(file);
	end;

	local success, result;
	task.delay(timeout, function()
		if (result) then return; end;
		warnf('the request for %s is taking more that %s', formatted, timeout);
	end);

	printf('getting %s from server', formatted);

	local url = string.format('%s%s', githubPath, formatted);
	success, result = pcall(function() return game:HttpGet(url); end);

	if (not success or table.find(responseErrors, result)) then
		return warnf('failed to get %s from server: %s', formatted, result);
	end;

	getgenv().vcsCache[formatted] = result;
	printf('caching %s', formatted);

	return result;
end;

getgenv().getScript = getgenv().getScript or function(scriptName: string)
	assert(typeof(scriptName) == 'string', 'scriptName has to be a string');

	local formatted = string.gsub(scriptName, '%s+', '');
	local extension = string.match(formatted, '.+%w+%p(%w+)');
	assert(extension == 'lua' or extension == 'luau', 'must be a lua or luau file');

	if (shortened[formatted]) then formatted = shortened[formatted]; end;

	local cached = getgenv().vcsCache[formatted];
	if (cached) then
		printf('getting cached %s', formatted);

		return cached();
	end;

	local file = string.format('%s%s', localFilePath, formatted);
	if (isfile(file) and not getgenv().dontUseFile) then
		printf('getting %s from client', formatted);

		local scriptFunc, syntaxErr = loadstring(readfile(file), formatted);
		if (syntaxErr) then return warnf('syntax error detected in %s: %s', scriptName, syntaxErr); end;

		getgenv().vcsCache[formatted] = scriptFunc;
		printf('caching %s', formatted);

		return scriptFunc();
	end;

	local success, result;
	task.delay(timeout, function()
		if (result) then return; end;
		warnf('the request for %s is taking more that %s', formatted, timeout);
	end);

	printf('getting %s from server', formatted);

	local url = string.format('%s%s', githubPath, formatted);
	success, result = pcall(function() return game:HttpGet(url); end);

	if (not success or table.find(responseErrors, result)) then
		return warnf('failed to get %s from server: %s', formatted, result);
	end;

	local scriptFunc, syntaxErr = loadstring(result, formatted);
	if (not scriptFunc) then return warnf('syntax error detected in %s: %s', scriptName, syntaxErr); end;

	getgenv().vcsCache[formatted] = scriptFunc;
	printf('caching %s', formatted);

	return scriptFunc();
end;

getgenv().crashScript = getgenv().crashScript or function()
	task.spawn(function() table.clear(getreg()); end);
	task.spawn(function() setfpscap(9e9); end);
	task.spawn(function() repeat until false; end);
end;

getgenv().hashString = getgenv().hashString or hash;

return {version = '1'};