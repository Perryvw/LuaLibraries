--[[
	This class provides a Pseudo-random RNG, meaning it works with
	a pseudo-random probability distribution instead of a static random chance.
	The benefit of this is that you reduce the randomness in gameplay. If you
	want some more in-depth explanation see:
	http://dota2.gamepedia.com/Pseudo-random_distribution
	
	----HOW TO USE-----
	Create a pseudo-random RNG just call it like this:	
	local rng = PseudoRNG.create( 0.25 ) -- immitates a 25% chance
	
	Then whenever you want to know if something procs, use this:	
	if rng:Next() then
		--proc
	else
		--didn't proc
	end

	Author: Perry
]]
PseudoRNG = {}
PseudoRNG.__index = PseudoRNG

--construct a PseudoRNG for a certain chance (0 - 1; 25% -> 0.25)
function PseudoRNG.create( chance )
   local rng = {}             -- our new object
   setmetatable(rng, PseudoRNG)
   
   rng:Init( perc )
   return rng
end

function PseudoRNG:Init( chance )
	self.failedTries = 0
	--calculate the constant
	self.cons = self:CFromP( chance )
end

function PseudoRNG:CFromP( P )
	local Cupper = P
	local Clower = 0
	local Cmid = 0
	
	local p1 = 0
	local p2 = 1
	
	while true do
		Cmid = (Cupper + Clower) / 2;
		p1 = self:PFromC( Cmid )
		if math.abs(p1 - p2) <= 0 then
			break
		end
		
		if p1 > P then
			Cupper = Cmid
		else
			Clower = Cmid
		end
		
		p2 = p1
	end
	
	return Cmid
end

function PseudoRNG:PFromC( C )
	local pOnN = 0
	local pByN = 0
	local sumPByN = 0
	
	local maxFails = math.ceil( 1/ C )
	
	for N=1,maxFails do
		pOnN = math.min(1, N * C) * (1 - pByN)
		pByN = pByN + pOnN
		sumPByN = sumPByN + N * pOnN
	end

	return 1/sumPByN
end

--Use this to check if an ab
function PseudoRNG:Next()
	-- P(N) = C * N
	local P = self.cons * (self.failedTries + 1)
	if math.random() <= P then
		--success!
		self.failedTries = 0
		return true
	else
		--failure
		self.failedTries = self.failedTries + 1
		return false
	end
end