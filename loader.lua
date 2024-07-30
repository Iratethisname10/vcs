local loaderRanAt = tick();

local name = '[loader]';

local scriptVersion = '1';
local recivedData;

local function printf(text: string, ...) return print(name, string.format(text, ...)); end;
local function warnf(text: string, ...) return warn(name, string.format(text, ...)); end;

local timeout = 15;
local githubPath = 'https://raw.githubusercontent.com/Iratethisname10/UnboundedYieldV2/main/requires.lua';
local localFilePath = 'Unbounded Yield V2/requires.lua';
local responseErrors = {'404: Not Found', '400: Invalid Request'};

local success = xpcall(function()
	task.delay(timeout, function()
		if (recivedData) then return; end;
		recivedData = 'failed: exceeded load time';
	end);

	repeat
		if (recivedData) then break; end;

		local success, result = pcall(function()
			if (isfile(localFilePath) and not getgenv().dontUseFile) then
				return readfile(localFilePath);
			end;

			return game:HttpGet(githubPath);
		end);

		if (not success or table.find(responseErrors, result)) then
			recivedData = 'failed: error recived when getting require file';
			break;
		end;

		recivedData = loadstring(result);

		task.wait();
	until recivedData;

	if (typeof(recivedData) == 'string' and recivedData:sub(1, 6) == 'failed') then
		return warnf('something went wrong: %s', recivedData:gsub('failed: ', ''));
	end;

	recivedData = recivedData();
	if (recivedData.version ~= scriptVersion) then return
		warnf('current version and recived version is not the same');
	end;
end, function(err)
	warnf('critical error: could not start script: ', err);
	return;
end);

if (not success) then return; end;
printf('passed in %.02f, loading main script.', tick() - loaderRanAt);

return getScript('main-script.lua');
