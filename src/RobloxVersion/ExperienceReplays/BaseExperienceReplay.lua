BaseExperienceReplay = {}

BaseExperienceReplay.__index = BaseExperienceReplay

local defaultBatchSize = 32

local defaultMaxBufferSize = 100

local defaultNumberOfExperienceToUpdate = 1

function BaseExperienceReplay.new(batchSize, numberOfExperienceToUpdate, maxBufferSize)
	
	local NewBaseExperienceReplay = {}
	
	setmetatable(NewBaseExperienceReplay, BaseExperienceReplay)

	NewBaseExperienceReplay.batchSize = batchSize or defaultBatchSize

	NewBaseExperienceReplay.numberOfExperienceToUpdate = numberOfExperienceToUpdate or defaultNumberOfExperienceToUpdate

	NewBaseExperienceReplay.maxBufferSize = maxBufferSize or defaultMaxBufferSize
	
	NewBaseExperienceReplay.numberOfExperience = 0
	
	NewBaseExperienceReplay.replayBufferArray = {}
	
	return NewBaseExperienceReplay
	
end

function BaseExperienceReplay:setParameters(batchSize, numberOfExperienceToUpdate, maxBufferSize)
	
	self.batchSize = batchSize or self.batchSize

	self.numberOfExperienceToUpdate = numberOfExperienceToUpdate or self.numberOfExperienceToUpdate

	self.maxBufferSize = maxBufferSize or self.maxBufferSize
	
end

function BaseExperienceReplay:extendResetFunction(resetFunction)
	
	self.resetFunction = resetFunction
	
end

function BaseExperienceReplay:reset()
	
	self.numberOfExperience = 0
	
	table.clear(self.replayBufferArray)
	
	self.resetFunction()
	
end

function BaseExperienceReplay:setSampleFunction(sampleFunction)
	
	self.sampleFunction = sampleFunction
	
end

function BaseExperienceReplay:sample()

	return self.sampleFunction()
	
end

function BaseExperienceReplay:run(updateFunction)
	
	if (self.numberOfExperience < self.numberOfExperienceToUpdate) then return nil end
	
	self.numberOfExperience = 0

	local experienceReplayBatchArray = self:sample()

	for _, experience in ipairs(experienceReplayBatchArray) do -- (s1, a, r, s2)
		
		local previousState = experience[1]
		
		local action = experience[2]
		
		local rewardValue = experience[3]
		
		local currentState = experience[4]

		updateFunction(previousState, action, rewardValue, currentState)

	end
	
end

function BaseExperienceReplay:addExperience(previousState, action, rewardValue, currentState)
	
	local experience = {previousState, action, rewardValue, currentState}

	table.insert(self.replayBufferArray, experience)

	if (#self.replayBufferArray > self.maxBufferSize) then table.remove(self.replayBufferArray, 1) end
	
	self.numberOfExperience += 1
	
end

return BaseExperienceReplay
