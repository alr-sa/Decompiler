-- main.lua
local timer = tick()
local api = game:GetService('HttpService'):JSONDecode(game:HttpGet("http://setup.roblox.com/"..game:HttpGet('http://setup.roblox.com/versionQTStudio',true).."-API-Dump.json",true)).Classes
local data = {}

for i,v in api do
	data[v.Name] = {["Superclass"] = v.Superclass}
	table.foreach(v.Members,function(c,prop) 
		if prop.MemberType == "Property" then 
			data[v.Name][prop.Name] = {prop.ValueType.Name,prop.ValueType.Category}
		end
	end)
end

function check(i)
	if data[i].Superclass ~= "<<<ROOT>>>" then
		table.foreach(data[data[i].Superclass], function(a,b) 
			data[i][a] = b 
		end)
		check(i)
	end
end

for i,_ in data do check(i) end
table.foreach(data,function(i,v) v.Superclass = nil v.Name = nil v.Parent = nil end)

data["UnionOperation"]["AssetId"] = {"Content"}
data["UnionOperation"]["ChildData"] = {"BinaryString"}
data["UnionOperation"]["FormFactor"] = {"Enum"}
data["UnionOperation"]["InitialSize"] = {"Vector3"}
data["UnionOperation"]["MeshData"] = {"BinaryString"}
data["UnionOperation"]["PhysicsData"] = {"BinaryString"}
data["Animator"]["EvaluationThrottled"] = nil
data["MeshPart"]["PhysicsData"] = {"BinaryString"}
data["MeshPart"]["InitialSize"] = {"Vector3"}
-- no point to these for now, planning to add terrain support soon:tm:
--[[data["Terrain"]["SmoothGrid"] = {"TerrainData"}
data["Terrain"]["MaterialColors"] = {"TerrainData"}
data["Terrain"]["PhysicsGrid"] = {"TerrainData"}]]
print(string.format("Initalized! Took %ss",tick()-timer))
--<<            MAIN            >>--

--[[Special types 🤓]]--
local propval
local tableSize = 15000
local types = {
    -- object, X,Y,Z
    ["Vector3"] = function(object,prop) propval = gethiddenproperty(object,prop) return string.format("<Vector3 name=\"%s\"><X>%s</X><Y>%s</Y><Z>%s</Z></Vector3>",prop,propval.X,propval.Y,propval.Z) end,
    -- object, X,Y
    ["Vector2"] = function(object,prop) propval = gethiddenproperty(object,prop) return string.format("<Vector2 name=\"%s\"><X>%s</X><Y>%s</Y></Vector2>",prop,propval.X,propval.Y) end,
    -- object, R,G,B
    ["Color3"] = function(object,prop) propval = gethiddenproperty(object,prop) return string.format("<Color3 name=\"%s\"><R>%s</R><G>%s</G><B>%s</B></Color3>",prop,propval.R,propval.G,propval.B) end,
    -- object, XS, XO, YS, YO
    ["UDim2"] = function(object,prop) propval = gethiddenproperty(object,prop) return string.format("<UDim2 name=\"%s\"><XS>%s</XS><XO>%s</XO><YS>%s</YS><YO>%s</YO></UDim2>",prop,propval.X.Scale,propval.X.Offset,propval.Y.Scale,propval.Y.Offset) end,
    -- object, X,Y,Z
    ["CFrame"] = function(object,prop) propval = gethiddenproperty(object,prop) return string.format("<CoordinateFrame name=\"%s\"><X>%s</X><Y>%s</Y><Z>%s</Z><R00>%s</R00><R01>%s</R01><R02>%s</R02><R10>%s</R10><R11>%s</R11><R12>%s</R12><R20>%s</R20><R21>%s</R21><R22>%s</R22></CoordinateFrame>",prop,propval:GetComponents()) end,
    -- object, base64 encoded prop
    ["TerrainData"] = function(object,prop) return string.format("<BinaryString name=\"%s\"><![CDATA[%s]]></BinaryString>",prop,crypt.base64.encode(gethiddenproperty(object,prop))) end,
    -- object, url
    ["Content"] = function(object,prop) return string.format("<Content name=\"%s\"><url>%s</url></Content>",prop,seralize(gethiddenproperty(object,prop))) end,
    -- object which gets decompiled, prop
    ["ProtectedString"] = function(object,prop) if prop == "Source" and decomp and (object:IsA("LocalScript") or object:IsA("ModuleScript")) then
        w,code = pcall(decompile,object)
        return string.format("<ProtectedString name=\"%s\"><![CDATA[%s]]></ProtectedString>",prop,seralize((w and code or "-- Failed to decompile!"))) 
    end 
    return "" end,
    -- object, prop's value
    ["EnumItem"] = function(object,prop) return string.format("<Token name=\"%s\">%s</Token>",prop,gethiddenproperty(object,prop).Value) end,
    -- object, base64 encoded prop
    ["BinaryString"] = function(object,prop) return string.format("<BinaryString name=\"%s\">%s</BinaryString>",object.ClassName,crypt.base64.encode((typeof(gethiddenproperty(object,prop)) == "EnumItem" and gethiddenproperty(object,prop).Value or gethiddenproperty(object,prop)))) end,
    ["UniqueId"] = function(object,prop) return string.format("<UniqueId name=\"%s\">%s</UniqueId>",object.ClassName,crypt.base64.encode((typeof(gethiddenproperty(object,prop)) == "EnumItem" and gethiddenproperty(object,prop).Value or gethiddenproperty(object,prop)))) end,
    ["SharedString"] = function(object,prop) return string.format("<SharedString name=\"%s\">%s</SharedString>",object.ClassName,crypt.base64.encode((typeof(gethiddenproperty(object,prop)) == "EnumItem" and gethiddenproperty(object,prop).Value or gethiddenproperty(object,prop)))) end
}

-- we dont want xml to cry :(
local escapes = {
    ['"'] = '&quot;',
    ['&'] = '&amp;',
    ['<'] = '&lt;',
    ['>'] = '&gt;',
    ['\''] = '&apos;'
}
function seralize(word)
    for i,v in escapes do 
        word = string.gsub(word,i,v)
    end
    return word
end

--[[Totally real string builder 😱]]--
local stringbuilder = table.create(tableSize)

local counter = 0
function add(text,endpoint)
    counter += 1
    table.insert(stringbuilder,text.."\n")
    if counter == tableSize or endpoint then 
        appendfile(game.PlaceId..".rbxl",table.concat(stringbuilder))
        stringbuilder = table.create(tableSize)
        counter = 0
    end
end

function getobj(object)
    add(string.format("<Item class=\"%s\"><Properties><String name=\"Name\">%s</String>",object.ClassName,seralize(object.Name)))
    if data[object.ClassName] then 
        for propName,propType in data[object.ClassName] do 
            if types[propType[1]] then 
                add(types[propType[1]](object,propName))
            else
                add(string.format("<%s name=\"%s\">%s</%s>",propType[1],propName,seralize(tostring(typeof(gethiddenproperty(object,propName)) == "EnumItem" and gethiddenproperty(object,propName).Value or gethiddenproperty(object,propName))),propType[1]))
            end
        end
        add("</Properties>")
        for i,v in pairs(object:GetChildren()) do 
            getobj(v)
        end
    end
    add("</Item>")
end

getgenv().saveinstance = function(list,dec)
    decomp = dec
    -- list: a list of objects to save
    if not list or #list == 0 then list = {workspace,game.ReplicatedStorage,game.StarterGui,game.Lighting} end
    timer = tick()
    writefile(game.PlaceId..".rbxl",[[<roblox xmlns:xmime="http://www.w3.org/2005/05/xmlmime" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:noNamespaceSchemaLocation="http://www.roblox.com/roblox.xsd" version="4">]])
    table.foreach(list,function(_,obj) getobj(obj) end)
    add("</roblox>",true)
    print(string.format("Saved! took %ss",tick()-timer))
end

saveinstance() 