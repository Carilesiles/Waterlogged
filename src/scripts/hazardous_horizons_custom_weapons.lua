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