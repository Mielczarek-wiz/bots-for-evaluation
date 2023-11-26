sniperMaxHealth = 9999;
sniperHealth = 9999;
sniperPosition = Vector4d(0,0,0,0);
sniperGoFor = 9999;
xmap = 800;
ymap = 800;

function mielczarek_sniperonStart( agent, actorKnowledge, time)
        agent:selectWeapon(Enumerations.RocketLuncher);
        sniperHealth = actorKnowledge:getHealth();
        sniperMaxHealth = sniperHealth;
        sniperPosition = actorKnowledge:getPosition();
end;

function mielczarek_sniperwhatTo( agent, actorKnowledge, time)
        sniperHealth = actorKnowledge:getHealth();
        sniperPosition = actorKnowledge:getPosition();
        enemies = actorKnowledge:getSeenFoes();

        followGuardian(agent, actorKnowledge);

        helpMeSniper(agent, actorKnowledge);

        changeWeaponSniper(agent, actorKnowledge, enemies);

        findSmthSniper(agent, actorKnowledge);

        notFriendlyFireShootSniper(agent, enemies);


end;
--[[  
        Go after a Guardian or an random position if he is dead already. 
--]]
function followGuardian(agent, actorKnowledge)
        if (actorKnowledge:isMoving()==false) then
                if (guardianHealth == 0 ) then
                        agent:moveTo(Vector4d(agent:randomDouble()*xmap, agent:randomDouble()*ymap, 0,0));
                        findNearestTriggerSniper(agent, actorKnowledge, false);
                else
                        dir = guardianPosition - sniperPosition;
                        if (dir:length() > 50) then
                                agent:moveTo(guardianPosition);
                        end;
                end;
                
        end;
end;

--[[  
        Find nearest trigger and take it. 
--]]
function findNearestTriggerSniper(agent, actorKnowledge, onlyHelp)
        nearest = 9999;
        nav = actorKnowledge:getNavigation()
        for i=0, nav:getNumberOfTriggers() -1, 1 do
                trig = nav:getTrigger(i);
                dist = trig:getPosition() - ramboPosition;

                if (onlyHelp == true) then
                        if(dist:length() < nearest and trig:isActive() and (trig:getType() == Trigger.Health or trig:getType() == Trigger.Armour) and ramboGoFor ~= i and guardianGoFor ~= i) then
                                nearest = i;
                        end;
                else
                        if(dist:length() < nearest and trig:isActive() and ramboGoFor ~= i and guardianGoFor ~= i) then
                                nearest = i;
                        end;
                end;

        end;
        if (nearest < 9999 and ramboGoFor ~= nearest and guardianGoFor ~= nearest) then
                sniperGoFor = nearest;
                agent:moveTo(nav:getTrigger(nearest):getPosition());
        end;
end;

--[[  
    If our Sniper has health under 75%, so we are searching for triggers that give him Armour or Health to protect.
--]]
function helpMeSniper(agent, actorKnowledge)
        if (sniperHealth < sniperMaxHealth * 0.65) then
                findNearestTriggerSniper(agent, actorKnowledge, true);
        end;
end;

--[[  
    Code for changing Weapon. 
--]]
function changeWeaponSniper(agent, actorKnowledge, enemies)
        if (enemies:size() > 0) then
                distanceBetweenEnemy = (sniperPosition - findNearestEnemyRambo(enemies):getPosition()):length();
                --[[  
                        If distance between two Foes are lower then 40 we choose RocketLuncher to shoot. 
                --]]
                if ((enemies:size() > 1) ) then
                        for i=0, enemies:size()-2, 1 do
                                for j=i+1, enemies:size()-1, 1 do 
                                        dist = enemies:at(i):getPosition() - enemies:at(j):getPosition();
                                        if((dist:length() < 40) and (actorKnowledge:getAmmo(Enumerations.RocketLuncher) ~= 0) and ((sniperPosition - enemies:at(j):getPosition()):length() > 100) ) then
                                                agent:selectWeapon(Enumerations.RocketLuncher);
                                        end;
                                end;
                        end;
                --[[  
                        If distance between enemy and Sniper are higher then 100 we choose RocketLuncher to shoot. 
                --]]
                elseif ((distanceBetweenEnemy >= 100) and actorKnowledge:getAmmo(Enumerations.RocketLuncher) ~= 0) then
                        agent:selectWeapon(Enumerations.RocketLuncher);
                --[[  
                        If distance between enemy and Sniper are between 50 and 100 we choose Railgun to shoot. 
                --]]
                elseif ((distanceBetweenEnemy >= 50 and distanceBetweenEnemy < 100) and actorKnowledge:getAmmo(Enumerations.Railgun) ~= 0) then
                        agent:selectWeapon(Enumerations.Railgun);
                --[[  
                        If distance between enemy and Sniper are lower then 50 we choose Shotgun to shoot. 
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
        Sniper must go and find some trigger because he will dead. 
--]]
function findSmthSniper(agent, actorKnowledge)
        if(actorKnowledge:getAmmo(Enumerations.RocketLuncher)==0 
                and actorKnowledge:getAmmo(Enumerations.Railgun) == 0 
                and actorKnowledge:getAmmo(Enumerations.Shotgun) == 0 
                and actorKnowledge:getAmmo(Enumerations.Chaingun) == 0) then
                
                findNearestTriggerSniper(agent, actorKnowledge, false);
        end;
end;

--[[  
        Shoot but not in your friend. 
--]]
function notFriendlyFireShootSniper(agent, enemies)
        guardianDir = (guardianPosition - sniperPosition):normalize();
        ramboDir = (ramboPosition - sniperPosition):normalize();
        if (enemies:size() > 0) then
                nearestEnemy = findNearestEnemySniper(enemies)
                enemyDir = (nearestEnemy:getPosition() - sniperPosition):normalize();
                skalarGuardian = guardianDir:dot(enemyDir);
                angleGuardian = math.deg(math.acos(skalarGuardian));
                skalarRambo = ramboDir:dot(enemyDir);
                angleRambo = math.deg(math.acos(skalarRambo));
                if(angleGuardian > 30 and angleRambo > 30) then
                        agent:shootAtPoint(nearestEnemy:getPosition());
                end;
        end;
end;

--[[  
        Find nearest enemy for Sniper. 
--]]
function findNearestEnemySniper(enemies)
        nearest = 9999
        for i=0, enemies:size() -1, 1 do
                dir = enemies:at(i):getPosition() - sniperPosition;
                if(dir:length() < nearest) then
                        nearest = i
                end;
        end;
        return enemies:at(nearest);
end;
