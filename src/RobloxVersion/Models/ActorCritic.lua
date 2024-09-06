--[[

	--------------------------------------------------------------------

	Aqwam's Machine And Deep Learning Library (DataPredict)

	Author: Aqwam Harish Aiman
	
	Email: aqwam.harish.aiman@gmail.com
	
	YouTube: https://www.youtube.com/channel/UCUrwoxv5dufEmbGsxyEUPZw
	
	LinkedIn: https://www.linkedin.com/in/aqwam-harish-aiman/
	
	--------------------------------------------------------------------
		
	By using this library, you agree to comply with our Terms and Conditions in the link below:
	
	https://github.com/AqwamCreates/DataPredict/blob/main/docs/TermsAndConditions.md
	
	--------------------------------------------------------------------
	
	DO NOT REMOVE THIS TEXT!
	
	--------------------------------------------------------------------

--]]

local AqwamMatrixLibrary = require(script.Parent.Parent.AqwamMatrixLibraryLinker.Value)

local ReinforcementLearningActorCriticBaseModel = require(script.Parent.ReinforcementLearningActorCriticBaseModel)

ActorCriticModel = {}

ActorCriticModel.__index = ActorCriticModel

setmetatable(ActorCriticModel, ReinforcementLearningActorCriticBaseModel)

local function calculateProbability(vector)
	
	local zScoreVector, standardDeviationVector = AqwamMatrixLibrary:horizontalZScoreNormalization(vector)
	
	local squaredZScoreVector = AqwamMatrixLibrary:power(zScoreVector, 2)
	
	local probabilityVectorPart1 = AqwamMatrixLibrary:multiply(-0.5, squaredZScoreVector)
	
	local probabilityVectorPart2 = AqwamMatrixLibrary:exponent(probabilityVectorPart1)
	
	local probabilityVectorPart3 = AqwamMatrixLibrary:multiply(standardDeviationVector, math.sqrt(2 * math.pi))
	
	local probabilityVector = AqwamMatrixLibrary:divide(probabilityVectorPart2, probabilityVectorPart3)

	return probabilityVector

end

function ActorCriticModel.new(discountFactor)
	
	local NewActorCriticModel = ReinforcementLearningActorCriticBaseModel.new(discountFactor)
	
	setmetatable(NewActorCriticModel, ActorCriticModel)
	
	local actionProbabilityVectorHistory = {}
	
	local criticValueHistory = {}
	
	local rewardValueHistory = {}
	
	NewActorCriticModel:setCategoricalUpdateFunction(function(previousFeatureVector, action, rewardValue, currentFeatureVector)
		
		local ActorModel = NewActorCriticModel.ActorModel
		
		local actionVector = ActorModel:predict(previousFeatureVector, true)

		local actionProbabilityVector = calculateProbability(actionVector)

		local criticValue = NewActorCriticModel.CriticModel:predict(previousFeatureVector, true)[1][1]
		
		local logActionProbabilityVector = AqwamMatrixLibrary:logarithm(actionProbabilityVector)

		table.insert(actionProbabilityVectorHistory, logActionProbabilityVector)

		table.insert(criticValueHistory, criticValue)

		table.insert(rewardValueHistory, rewardValue)
		
	end)
	
	NewActorCriticModel:setDiagonalGaussianUpdateFunction(function(previousFeatureVector, expectedActionVector, rewardValue, currentFeatureVector, standardDeviationVector)
		
		local randomNormalVector = AqwamMatrixLibrary:createRandomNormalMatrix(1, #expectedActionVector[1])
		
		local actionVectorPart1 = AqwamMatrixLibrary:multiply(standardDeviationVector, randomNormalVector)
		
		local actionVector = AqwamMatrixLibrary:add(expectedActionVector, actionVectorPart1)
		
		local zScoreVectorPart1 = AqwamMatrixLibrary:subtract(actionVector, expectedActionVector)
		
		local zScoreVector = AqwamMatrixLibrary:divide(zScoreVectorPart1, standardDeviationVector)
		
		local squaredZScoreVector = AqwamMatrixLibrary:power(zScoreVector, 2)
		
		local logActionProbabilityVectorPart1 = AqwamMatrixLibrary:logarithm(standardDeviationVector)
		
		local logActionProbabilityVectorPart2 = AqwamMatrixLibrary:multiply(2, logActionProbabilityVectorPart1)
		
		local logActionProbabilityVectorPart3 = AqwamMatrixLibrary:add(squaredZScoreVector, logActionProbabilityVectorPart2)
		
		local logActionProbabilityVector = AqwamMatrixLibrary:add(logActionProbabilityVectorPart3, math.log(2 * math.pi))

		local criticValue = NewActorCriticModel.CriticModel:predict(previousFeatureVector, true)[1][1]
		
		table.insert(actionProbabilityVectorHistory, logActionProbabilityVector)

		table.insert(criticValueHistory, criticValue)

		table.insert(rewardValueHistory, rewardValue)

	end)
	
	NewActorCriticModel:setEpisodeUpdateFunction(function()
		
		local returnValueHistory = {}

		local discountedSum = 0

		local historyLength = #rewardValueHistory
		
		local discountFactor = NewActorCriticModel.discountFactor

		for h = historyLength, 1, -1 do

			discountedSum = rewardValueHistory[h] + (discountFactor * discountedSum)

			table.insert(returnValueHistory, 1, discountedSum)

		end

		local sumCriticLoss = 0
		
		local sumActorLossVector = AqwamMatrixLibrary:createMatrix(1, #actionProbabilityVectorHistory[1], 0)

		for h = 1, historyLength, 1 do

			local criticValue = criticValueHistory[h]

			local returnValue = returnValueHistory[h]

			local logActionProbabilityVector = actionProbabilityVectorHistory[h]
			
			local criticLoss = returnValue - criticValue

			local actorLossVector = AqwamMatrixLibrary:multiply(logActionProbabilityVector, criticLoss)

			sumCriticLoss = sumCriticLoss + criticLoss
			
			sumActorLossVector = AqwamMatrixLibrary:add(sumActorLossVector, actorLossVector)

		end
		
		local ActorModel = NewActorCriticModel.ActorModel

		local CriticModel = NewActorCriticModel.CriticModel
		
		local numberOfFeatures = ActorModel:getTotalNumberOfNeurons(1)

		local numberOfActions = #ActorModel:getClassesList()

		local featureVector = AqwamMatrixLibrary:createMatrix(1, numberOfFeatures, 1)
		
		sumActorLossVector = AqwamMatrixLibrary:unaryMinus(sumActorLossVector)

		CriticModel:forwardPropagate(featureVector, true)
		
		ActorModel:forwardPropagate(featureVector, true)

		CriticModel:backwardPropagate(-sumCriticLoss, true)
		
		ActorModel:backwardPropagate(sumActorLossVector, true)

		table.clear(actionProbabilityVectorHistory)

		table.clear(criticValueHistory)

		table.clear(rewardValueHistory)
		
	end)
	
	NewActorCriticModel:setResetFunction(function()
		
		table.clear(actionProbabilityVectorHistory)

		table.clear(criticValueHistory)

		table.clear(rewardValueHistory)
		
	end)
	
	return NewActorCriticModel
	
end

return ActorCriticModel