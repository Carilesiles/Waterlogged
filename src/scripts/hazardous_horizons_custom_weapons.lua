local CLASS_ROBOT_MODELS = {
	[1] = "models/bots/scout/bot_scout.mdl",
	[2] = "models/bots/sniper/bot_sniper.mdl",
	[3] = "models/bots/soldier/bot_soldier.mdl",
	[4] = "models/bots/demo/bot_demo.mdl",
	[5] = "models/bots/medic/bot_medic.mdl",
	[6] = "models/bots/heavy/bot_heavy.mdl",
	[7] = "models/bots/pyro/bot_pyro.mdl",
	[8] = "models/bots/spy/bot_spy.mdl",
	[9] = "models/bots/engineer/bot_engineer.mdl",
}

function ApplyPlayerRobotModel(_, activator)
	local class = activator.m_iClass

	local robotModel = CLASS_ROBOT_MODELS[class]

	if not robotModel then
		return
	end

	activator:SetCustomModelWithClassAnimations(robotModel)
end

function DronePlaced(_, originalBuilding)
	print(originalBuilding)
	if originalBuilding.m_bDisposableBuilding ~= 0 then
		return
	end

	local owner = originalBuilding.m_hBuilder

	if not owner then
		return
	end

	local origin = originalBuilding:GetAbsOrigin()

	local sentry = ents.CreateWithKeys("obj_sentrygun", {
		defaultupgrade = 0,
		team = owner.m_iTeamNum,
		SolidToPlayer = 0,
	}, true)

	originalBuilding:Remove()

	sentry:SetBuilder(owner, owner, owner)
	sentry.m_bMiniBuilding = 1
	sentry.m_iAmmoShells = 99999
	sentry.m_nSolidType = 0
	sentry:SetModelOverride("models/rcat/rcat_level2.mdl")
	sentry["m_nSkin"] = 1


	sentry["$fakeparentoffset"] = Vector(40, -50, 80)
	sentry:SetFakeParent(owner)
end