--[[
	This class provides a Pseudo-random RNG, meaning it works with
	a pseudo-random probability distribution instead of a static random chance.
	The benefit of this is that you reduce the randomness in gameplay. If you
	want some more in-depth explanation see:
	http://dota2.gamepedia.com/Pseudo-random_distribution
		
	----HOW TO USE-----
	Create a pseudo-random RNG like this:	
	
	local rng = PseudoRNG.create( 0.25 ) -- immitates a 25% chance
	
	Then whenever you want to know if something procs, use this:	
	
	if rng:Next() then
		--proc
	else
		--didn't proc
	end
	
	UPDATE: added ChoicePseudoRNG, this class will use a pseudo-random distribution to
	choose an element based on its probability. Items chosen will have a lower probability
	next choice, items not chosen will have a higher probability.
	
	----HOW TO USE-----
	Create a pseudo-random ChoiceRNG like this:	
	NOTE: The probabilities HAVE to add up to 1!
	
	local choiceRNG = ChoicePseudoRNG.create( {0.2, 0.1, 0.3, 0.4} ) -- Adds 4 items with percentages 20%, 10%, 30% and 40%
	
	When you need to choose one of the elements you put in use:
	
	local result = choiceRNG:Choose()
	
	Result will contain a number from 1 to the number of elements you put in, signifying the items index in the input list.
	(1 is the item with prob 0.2, 2 is the item with prob 0.1 etc...)

	Author: Perry
]]
PseudoRNG = {}
PseudoRNG.__index = PseudoRNG

--construct a PseudoRNG for a certain chance (0 - 1; 25% -> 0.25)
function PseudoRNG.create( chance )
   local rng = {}             -- our new object
   setmetatable(rng, PseudoRNG)
   
   rng:Init( chance )
   return rng
end

function PseudoRNG:Init( chance )
	self.failedTries = 0
	--calculate the constant
	self.cons = PseudoRNG:CFromP( chance )
end

function PseudoRNG:CFromP( P )
	local Cupper = P
	local Clower = 0
	local Cmid = 0
	
	local p1 = 0
	local p2 = 1
	
	while true do
		Cmid = (Cupper + Clower) / 2;
		p1 = PseudoRNG:PFromC( Cmid )
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

------------------------------------
-- Pseudo-Random Choice - choose between a number of probabilities
------------------------------------
ChoicePseudoRNG = {}
ChoicePseudoRNG.__index = ChoicePseudoRNG
--construct a ChoicePseudoRNG from a list of probabilities, they HAVE to add up to 1 though!
function ChoicePseudoRNG.create( probs )
   local rng = {}             -- our new object
   setmetatable(rng, ChoicePseudoRNG)
   
   rng:Init( probs )
   return rng
end

function ChoicePseudoRNG:Init( probs )
	self.probs = {} --the probability the drop should be around
	self.curProbs = {} --the current probability
	self.min = {} --the minimum value for this probability
	
	for _,chance in pairs( probs ) do
		self.probs[#self.probs+1] = chance
		self.curProbs[#self.curProbs+1] = chance
		self.min[#self.min+1] = PseudoRNG:CFromP( chance ) -- calculate the minimum
	end
		
	--scramble the distribution a bit before using
	for i=0, RandomInt(5, 16) do
		self:Choose()
	end
end

--Use this to choose one of the elements, returns the index of the chosen item (starts at 1!)
function ChoicePseudoRNG:Choose()
	local rand = math.random()
	local cumulative = 0
	
	local choice = #self.min
	
	--loop over all probabilities we have
	for i=1,#self.probs do
		--the number we generated is below the current probability and all previous probabilities
		--we choose this i
		if cumulative + self.curProbs[i] > rand then
			choice = i
			break
		else
			--otherwise add this probability to the cumulative value and continue
			cumulative = cumulative + self.curProbs[i]
		end
	end
	
	--Set the chosen index to its minimum probability and calculate how much we have to redistribute
	local redistrib = self.curProbs[choice] - self.min[choice]
	self.curProbs[choice] = self.min[choice]
	
	--distribute the 'extra probability' we got from our choice over all indices we didn't choose
	for i=1,#self.min do
		if i ~= choice then
			--we base the amount we give on how large the index's original probability is
			self.curProbs[i] = self.curProbs[i] + redistrib * self.probs[i]/(1-self.probs[choice])
		end
	end
	
	return choice
end

--check if our RNG is still valid
function ChoicePseudoRNG:IsValid()
	local total = 0
	for i=1,#self.min do
		total = total + self.curProbs[i]
	end
	
	if total ~= 1 then
		return false
	else
		return true
	end
end