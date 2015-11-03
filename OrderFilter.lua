--[[
	Overwrite the existing order filter to allows multiple order filters using the default API.

	It is important to require this file from or after Activate function in addon_game_mode.lua
	is called, otherwise GameRules:GetGameModeEntity will return nil.

	Example usage:
	--Filter 1
	GameRules:GetGameModeEntity():SetExecuteOrderFilter( function( self, order )
		print('Filter 1')
		return true
	end, ORDER_FILTER_PRIORITY_LOW )

	--Filter 2
	GameRules:GetGameModeEntity():SetExecuteOrderFilter( function( self, order )
		print('Filter 2')
		return true
	end )

	--Filter 3
	GameRules:GetGameModeEntity():SetExecuteOrderFilter( DynamicWrap( MyGameMode, 'OrderFilter' ), self )

	--Output For each order:
	Filter 2
	Filter 3
	Filter 1
]]
if orderFilterOverwritten == nil then
	orderFilterOverwritten = true

	ORDER_FILTER_PRIORITY_LOWEST = 0
	ORDER_FILTER_PRIORITY_LOW = 1
	ORDER_FILTER_PRIORITY_NORMAL = 2
	ORDER_FILTER_PRIORITY_HIGH = 3
	ORDER_FILTER_PRIORITY_HIGHEST = 4

	--Save a list of different functions
	orderFilters = {}

	--Set the actual order filter to the function that just iterates over all filters
	GameRules:GetGameModeEntity():SetExecuteOrderFilter( function( self, order )
		for _,filter in ipairs( orderFilters ) do
			if filter.func( filter.context, order ) ~= true then
				return false
			end
		end

		return true
	end, {} )

	--Overwrite the original function
	GameRules:GetGameModeEntity().SetExecuteOrderFilter = function( self, filterFunc, context, priority )
		if type( context ) == 'number' then
			priority = context
			context = self
		end

		--Set default priority if it's not set
		if priority == nil then
			priority = ORDER_FILTER_PRIORITY_NORMAL
		end

		table.insert( orderFilters, {func = filterFunc, priority = priority, context = context } )

		--Sort table based on priorities
		table.sort( orderFilters, function( a, b ) return a.priority - b.priority end )
	end
end

