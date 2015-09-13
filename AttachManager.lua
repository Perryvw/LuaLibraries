--[[
	AttachManager library.
	This class manages the attachment of models to a model's attach points, allowing devs to attach 
	any model to any model attach points.

	By: Perry
	Date: September, 2015

	Interface:
	---------------------------------------------------------------------------------------------------------------------------
	AttachManager:DrawAxes( unit, attachment, duration, scale )
		Draw an axis system at a unit's attachment with a scale. Automatically disappears after some duration.

		Params:
			* unit - The unit to attach the axes to.
			* attachment - The attachment to follow.
			* duration - The duration after which the axis system will disappear again.
			* scale - The scale of the axes
	---------------------------------------------------------------------------------------------------------------------------
	AttachManager:AddModel( modelName[, initialOffset, initialDirection ])
		Add a model to the AttachManager's model library. 
		This step is REQUIRED if you want to use this model for attachments.

		Params:
			* modelName - The path of the model.
			* initialOffset - (Optional) The offset a model has to its own origin (can be estimated with model editor). 
				Default: Vector( 0, 0, 0 )
			* initialOffset - (Optional) The direction a model has to its own origin (can be estimated with model editor). 
				Default: Vector( 1, 0 ,0 )
	---------------------------------------------------------------------------------------------------------------------------
	AttachManager:AttachModel( unit, modelName, parent[, offset, direction, scale ])
		Create an attachment for some unit.

		Params:
			* unit - The unit to attach to.
			* modelname - The name of the model. Has to be added usnig AttachManager:AddModel(..)
			* parent - The name of the attachment to attach to, e.g. 'attach_hitloc' or 'attach_attack1'
			* offset - (Optional) The offset of the attachment relative to its parent.
				Default: Vector( 0, 0, 0 )
			* direction - (Optional)The direction of the attachment relative to its parent.
				Default: Vector( 1, 0, 0 )
			* scale - (Optional) The scale of the attachment model.
				Default: 1
			* animation - (Optional) The animation of the model.
				Default: ''

		Returns: The attachment entity that was created.
	---------------------------------------------------------------------------------------------------------------------------
	AttachManager:ChangeModel( entity, modelName[, scale ])
		Change the model or scale of an attachment entity created with AttachManager:AttachModel(..)

		Params:
		* entity - The attachment entity to change the model of. Has to be made using AttachManager:AttachModel(..)
		* modelName - The new modelName for the attachment. The model needs to have been added with	AttachManager:AddModel(..)
		* scale - (Optional) The new scale for the model.
			Default: 1
	---------------------------------------------------------------------------------------------------------------------------

	Examples:
	--=========================================================================================================================

	--Add model data to the AttachManager model library at your initialisation:
	AttachManager:AddModel( 'models/items/enchantress/anuxi_summer_spear/anuxi_summer_spear.vmdl' )
	AttachManager:AddModel( 'models/items/huskar/burning_spear/burning_spear.vmdl', Vector( 0, 100, 0 ) )
	AttachManager:AddModel( 'models/items/faceless_void/battlefury/battlefury.vmdl', Vector( 0, -110, 70 ), Vector( 0, 0, 1 ) )

	--=========================================================================================================================

	--Create an attachment with some offset and direction relative to their parent
	local offset = Vector( 50, 0, 0 )
	local direction = Vector( 0, 0, 1 )
	local scale = 2
	local animation = 'bindPose'

	local attachment = AttachManager:AttachModel( unit, 'models/items/enchantress/anuxi_summer_spear/anuxi_summer_spear.vmdl', 
		'attach_attack1', offset, direction, scale, animation )

	--=========================================================================================================================

	--Change the model/scale of an existing attachment maintaining its position/direction
	local newScale = 4
	AttachManager:ChangeModel( attachment, 'models/items/faceless_void/battlefury/battlefury.vmdl', newScale )

	--=========================================================================================================================

]]

--Class definition
if AttachManager == nil then
	AttachManager = class({})
	AttachManager.models = {}
end

--Draw an axis system at a unit's attach point
function AttachManager:DrawAxes( unit, attachment, duration, scale )
	--Get start time
	local timerStart = GameRules:GetGameTime()

	--Repeat every frame
	Timers:CreateTimer( function()
		local axisLength = scale or 50
		local attach = unit:ScriptLookupAttachment( attachment )
		local attachPos = unit:GetAttachmentOrigin( attach )
		local attachRot = unit:GetAttachmentAngles( attach )
		local attachQA = QAngle( attachRot.x, attachRot.y, attachRot.z )

		--Calculate orientation
		local xAxis = RotatePosition( Vector( 0, 0, 0 ), RotationDelta( QAngle( 0, 0, 0 ), attachQA ) , Vector( axisLength, 0, 0 ) )
		local yAxis = RotatePosition( Vector( 0, 0, 0 ), RotationDelta( QAngle( 0, 90, 0 ), attachQA ) , Vector( -axisLength, 0, 0 ) )
		local zAxis = RotatePosition( Vector( 0, 0, 0 ), RotationDelta( QAngle( 270, 0, 0 ), attachQA ) , Vector( -axisLength, 0, 0 ) )

		--Draw the lines
		DebugDrawLine( attachPos, attachPos + xAxis, 255, 0, 0, false, 0.02 )
		DebugDrawLine( attachPos, attachPos + yAxis, 0, 255, 0, false, 0.02 )
		DebugDrawLine( attachPos, attachPos + zAxis, 0, 0, 255, false, 0.02 )

		--Enforce duration
		if GameRules:GetGameTime() - timerStart < duration then
			return 0
		else
			return nil
		end
	end)
end

--Add a model to the AttachManager's mode library
function AttachManager:AddModel( modelName, initialOffset, initialDirection )
	--Handle default values
	local offV = initialOffset or Vector( 0, 0, 0 )
	local dirV = initialDirection or Vector( 1, 0, 0 )

	--Insert in library
	AttachManager.models[modelName] = { offset = Vector( offV.z, offV.y, offV.x ), direction = dirV }
end

--Create an attachment
function AttachManager:AttachModel( unit, modelName, parent, offset, direction, scale, animation )
	--Check if the model is in the model library
	if AttachManager.models[ modelName ] == nil then
		Warning( '[AttachManager] Attachment with model '..modelname..' not found. Use AddModel( model[, initialOffset, initialDirection]) to add it first.' )
		return
	end

	--Animation default
	local animation = animation or ''

	--Create the attachment
	local attachment = SpawnEntityFromTableSynchronous( 'prop_dynamic', {model = modelName, DefaultAnim = animation })

	--Set attachment values
	attachment.unit = unit
	attachment.parent = parent

	attachment.attachOffset = offset or Vector( 0, 0, 0 )
	attachment.attachDirection = direction or Vector( 1, 0, 0 )

	--Set the attachment's model/position/rotation/scale
	AttachManager:ChangeModel( attachment, modelName, scale )

	--Return the created attachment
	return attachment
end

--Change the model/scale of an existing attachment
function AttachManager:ChangeModel( entity, modelName, scale )
	--Check if the model is in the model library
	if AttachManager.models[ modelName ] == nil then
		Warning( '[AttachManager] Attachment with model '..modelname..' not found. Use AddModel( model[, initialOffset, initialDirection]) to add it first.' )
		return
	end

	--Set model
	entity:SetModel( modelName )

	--Set scale
	entity.scale = scale or 1
	entity:SetModelScale( entity.scale )

	--Unparent first to set position/rotation in world coords
	entity:SetParent( nil, '' )

	--Fetch model data
	local modelData = AttachManager.models[ modelName ]

	--Get initial offsets
	local initialOffset = modelData.offset * entity.scale
	local initialDirection = modelData.direction
	local initialRotation = VectorToAngles( initialDirection )

	--Get parent data
	local attach = entity.unit:ScriptLookupAttachment( entity.parent )	
	local attachPos = entity.unit:GetAttachmentOrigin( attach )
	local attachRot = entity.unit:GetAttachmentAngles( attach )
	local attachQA = QAngle( attachRot.x, attachRot.y, attachRot.z )

	--Calculat rotations
	local relativeDir = entity.attachDirection
	local rotationalOffset = VectorToAngles( relativeDir )

	local propRot = initialRotation
	local rotation = RotationDelta( rotationalOffset, QAngle( 0, 0, 0 ) )

	local delta = RotationDelta( rotation , attachQA )

	--Calculate offset from attachment
	local offset = entity.attachOffset
	local correctOffset = RotatePosition( Vector(0, 0, 0), delta, offset )

	--Calculate initial offset
	local offset2 = RotatePosition( Vector(0,0,0), delta, initialOffset )

	--Set origin
	entity:SetAbsOrigin( attachPos - offset2 + correctOffset )

	--Set angles
	local angles = RotationDelta( initialRotation, delta )
	entity:SetAngles( angles.x, angles.y, angles.z )

	--Attach to parent
	entity:SetParent( entity.unit, entity.parent )
end