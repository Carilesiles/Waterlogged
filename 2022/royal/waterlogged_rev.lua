-- smol shield replacement
function replaceAllMedigunShields()
	for _, shield in pairs(ents.FindAllByClass("entity_medigun_shield")) do
		local shieldOwner = shield.m_hOwnerEntity

		if (not shieldOwner) or tostring(shieldOwner) == "Invalid entity handle id: -1" then
			goto continue
		end

		if shieldOwner.shieldReplacementFlag ~= 1 then
			goto continue
		end

		shield:SetModel("models/props_mvm/mvm_comically_small_player_shield.mdl")

		::continue::
	end
end

-- function replaceShieldModel(shield)
-- 	local shieldOwner = shield:DumpProperties()["m_hOwnerEntity"]

-- 	if not shieldOwner then
-- 		goto continue
-- 	end

-- 	if shieldOwner:DumpProperties()["shieldReplacementFlag"] ~= 1 then
-- 		goto continue
-- 	end

-- 	shield:SetModel("models/props_mvm/mvm_comically_small_player_shield.mdl")

-- 	::continue::
-- end

-- ents.AddCreateCallback(
-- 	"entity_medigun_shield",
-- 	function(shield)
-- 		print(shield)
-- 		timer.Simple(
-- 			-1,
-- 			function()
-- 				replaceShieldModel(shield)
-- 			end
-- 		)
-- 	end
-- )

--set shield charge to 25% whenever it'd be below that to mimic charging faster
function setDefaultShieldCharge(_, activator)
	local properties = activator:DumpProperties()

	if properties["m_bRageDraining"] ~= 0 then
		goto continue
	end

	if properties["m_flRageMeter"] >= 25 then
		goto continue
	end

	activator:AcceptInput("$SetProp$m_flRageMeter", 25)

	::continue::
end

function OnGameTick()
	replaceAllMedigunShields()
end

function removeAllCosmetics(_, activator)
	local cosmetics = {
		activator:GetPlayerItemBySlot(7),
		activator:GetPlayerItemBySlot(8),
		activator:GetPlayerItemBySlot(10),
	}

	for _, wearable in pairs(cosmetics) do
		wearable:Remove()
	end
end

local comfortablyNumbUsers = {}

function clamp(number, min, max)
	return math.min(math.max(number, min), max)
end

local NUMB_CHARGE_RATIO = 3

function comfortablyNumbSpawn(_, activator)
	local handle = activator:GetHandleIndex()

	local applier = ents.FindByName("apply_numb_charge")

	local medigun = activator.m_hMyWeapons[1]

	if comfortablyNumbUsers[handle] then
		comfortablyNumbUnspawn(_, activator)
	end

	comfortablyNumbUsers[handle] = {
		Medigun = medigun,
		Callbacks = {},
		ChargeApplyTimerID = false,
		Charge = 0
	}

	local data = comfortablyNumbUsers[handle]

	data.Callbacks.damageCallback = {
		Type = 4,
		ID = activator:AddCallback(
			4,
			function(_, damageInfo)
				if damageInfo.Attacker.m_iTeamNum == activator.m_iTeamNum then
					return
				end

				local propeties = medigun:DumpProperties()

				if propeties.m_bChargeRelease == 0 then
					local numbChargeToAdd = clamp(damageInfo.Damage / (NUMB_CHARGE_RATIO * 100), 0, 1)

					data.Charge = clamp(propeties.m_flChargeLevel + numbChargeToAdd, 0, 1)
					medigun:AcceptInput("$SetProp$m_flChargeLevel", data.Charge)
				else 
					--deflect n heal
					local deflectDmgInfo = {
						Attacker = activator, 
						Inflictor = nil, 
						Weapon = medigun,
						Damage = damageInfo.Damage * 5,
						DamageType = 0, 
						DamageCustom = 0, 
						DamagePosition = Vector(0, 0, 0), 
						DamageForce = Vector(0, 0, 0),
						ReportedPosition = Vector(0, 0, 0) 
					}

					damageInfo.Attacker:TakeDamage(deflectDmgInfo)
					caller:AddHealth(damageInfo.Damage / 2, true)
				end
			end
		)
	}

	data.ChargeApplyTimerID =
		timer.Create(
		0.05,
		function()
			local propeties = medigun:DumpProperties()

			if propeties.m_bChargeRelease == 0 then
				-- activator:AcceptInput("$SetVar$numbCharge", math.floor(data.Charge * 100))
				-- applier:FireUser5(_, activator)
			else
				--ubercharging effects
				data.Charge = propeties.m_flChargeLevel
				activator:AddCond(20, 0.1)
				activator:AddCond(36, 0.1)
			end
		end,
		0
	)
end

--for debugging
-- function forceSetNumbCharge(charge, activator)
-- 	print(charge)
-- 	local handle = activator:GetHandleIndex()

-- 	comfortablyNumbUsers[handle].Charge = charge
-- end

function comfortablyNumbUnspawn(_, activator)
	local handle = activator:GetHandleIndex()

	local data = comfortablyNumbUsers[handle]

	timer.Stop(data.ChargeApplyTimerID)

	for _, callbackData in pairs(data.Callbacks) do
		activator:RemoveCallback(callbackData.Type, callbackData.ID)
	end

	comfortablyNumbUsers[handle] = nil
end

function dealDamageToActivator(damage, activator, caller)
	if activator == caller then
		return
	end

	local damageInfo = {
		Attacker = caller, -- Attacker
		Inflictor = nil, -- Direct cause of damage, usually a projectile
		Weapon = nil,
		Damage = damage,
		DamageType = 0, -- Damage type, see DMG_* globals. Can be combined with | operator
		DamageCustom = 0, -- Custom damage type, see TF_DMG_* globals
		DamagePosition = Vector(0, 0, 0), -- Where the target was hit at
		DamageForce = Vector(0, 0, 0), -- Knockback force of the attack
		ReportedPosition = Vector(0, 0, 0) -- Where the attacker attacked from
	}

	local dmg = activator:TakeDamage(damageInfo)
	--print("damage dealt "..dmg)
end

function healCaller(amount, _, caller)
	caller:AddHealth(amount, true)
end

function helicopterAscend(units, _, caller)
	local iterated = 0

	for i = 0, units, units / 20 do
		timer.Simple(
			0.02 * iterated,
			function()
				caller:FireUser6(i)
			end
		)

		iterated = iterated + 1
	end
end

local LEVELS_INFO = {
	[1] = {
		Damage = 6,
		Cooldown = 0.05
	},
	[2] = {
		Damage = 8,
		Cooldown = 0.05
	}
}

local registeredShields = {} --value is debounce players

function _register(shieldEnt, level, ownerTeamnum, activator)
	local handle = shieldEnt:GetHandleIndex()

	registeredShields[handle] = {}

	shieldEnt:AddCallback(
		ON_REMOVE,
		function()
			registeredShields[handle] = nil
		end
	)

	local levelInfo = LEVELS_INFO[level]

	shieldEnt:AddCallback(
		ON_TOUCH,
		function(_, target, hitPos)
			if not target or not target:IsPlayer() then
				return
			end

			local visualHitPos = hitPos + Vector(0, 0, 50)

			local targetHandle = target:GetHandleIndex()

			local nextAllowedDamageTickOnTarget = registeredShields[handle][targetHandle] or -1

			if CurTime() < nextAllowedDamageTickOnTarget then
				return
			end

			local targetTeamnum = target.m_iTeamNum

			if targetTeamnum == ownerTeamnum then
				return
			end

			local damageInfo = {
				Attacker = activator,
				Inflictor = nil,
				Weapon = nil,
				Damage = levelInfo.Damage,
				DamageType = DMG_SHOCK,
				DamageCustom = 0,
				DamagePosition = visualHitPos,
				DamageForce = Vector(0, 0, 0),
				ReportedPosition = visualHitPos
			}

			local dmg = target:TakeDamage(damageInfo)

			registeredShields[handle][targetHandle] = CurTime() + levelInfo.Cooldown

			-- print("damage dealt " .. dmg)
		end
	)
end

function registerShieldThunderdome(shieldEntName, activator)
	local shieldEnt = ents.FindByName(shieldEntName)

	local ownerTeamnum = activator.m_iTeamNum

	_register(shieldEnt, 1, ownerTeamnum, activator)
end

function registerShieldDoppler(shieldEntName, activator)
	local shieldEnt = ents.FindByName(shieldEntName)

	local ownerTeamnum = activator.m_iTeamNum

	_register(shieldEnt, 2, ownerTeamnum, activator)
end
