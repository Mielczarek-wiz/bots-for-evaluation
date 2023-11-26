ramboMaxHealth = 1000;
ramboHealth = 1000;
ramboPosition = Vector4d(0,0,0,0);
ramboGoFor = 9999;
xmap = 800;
ymap = 800;

function mielczarek_ramboonStart( agent, actorKnowledge, time)
    agent:selectWeapon(Enumerations.RocketLuncher);
    ramboHealth = actorKnowledge:getHealth();
    ramboMaxHealth = ramboHealth;
    ramboPosition = actorKnowledge:getPosition();

end

function mielczarek_rambowhatTo( agent, actorKnowledge, time)
        ramboHealth = actorKnowledge:getHealth();
        ramboPosition = actorKnowledge:getPosition();
        enemies = actorKnowledge:getSeenFoes();
        if (actorKnowledge:isMoving() == false) then
                agent:moveTo(Vector4d(agent:randomDouble()*xmap, agent:randomDouble()*ymap, 0,0));
                findNearestTriggerRambo(agent, actorKnowledge, false);
        end

        helpMeRambo(agent, actorKnowledge);

        changeWeaponRambo(agent, actorKnowledge, enemies);

        findSmthRambo(agent, actorKnowledge);

        notFriendlyFireShootRambo(agent, enemies);
end

--[[  
        Find nearest trigger and take it. 
--]]
function findNearestTriggerRambo(agent, actorKnowledge, onlyHelp)
        nearest = 9999;
        nav = actorKnowledge:getNavigation();
        for i=0, nav:getNumberOfTriggers() -1, 1 do
                trig = nav:getTrigger(i);
                dist = trig:getPosition() - ramboPosition;

                if (onlyHelp == true) then
                        if(dist:length() < nearest and trig:isActive() and (trig:getType() == Trigger.Health or trig:getType() == Trigger.Armour) and sniperGoFor ~= i and guardianGoFor ~= i) then
                                nearest = i;
                        end
                else
                        if(dist:length() < nearest and trig:isActive() and sniperGoFor ~= i and guardianGoFor ~= i) then
                                nearest = i;
                        end
                end

        end
        if (nearest < 9999 and sniperGoFor ~= nearest and guardianGoFor ~= nearest) then
                ramboGoFor = nearest
                agent:moveTo(nav:getTrigger(nearest):getPosition());
        end
   
end

--[[  
    If our Rambo has health under 60%, so we are searching for triggers that give him Armour or Health to protect.
--]]
function helpMeRambo(agent, actorKnowledge)
        if(ramboHealth < ramboMaxHealth*0.6) then
            findNearestTriggerRambo(agent, actorKnowledge, true);
        end
end

--[[  
    Code for changing Weapon.
--]]
function changeWeaponRambo(agent, actorKnowledge, enemies)
        if (enemies:size() > 0) then
                distanceBetweenEnemy = (ramboPosition - findNearestEnemyRambo(enemies):getPosition()):length();
                --[[  
                        If distance between two Foes are lower then 40 we choose RocketLuncher to shoot. 
                --]]
                if ((enemies:size() > 1) ) then
                        for i=0, enemies:size()-2, 1 do
                                for j=i+1, enemies:size()-1, 1 do 
                                        dir = enemies:at(i):getPosition() - enemies:at(j):getPosition();
                                        if((dir:length() < 40) and (actorKnowledge:getAmmo(Enumerations.RocketLuncher) ~= 0) and ((ramboPosition - enemies:at(j):getPosition()):length() > 100) ) then
                                                agent:selectWeapon(Enumerations.RocketLuncher);
                                        end;
                                end;
                        end;
                --[[  
                        If distance between enemy and Rambo are higher then 100 we choose RocketLuncher to shoot. 
                --]]
                elseif ((distanceBetweenEnemy >= 100) and actorKnowledge:getAmmo(Enumerations.RocketLuncher) ~= 0) then
                        agent:selectWeapon(Enumerations.RocketLuncher);
                --[[  
                        If distance between enemy and Rambo are between 50 and 100 we choose Railgun to shoot. 
                --]]
                elseif ((distanceBetweenEnemy >= 50 and distanceBetweenEnemy < 100) and actorKnowledge:getAmmo(Enumerations.Railgun) ~= 0) then
                        agent:selectWeapon(Enumerations.Railgun);
                --[[  
                        If distance between enemy and Rambo are lower then 50 we choose Shotgun to shoot. 
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
        Rambo must go and find some trigger because he will dead. 
--]]
function findSmthRambo(agent, actorKnowledge)
        if(actorKnowledge:getAmmo(Enumerations.RocketLuncher)==0 
                and actorKnowledge:getAmmo(Enumerations.Railgun) == 0 
                and actorKnowledge:getAmmo(Enumerations.Shotgun) == 0 
                and actorKnowledge:getAmmo(Enumerations.Chaingun) == 0) then
                
                findNearestTriggerRambo(agent, actorKnowledge, false);
        end
end;

--[[  
        Shoot but not in your friend. 
--]]
function notFriendlyFireShootRambo(agent, enemies)
        sniperDir = (sniperPosition - guardianPosition):normalize();
        guardianDir = (guardianPosition - sniperPosition):normalize();
        if (enemies:size() > 0) then
                nearestEnemy = findNearestEnemyRambo(enemies)
                enemyDir = (nearestEnemy:getPosition() - guardianPosition):normalize();
                skalarSniper = sniperDir:dot(enemyDir);
                angleSniper= math.deg(math.acos(skalarSniper));
                skalarGuardian = guardianDir:dot(enemyDir);
                angleGuardian = math.deg(math.acos(skalarGuardian));
                if(angleSniper > 30 and angleGuardian > 30) then
                        shootingLogicRambo(agent, nearestEnemy);
                end;
        end;
end;

--[[  
        Logic for Rambo shooting. 
--]]
function shootingLogicRambo(agent, enemy)
        dir = enemy:getPosition() - ramboPosition;
        if(enemy:getHealth() > (ramboMaxHealth * 0.5) and ramboHealth < (ramboMaxHealth * 0.6)) then
                agent:moveDirection(dir * (-1));
                if(dir:length() < 100) then
                        agent:moveTo(Vector4d(agent:randomDouble()*xmap, agent:randomDouble()*ymap, 0,0));
                end;
        elseif(enemy:getHealth() < ramboHealth) then
                agent:moveTo(enemy:getPosition());
        end;
        agent:shootAtPoint(enemy:getPosition());
end;

--[[  
        Find nearest enemy for Rambo. 
--]]
function findNearestEnemyRambo(enemies)
        nearest = 9999
        for i=0, enemies:size() -1, 1 do
                dir = enemies:at(i):getPosition() - ramboPosition;
                if(dir:length() < nearest) then
                        nearest = i
                end;
        end;
        return enemies:at(nearest);
end;