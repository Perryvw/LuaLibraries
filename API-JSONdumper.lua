--Initial call
--dumpObjectFunc( _G, '_G', 0 )

--Only outputs tables and functions!
function dumpObjectFunc( obj, name, indent )
	--build our indentation offset
	local indentStr = '';
	for i=1,indent do
		indentStr = indentStr..'    '
	end

	--keep track of what we did to prevent infinite cycles
	doneObjs[obj] = true

	--open the JSON object
	print(indentStr..'"'..name..'" : ')
	print(indentStr.."{")

	--loop over all fields
	for k,v in pairsByKeys(obj) do
		
		--if the field is a table recurse
		if type(v) == 'table' and k ~= 'FDesc' and doneObjs[v] == nil and type(k) ~= 'table' and k ~= 'doneObjs' then

			dumpObjectFunc( v, k, indent + 1)

		elseif type(v) == 'function' then
			
			--if the field is a function try to find a description and print
			if obj.FDesc and obj.FDesc[k] then
				print(indentStr..'    "'..k..'" : '..'"'..string.gsub(tostring(obj.FDesc[k]), '\n', '\\n ')..'",')
			else
				print(indentStr..'    "'..k..'" : '..'"No description",')
			end

		elseif type(v) == 'number' or type(v) == 'string' then
			--print constants
			print(indentStr..'    "'..k..'" : "'..v..'",')
		end

	end
	print('"##FIX##"')
	--close JSON object
	print(indentStr.."},")
end

function pairsByKeys (t, f)
  local a = {}
  for n in pairs(t) do table.insert(a, n) end
  table.sort(a, f)
  local i = 0      -- iterator variable
  local iter = function ()   -- iterator function
    i = i + 1
    if a[i] == nil then return nil
    else return a[i], t[a[i]]
    end
  end
  return iter
end