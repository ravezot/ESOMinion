ai_unstuck = {}
ai_unstuck.stucktimer = 0
ai_unstuck.stuckcounter = 0
ai_unstuck.idletimer = 0
ai_unstuck.idlecounter = 0
ai_unstuck.respawntimer = 0
ai_unstuck.ismoving = false
ai_unstuck.lastpos = nil
ai_unstuck.Obstacles = {}
ai_unstuck.AvoidanceAreas = {}

function ai_unstuck:OnUpdate( tick )
	
	if ( Player.alive == false) then 
		ai_unstuck.Reset()
		return
	end
	
	
	if 	(ai_unstuck.lastpos == nil) or (ai_unstuck.lastpos and type(ai_unstuck.lastpos) ~= "table") then
		ai_unstuck.lastpos = Player.pos
		return	
	end
	
	if ( gBotMode == GetString("assistMode") ) then return end
	
	
	-- Stuck check for movement stucks
	if ( Player:IsMoving()) then
		local movedirs = Player:GetMovement()
		if ( not movedirs.backward and tick - ai_unstuck.stucktimer > 500 ) then
			ai_unstuck.stucktimer = tick
			local pPos = Player.pos
			if ( pPos ) then
				--d(Distance3D ( pPos.x, pPos.y, pPos.z, ai_unstuck.lastpos.x,  ai_unstuck.lastpos.y, ai_unstuck.lastpos.z))		
				local bcheck = Distance3D ( pPos.x, pPos.y, pPos.z, ai_unstuck.lastpos.x,  ai_unstuck.lastpos.y, ai_unstuck.lastpos.z) < 2.50 --4.1 normal by foot
				if ( Player.stealthstate ~= 0 ) then
					bcheck = Distance3D ( pPos.x, pPos.y, pPos.z, ai_unstuck.lastpos.x,  ai_unstuck.lastpos.y, ai_unstuck.lastpos.z) < 1.75 --2.4 crouched
				end
				
				if ( bcheck ) then					
					if ( ai_unstuck.stuckcounter > 1 ) then
						d("Seems we are stuck?")
						--if ( Player:CanMove() ) then
							Player:Jump()
						--end
					end
					if ( ai_unstuck.stuckcounter > 8 ) then
						ai_unstuck.HandleStuck()
					end
					ai_unstuck.stuckcounter = ai_unstuck.stuckcounter + 1
				else
					ai_unstuck.stuckcounter = 0
					if ( ai_unstuck.ismoving == true ) then
						Player:Stop()						
						ai_unstuck.ismoving = false
					end
				end
				ai_unstuck.lastpos = Player.pos
			end
		end
	else
		ai_unstuck.stuckcounter = 0
				
		
		-- Idle stuck check	
		if ( tick - ai_unstuck.idletimer > 6000 ) then
			ai_unstuck.idletimer = tick
			--if ( not Player:IsConversationOpen() and not Inventory:IsVendorOpened() ) then
				local pPos = Player.pos
				
				if ( pPos ) then				
					if ( Distance2D ( pPos.x, pPos.y, ai_unstuck.lastpos.x,  ai_unstuck.lastpos.y) < 0.85 ) then
						ai_unstuck.idlecounter = ai_unstuck.idlecounter + 1
						if ( ai_unstuck.idlecounter > 10 ) then -- 60 seconds of doing nothing
							d("Our bot seems to be doing nothing anymore...")
							ai_unstuck.idlecounter = 0
							ai_unstuck.HandleStuck()							
						end
					else
						ai_unstuck.idlecounter = 0
						ai_unstuck.logoutTmr = 0
					end
				end
				ai_unstuck.lastpos = Player.pos
			--end
		end
	end	
end

function ai_unstuck.HandleStuck()	
	d("TODO: Handle stuck")
	-- Setting an avoidancearea at this point to hopefully find a way around it
	local pPos = Player.pos
	if ( pPos ) then
		table.insert(ai_unstuck.AvoidanceAreas, { x=pPos.x, y=pPos.y, z=pPos.z, r=2 })
		d("adding AvoidanceArea with size "..tostring(2))
		NavigationManager:SetAvoidanceAreas(ai_unstuck.AvoidanceAreas)
	end
	Player.Stop() -- force recreation of path
	
	ai_unstuck.stuckcounter = 0	
end

function ai_unstuck.stuckhandler( event, distmoved, stuckcount )
	
	if ( Player.alive == false) then 
		ai_unstuck.Reset()
		return
	end
	
	d("STUCK! Distance Moved: "..tostring(distmoved) .. " Count: "..tostring(stuckcount) )
		
	if ( tonumber(stuckcount) < 10 ) then
		Player:Jump()
				
		local i = math.random(0,1)
		if ( i == 0 ) then
			--Player:SetMovement(2)
			ai_unstuck.ismoving = true
		elseif ( i == 1 ) then
			--Player:SetMovement(3)
			ai_unstuck.ismoving = true
		end
	end
	
	if ( tonumber(stuckcount) > 20 ) then
		ml_error("We are STUCK!")
		ai_unstuck.HandleStuck()
	end
end

function ai_unstuck.Reset()
	ai_unstuck.stucktimer = 0
	ai_unstuck.stuckcounter = 0
	ai_unstuck.idletimer = 0
	ai_unstuck.idlecounter = 0
	ai_unstuck.respawntimer = 0
	ai_unstuck.ismoving = false
	ai_unstuck.lastpos = nil
	ai_unstuck.logoutTmr = 0
end

RegisterEventHandler("Gameloop.Stuck",ai_unstuck.stuckhandler) -- gets called by c++ when using the navigationsystem
