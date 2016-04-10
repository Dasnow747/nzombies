local wep = FindMetaTable("Weapon")
local ply = FindMetaTable("Player")

function wep:IsSpecial()
	return SpecialWeapons.Weapons[self:GetClass()] and true or false
end

function wep:GetSpecialCategory()
	return SpecialWeapons.Weapons[self:GetClass()].id
end

function ply:GetSpecialWeaponFromCategory( id )
	if !self.NZSpecialWeapons then self.NZSpecialWeapons = {} end
	return self.NZSpecialWeapons[id] or nil
end

function ply:EquipPreviousWeapon()
	if IsValid(self.NZPrevWep) then -- If the previously used weapon is valid, use that
		self:SelectWeapon(self.NZPrevWep:GetClass())
	else
		for k,v in pairs(self:GetWeapons()) do -- And pick the first one that isn't special
			if !v:IsSpecial() then self:SelectWeapon(v:GetClass()) return end
		end
		self:SetActiveWeapon(nil)
	end
end

-- Prevent players from manually switching to the weapon if it is special - it is handled by the bind
hook.Add("PlayerSwitchWeapon", "PreventSwitchingToSpecialWeapons", function(ply, oldwep, newwep)
	if IsValid(oldwep) and IsValid(newwep) then
		if (!ply:GetUsingSpecialWeapon() and newwep:IsSpecial()) or (ply:GetUsingSpecialWeapon() and oldwep:IsSpecial()) then return true end
		if oldwep != newwep and !oldwep:IsSpecial() then
			ply.NZPrevWep = oldwep
			print(ply.NZPrevWep, "2")
		end
	end
end)

if SERVER then
	function ply:AddSpecialWeapon(wep)
		if !self.NZSpecialWeapons then self.NZSpecialWeapons = {} end
		local id = wep:GetSpecialCategory()
		self.NZSpecialWeapons[id] = wep
		SpecialWeapons:SendSpecialWeaponAdded(self, wep, id)
		if SpecialWeapons.Weapons[wep:GetClass()].equip then
			SpecialWeapons.Weapons[wep:GetClass()].equip(self, wep)
		end
	end

	-- This hook only works server-side
	hook.Add("WeaponEquip", "SetSpecialWeapons", function(wep)
		if wep:IsSpecial() then
			-- 0 second timer for the next tick where wep's owner is valid
			timer.Simple(0, function()
				local ply = wep:GetOwner()
				if IsValid(ply) then
					local oldwep = ply:GetSpecialWeaponFromCategory( wep:GetSpecialCategory() )
					print(wep, oldwep)
					if IsValid(oldwep) then
						ply:StripWeapon(oldwep:GetClass())
					end
					ply:AddSpecialWeapon(wep)
				end		
			end)
		end
	end)
end