local module = {}

-- example: strsplit(",%s*", "Anna, Bob, Charlie,Dolores")
function module.strsplit(inputstr,sep)
	if sep == nil then
		sep = "%s"
	end
	local t={}
	for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
		table.insert(t,str)
	end
	return t

end

return module

