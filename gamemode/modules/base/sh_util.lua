-----------------------------------------------------------------------------[[
/*---------------------------------------------------------------------------
Utility functions
---------------------------------------------------------------------------*/
-----------------------------------------------------------------------------]]

local vector = FindMetaTable("Vector")
local meta = FindMetaTable("Player")
local config = GM.Config

/*---------------------------------------------------------------------------
Decides whether the vector could be seen by the player if they were to look at it
---------------------------------------------------------------------------*/
function vector:isInSight(filter, ply)
	ply = ply or LocalPlayer()
	local trace = {}
	trace.start = ply:EyePos()
	trace.endpos = self
	trace.filter = filter
	trace.mask = -1
	local TheTrace = util.TraceLine(trace)

	return not TheTrace.Hit, TheTrace.HitPos
end

/*---------------------------------------------------------------------------
Turn a money amount into a pretty string
---------------------------------------------------------------------------*/
local function attachCurrency(str)
	return config.currencyLeft and config.currency .. str or str .. config.currency
end

function DarkRP.formatMoney(n)
	if not n then return attachCurrency("0") end

	if n >= 1e14 then return attachCurrency(tostring(n)) end

	n = tostring(n)
	local sep = sep or ","
	local dp = string.find(n, "%.") or #n+1

	for i=dp-4, 1, -3 do
		n = n:sub(1, i) .. sep .. n:sub(i+1)
	end

	return attachCurrency(n)
end

/*---------------------------------------------------------------------------
Find a player based on given information
---------------------------------------------------------------------------*/
function DarkRP.findPlayer(info)
	if not info or info == "" then return nil end
	local pls = player.GetAll()

	for k = 1, #pls do -- Proven to be faster than pairs loop.
		local v = pls[k]
		if tonumber(info) == v:UserID() then
			return v
		end

		if info == v:SteamID() then
			return v
		end

		if string.find(string.lower(v:SteamName()), string.lower(tostring(info)), 1, true) ~= nil then
			return v
		end

		if string.find(string.lower(v:Name()), string.lower(tostring(info)), 1, true) ~= nil then
			return v
		end
	end
	return nil
end

function meta:getEyeSightHitEntity(searchDistance, hitDistance, filter)
	searchDistance = searchDistance or 100
	hitDistance = hitDistance or 15
	filter = filter or function(p) return p:IsPlayer() and p ~= self end

	local shootPos = self:GetShootPos()
	local entities = ents.FindInSphere(shootPos, searchDistance)
	local aimvec = self:GetAimVector()
	local eyeVector = shootPos + aimvec * searchDistance

	local smallestDistance = math.huge
	local foundEnt

	for k, ent in pairs(entities) do
		if not IsValid(ent) or filter(ent) == false then continue end

		local center = ent:GetPos()
		center.z = eyeVector.z

		-- project the center vector on the aim vector
		local projected = shootPos + (center - shootPos):Dot(aimvec) * aimvec

		-- the point on the model that has the smallest distance to your line of sight
		local nearestPoint = ent:NearestPoint(projected)
		local distance = nearestPoint:Distance(projected)

		if distance < smallestDistance then
			local trace = {
				start = self:GetShootPos(),
				endpos = nearestPoint,
				filter = {self, ent}
			}
			local traceLine = util.TraceLine(trace)
			if traceLine.Hit then continue end

			smallestDistance = distance
			foundEnt = ent
		end
	end

	if smallestDistance < hitDistance then
		return foundEnt, smallestDistance
	end

	return nil
end

/*---------------------------------------------------------------------------
Print the currently available vehicles
---------------------------------------------------------------------------*/
local function GetAvailableVehicles(ply)
	if SERVER and IsValid(ply) and not ply:IsAdmin() then return end
	local print = SERVER and ServerLog or Msg

	print(DarkRP.getPhrase("rp_getvehicles") .. "\n")
	for k,v in pairs(DarkRP.getAvailableVehicles()) do
		print("\""..k.."\"" .. "\n")
	end
end
if SERVER then
	concommand.Add("rp_getvehicles_sv", GetAvailableVehicles)
else
	concommand.Add("rp_getvehicles", GetAvailableVehicles)
end

/*---------------------------------------------------------------------------
Whether a player has a DarkRP privilege
---------------------------------------------------------------------------*/
function meta:hasDarkRPPrivilege(priv)
	if FAdmin then
		return FAdmin.Access.PlayerHasPrivilege(self, priv)
	end
	return self:IsAdmin()
end

/*---------------------------------------------------------------------------
Convenience function to return the players sorted by name
---------------------------------------------------------------------------*/
function DarkRP.nickSortedPlayers()
	local plys = player.GetAll()
	table.sort(plys, function(a,b) return a:Nick() < b:Nick() end)
	return plys
end