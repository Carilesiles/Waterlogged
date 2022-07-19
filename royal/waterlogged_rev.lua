-- smol shield replacement
function replaceAllMedigunShields()
	for _, shield in pairs(ents.FindAllByClass("entity_medigun_shield")) do
		local shieldOwner = shield:DumpProperties()["m_hOwnerEntity"]

		if not shieldOwner then
			goto continue
		end

		if shieldOwner:DumpProperties()["shieldReplacementFlag"] ~= 1 then
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

function dealDamageToActivator(damage, activator, caller)
	if activator == caller then
		return
	end

	-- local dump = caller:DumpProperties()
	-- local damage = dump.damageAmount

	-- local damager = ents.FindByName('damager')

	-- print(damager)

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

			local targetHandle = target:GetHandleIndex()

			local nextAllowedDamageTickOnTarget = registeredShields[handle][targetHandle] or -1

			if CurTime() < nextAllowedDamageTickOnTarget then
				return
			end

			local targetTeamnum = target:DumpProperties()["m_iTeamNum"]

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
				DamagePosition = hitPos,
				DamageForce = Vector(0, 0, 0),
				ReportedPosition = hitPos
			}

			local dmg = target:TakeDamage(damageInfo)

			registeredShields[handle][targetHandle] = CurTime() + levelInfo.Cooldown

			-- print("damage dealt " .. dmg)
		end
	)
end

function registerShieldThunderdome(shieldEntName, activator)
	local shieldEnt = ents.FindByName(shieldEntName)

	-- local owner = shieldEnt:DumpProperties()["m_hOwnerEntity"]
	local ownerTeamnum = activator:DumpProperties()["m_iTeamNum"]

	_register(shieldEnt, 1, ownerTeamnum, activator)
end

function registerShieldDoppler(shieldEntName, activator)
	local shieldEnt = ents.FindByName(shieldEntName)

	local ownerTeamnum = activator:DumpProperties()["m_iTeamNum"]

	_register(shieldEnt, 2, ownerTeamnum, activator)
end
