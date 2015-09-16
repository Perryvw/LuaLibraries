--[[
	MotionControllers library.

	Basically does what we expect from valve motion controllers but don't get.

	By: Perry
	Date: September, 2015

	The rules are simple:
	-If there are multiple motion controller modifiers on one unit, the modifier with the highest priority is applied,
	 the rest IS NOT.
	-If there are multiple modifiers with the highest priority, the modifier applied last overrules the others.

	Interface:
	----------------------------------------------------------------------------------------------------------------------
	MotionControllers:Register( modifier, priority )
		Register a modifier as a motion controller with some priority. Call this in the modifier's OnCreated(..).

		Params:
			* modifier - The modifier to register as motion controller, usually 'self' in OnCreated(..).
			* priority - The priority of the motion controller, possible values are:
				- DOTA_MOTION_CONTROLLER_PRIORITY_LOWEST
				- DOTA_MOTION_CONTROLLER_PRIORITY_LOW
				- DOTA_MOTION_CONTROLLER_PRIORITY_MEDIUM
				- DOTA_MOTION_CONTROLLER_PRIORITY_HIGH
				- DOTA_MOTION_CONTROLLER_PRIORITY_HIGHEST
	----------------------------------------------------------------------------------------------------------------------
	modifier:DoMotion( motionFunction )
		Motion controllers should call this everytime they are trying to apply some motion. Internally validates if the 
		motion controller is applied or not. Will execute the motionFunction if the motion controller is applied, therefore
		should contain all the motion code for the modifier.

		Params:
			* motionFunction - The function to execute or not depending on if the motion controller has priority over the others.
								Typically this function contains a SetAbsOrigin.
	----------------------------------------------------------------------------------------------------------------------
	MotionControllers:NonModifierMotion( priority, unit, motionFunction )
		Perform a motion with some priority on a unit without using any modifier.

		Params:
			* priority - The priority of the motion controller, possible values are:
				- DOTA_MOTION_CONTROLLER_PRIORITY_LOWEST
				- DOTA_MOTION_CONTROLLER_PRIORITY_LOW
				- DOTA_MOTION_CONTROLLER_PRIORITY_MEDIUM
				- DOTA_MOTION_CONTROLLER_PRIORITY_HIGH
				- DOTA_MOTION_CONTROLLER_PRIORITY_HIGHEST
			* unit - The unit the motion is applied to.
			* motionFunction - The function to execute or not depending on if the motion has priority over other motion controllers.
								Typically this function contains a SetAbsOrigin.
	----------------------------------------------------------------------------------------------------------------------
]]
MotionControllers = class({})

--Register a modifier as a motion controller with soem priority
function MotionControllers:Register( modifier, priority )
	modifier.MotionControllers = {
		priority = priority,
		creation_time = GameRules:GetGameTime()
	}

	function modifier:DoMotion( motion )
		MotionControllers:ValidateMotion( modifier, motion )
	end
end

--Validate a motioncontroller. Decides whether the motion controller is applied or not.
function MotionControllers:ValidateMotion( modifier, motion )
	--Get modifier info
	local parent = modifier:GetParent()
	local priority = modifier.MotionControllers.priority
	local creation_time = modifier.MotionControllers.creation_time

	--Assume this motioncontroller is not blocked for now
	local blocked = false

	--Loop over all modifiers on the unit
	local modifiers = parent:FindAllModifiers()
	for _, m in pairs( modifiers ) do
		--Only check other motion controllers
		if m.MotionControllers ~= nil and m ~= modifier then
			--Check if the priority of the other motion controller outranks this one
			if m.MotionControllers.priority > priority then
				blocked = true
				break
			end

			--If the priorities are equal, check which motion controller was applied last
			if m.MotionControllers.priority == priority and m.MotionControllers.creation_time > creation_time then
				blocked = true
				break
			end
		end
	end

	--Execute the motion function if it didn't get blocked by another motion controller
	if not blocked then
		motion()
	end
end

--Validate a motion not attached to a motion controller
function MotionControllers:NonModifierMotion( priority, unit, motion )
	--Assume this motioncontroller is not blocked for now
	local blocked = false

	--Loop over all modifiers on the unit
	local modifiers = unit:FindAllModifiers()
	for _, m in pairs( modifiers ) do
		--Only check other motion controllers
		if m.MotionControllers ~= nil then
			--Check if the priority of the other motion controller outranks this one
			if m.MotionControllers.priority > priority then
				blocked = true
				break
			end
		end
	end

	--Execute the motion function if it didn't get blocked by another motion controller
	if not blocked then
		motion()
	end
end
