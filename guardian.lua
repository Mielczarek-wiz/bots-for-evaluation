guardianMaxHealth = 1000;
guardianHealth = 1000;
guardianPosition = Vector4d(0,0,0,0);
guardianGoFor = 9999;
xmap = 800;
ymap = 800;
function mielczarek_guardianonStart( agent, actorKnowledge, time)
        agent:selectWeapon(Enumerations.Shotgun);
        guardianHealth = actorKnowledge:getHealth();
        guardianMaxHealth = guardianHealth;
        guardianPosition = actorKnowledge:getPosition();

end;

function mielczarek_guardianwhatTo( agent, actorKnowledge, time)
        guardianHealth = actorKnowledge:getHealth();
        guardianPosition = actorKnowledge:getPosition();
        enemies = actorKnowledge:getSeenFoes();

        if (actorKnowledge:isMoving() == false) then
                agent:moveTo(Vector4d(agent:randomDouble()*xmap, agent:randomDouble()*ymap, 0,0));
                findNearestTriggerGuardian(agent, actorKnowledge, false);

        end;

        helpMeGuardian(agent, actorKnowledge);

        changeWeaponGuardian(agent, actorKnowledge, enemies);

        findSmthGuardian(agent, actorKnowledge);

        notFriendlyFireShootGuardian(agent, enemies);
end;
--[[  
        Find nearest trigger and take it. 
--]]
function findNearestTriggerGuardian(agent, actorKnowledge, onlyHelp)
        nearest = 9999;
        nav = actorKnowledge:getNavigation();
        for i=0, nav:getNumberOfTriggers() -1, 1 do
                trig = nav:getTrigger(i);
                dist = trig:getPosition() - guardianPosition;

                if (onlyHelp == true) then
                        if(dist:length() < nearest and trig:isActive() and (trig:getType() == Trigger.Health or trig:getType() == Trigger.Armour) and ramboGoFor ~= i and sniperGoFor ~= i) then
                                nearest = i;
                        end;
                else
                        if(dist:length() < nearest and trig:isActive() and ramboGoFor ~= i and sniperGoFor ~= i) then
                                nearest = i;
                        end;
                end;
        end;
        if (nearest < 9999 and ramboGoFor ~= nearest and sniperGoFor ~= nearest) then
                guardianGoFor = nearest
                agent:moveTo(nav:getTrigger(nearest):getPosition());
        end;
end;

--[[  
    If our Guardian has health under 65%, so we are searching for triggers that give him Armour or Health to protect.
--]]
function helpMeGuardian(agent, actorKnowledge)
    if(guardianHealth < guardianMaxHealth*0.65) then
        findNearestTriggerGuardian(agent, actorKnowledge, true);
    end;
end;
--[[  
    Code for changing Weapon. 
--]]
function changeWeaponGuardian(agent, actorKnowledge, enemies)
        if (enemies:size() > 0) then
                distanceBetweenEnemy = (guardianPosition - findNearestEnemyRambo(enemies):getPosition()):length();
                --[[  
                        If distance between two Foes are lower then 40 we choose RocketLuncher to shoot. 
                --]]
                if ((enemies:size() > 1) ) then
                        for i=0, enemies:size()-2, 1 do
                                for j=i+1, enemies:size()-1, 1 do
                                        dir = enemies:at(i):getPosition() - enemies:at(j):getPosition();
                                        if((dir:length() < 40) and (actorKnowledge:getAmmo(Enumerations.RocketLuncher) ~= 0) and ((guardianPosition - enemies:at(j):getPosition()):length() > 100) ) then
                                                agent:selectWeapon(Enumerations.RocketLuncher);
                                        end;
                                end;
                        end;
                --[[  
                        If distance between enemy and Guardian are higher then 100 we choose RocketLuncher to shoot. 
                --]]
                elseif ((distanceBetweenEnemy >= 100) and actorKnowledge:getAmmo(Enumerations.RocketLuncher) ~= 0) then
                        agent:selectWeapon(Enumerations.RocketLuncher);
                --[[  
                        If distance between enemy and Guardian are between 50 and 100 we choose Railgun to shoot. 
                --]]
                elseif ((distanceBetweenEnemy >= 50 and distanceBetweenEnemy < 100) and actorKnowledge:getAmmo(Enumerations.Railgun) ~= 0) then
                        agent:selectWeapon(Enumerations.Railgun);
                --[[  
                        If distance between enemy and Guardian are lower then 50 we choose Shotgun to shoot. 
                --]]
                elseif ((distanceBetweenEnemy < 50) and actorKnowledge:getAmmo(Enumerations.Shotgun) ~= 0) then
                        agent:selectWeapon(Enumerations.Shotgun);
                --[[  
                        Else change to Chaingun to shoot. 
                --]]
                elseif (actorKnowledge:getAmmo(Enumerations.Chaingun) ~= 0) then
                        agent:selectWeapon(Enumerations.Chaingun);
                end;
        end;

end;
--[[  
        Guardian must go and find some trigger because he will dead. 
--]]
function findSmthGuardian(agent, actorKnowledge)
        if(actorKnowledge:getAmmo(Enumerations.RocketLuncher)==0
                and actorKnowledge:getAmmo(Enumerations.Railgun) == 0
                and actorKnowledge:getAmmo(Enumerations.Shotgun) == 0
                and actorKnowledge:getAmmo(Enumerations.Chaingun) == 0) then
                
                findNearestTriggerGuardian(agent, actorKnowledge, false);
        end;
end;

--[[  
        Shoot but not in your friend. 
--]]
function notFriendlyFireShootGuardian(agent, enemies)
        sniperDir = (sniperPosition - guardianPosition):normalize();
        ramboDir = (ramboPosition - sniperPosition):normalize();
        if (enemies:size() > 0) then
                nearestEnemy = findNearestEnemyGuardian(enemies);
                enemyDir = (nearestEnemy:getPosition() - guardianPosition):normalize();
                skalarSniper = sniperDir:dot(enemyDir);
                angleSniper= math.deg(math.acos(skalarSniper));
                skalarRambo = ramboDir:dot(enemyDir);
                angleRambo = math.deg(math.acos(skalarRambo));
                if(angleSniper > 30 and angleRambo > 30) then
                        shootingLogicGuardian(agent, nearestEnemy);
                end;
        end;
end;

--[[  
        Logic for Guardian shooting. 
--]]
function shootingLogicGuardian(agent, enemy)
        dir = enemy:getPosition() - guardianPosition;
        if((enemy:getHealth() > guardianMaxHealth * 0.75)) then
                agent:moveDirection(dir * (-1));
                if(dir:length() < 100) then
                        agent:moveTo(Vector4d(agent:randomDouble()*xmap, agent:randomDouble()*ymap, 0,0));
                end;
        end;
        agent:shootAtPoint(enemy:getPosition());
end;

--[[  
        Find nearest enemy for Guardian. 
--]]
function findNearestEnemyGuardian(enemies)
        nearest = 9999
        for i=0, enemies:size() -1, 1 do
                dir = enemies:at(i):getPosition() - guardianPosition;
                if(dir:length() < nearest) then
                        nearest = i
                end;
        end;
        return enemies:at(nearest);
end;