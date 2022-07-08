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
        DamagePosition = Vector(0,0,0), -- Where the target was hit at
        DamageForce = Vector(0,0,0), -- Knockback force of the attack
        ReportedPosition = Vector(0,0,0) -- Where the attacker attacked from
    }
    
    local dmg = activator:TakeDamage(damageInfo)
    --print("damage dealt "..dmg)
end

function healCaller(amount, _, caller)
    caller:AddHealth(amount, true)
end