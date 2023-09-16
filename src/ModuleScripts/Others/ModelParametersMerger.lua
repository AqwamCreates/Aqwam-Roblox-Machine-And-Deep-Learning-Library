local AqwamMatrixLibrary = require(script.Parent.Parent.AqwamRobloxMatrixLibraryLinker.Value)

local ModelParametersMerger = {}

ModelParametersMerger.__index = ModelParametersMerger

local defaultMergeType = "average"

function ModelParametersMerger.new(Model, modelType, mergeType)

	if (Model == nil) then error("No model!") end

	if (modelType == nil) then error("No model type!") end

	local NewModelParametersMerger = {}

	setmetatable(NewModelParametersMerger, ModelParametersMerger)

	NewModelParametersMerger.Model = Model

	NewModelParametersMerger.modelType = modelType

	NewModelParametersMerger.mergeType = mergeType or defaultMergeType

	NewModelParametersMerger.ModelParametersArray = {}

	NewModelParametersMerger.featureMatrix = nil

	NewModelParametersMerger.labelVector = nil

	return NewModelParametersMerger

end

function ModelParametersMerger:setParameters(Model, modelType, mergeType)

	self.Model = Model or self.Model

	self.modelType = modelType or self.modelType

	self.mergeType = mergeType or self.mergeType

end

function ModelParametersMerger:setModelParameters(...)
	
	local inputtedModelParametersArray = {...}

	local proccesedModelsArray = ((#inputtedModelParametersArray > 0) and inputtedModelParametersArray) or nil
	
	self.ModelParametersArray = proccesedModelsArray

end

function ModelParametersMerger:setData(featureMatrix, labelVector)

	if (featureMatrix) and (labelVector) then

		if (#featureMatrix ~= #labelVector) then error("Feature matrix and the label vector does not contain the same number of rows!") end

	end

	self.featureMatrix = featureMatrix or self.featureMatrix

	self.labelVector = labelVector or self.labelVector

end

local function checkDepth(array, depth)

	depth = depth or 0

	local valueType = typeof(array)

	if (valueType == "table") then

		return checkDepth(array[1], depth + 1)

	else

		return depth

	end

end

local function checkIfIsTable(array)

	local depth = checkDepth(array)

	local isTable = (depth == 3)

	return isTable

end

local function generateModelParametersTableWithMatricesOfZeroValues(ModelParameters)

	local NewModelParameters = {}

	for i, matrix in ipairs(ModelParameters) do

		local numberOfRows = #matrix

		local numberOfColumns = #matrix[1]

		local newMatrix = AqwamMatrixLibrary:createMatrix(numberOfRows, numberOfColumns)

		table.insert(NewModelParameters, newMatrix)

	end

	return NewModelParameters

end

local function calculateTotalFromArray(array)

	local total = 0

	for i, value in ipairs(array) do total += value end

	return total

end

local function convertValueArrayToPercentageArray(array)

	local percentage

	local total = calculateTotalFromArray(array)

	local percentageArray = {}

	for i, value in ipairs(array) do

		if (total == 0) then

			percentage = 0

		else

			percentage = (value / total)

		end

		table.insert(percentageArray, percentage)

	end

	return percentageArray

end

local function calculateScaledModelParametersTable(ModelParametersArray, percentageArray)

	local NewModelParameters = generateModelParametersTableWithMatricesOfZeroValues(ModelParametersArray[1])

	for i, ModelParameters in ipairs(ModelParametersArray) do

		for j, matrix in ipairs(ModelParameters) do

			local calculatedMatrix = AqwamMatrixLibrary:multiply(matrix, percentageArray[i])

			NewModelParameters[j] = AqwamMatrixLibrary:add(NewModelParameters[j], calculatedMatrix)

		end

	end

	return NewModelParameters

end

local function calculateScaledModelParameters(ModelParametersArray, percentageArray)

	local FirstModelParameters = ModelParametersArray[1]

	local NewModelParameters = AqwamMatrixLibrary:createMatrix(#FirstModelParameters, #FirstModelParameters[1])

	for j, percentage in ipairs(percentageArray) do

		local matrix = ModelParametersArray[j]

		local calculatedMatrix = AqwamMatrixLibrary:multiply(matrix, percentage)

		NewModelParameters = AqwamMatrixLibrary:add(NewModelParameters, calculatedMatrix)

	end

	return NewModelParameters

end

local function generateErrorArrayForRegression(Model, ModelParametersArray, featureMatrix, labelVector)

	local errorArray = {}

	for i, ModelParameters in ipairs(ModelParametersArray) do

		Model:setModelParameters(ModelParameters)

		local predictVector = Model:predict(featureMatrix)

		local errorVector = AqwamMatrixLibrary:subtract(labelVector, predictVector)

		local absoluteErrorVector = AqwamMatrixLibrary:applyFunction(math.abs, errorVector)

		local errorValue = AqwamMatrixLibrary:sum(absoluteErrorVector)

		table.insert(errorArray, errorValue)

	end

	return errorArray

end

local function generateErrorArrayForClustering(Model, ModelParametersArray, featureMatrix)

	local errorArray = {}

	for i, ModelParameters in ipairs(ModelParametersArray) do

		Model:setModelParameters(ModelParameters)

		local _, distanceVector = Model:predict(featureMatrix)

		local errorValue = AqwamMatrixLibrary:sum(distanceVector)

		table.insert(errorArray, errorValue)

	end

	return errorArray

end

local function convertErrorArrayToAccuracyArray(errorArray)

	local accuracyArray = {}

	local errorPercentageArray = convertValueArrayToPercentageArray(errorArray)

	for i, errorPercentage in ipairs(errorPercentageArray) do

		local accuracy = 1 - errorPercentage

		table.insert(accuracyArray, accuracy)

	end

	return accuracyArray

end

local function generateAccuracyArray(Model, ModelParametersArray, featureMatrix, labelVector)

	local accuracyArray = {}

	local totalLabel = #labelVector

	for i, ModelParameters in ipairs(ModelParametersArray) do

		local accuracy = 0

		local totalCorrect = 0

		Model:setModelParameters(ModelParameters)

		for j = 1, totalLabel, 1 do

			local label = Model:predict(featureMatrix)

			if (label == labelVector[j][1]) then

				totalCorrect += 1

			end

		end

		accuracy = totalCorrect / totalLabel

		table.insert(accuracyArray, accuracy)

	end

	return accuracyArray

end

local function checkIfAllValuesAreZeroesInArray(array)

	local allZeroes = true

	for i, accuracyPercentage in ipairs(array) do

		array = (accuracyPercentage == 0)

		if (allZeroes == false) then break end

	end

	return allZeroes

end

local function generateAccuracyForEachModel(Model, modelType, mergeType, ModelParametersArray, featureMatrix, labelVector)
	
	local accuracyArray
	
	if (modelType == "regression") and (mergeType ~= "average") then

		local errorArray = generateErrorArrayForRegression(Model, ModelParametersArray, featureMatrix, labelVector)

		accuracyArray = convertErrorArrayToAccuracyArray(errorArray)

	elseif (modelType == "classification") and (mergeType ~= "average") then

		accuracyArray = generateAccuracyArray(Model, ModelParametersArray, featureMatrix, labelVector)

	elseif (modelType == "clustering") and (mergeType ~= "average") then

		local errorArray = generateErrorArrayForClustering(Model, ModelParametersArray, featureMatrix)

		accuracyArray = convertErrorArrayToAccuracyArray(errorArray)

	else

		error("Invalid model type!")

	end
	
	return accuracyArray
	
end

local function getIndexOfHighestAccuracy(accuracyArray)
	
	local index
	
	local highestAccuracy = -math.huge

	for i, accuracy in ipairs(accuracyArray)  do

		if (accuracy > highestAccuracy) then 

			highestAccuracy = accuracy 

			index = i

		end

	end
	
	return index
	
end

local function getSplitPercentageArray(mergeType, accuracyArray, numberOfModelParameters)
	
	local percentageSplitArray
	
	if (mergeType == "average") then

		local averageValue = 1 / numberOfModelParameters

		percentageSplitArray = table.create(numberOfModelParameters, averageValue)

	elseif (mergeType == "weightedAverage") then

		percentageSplitArray = convertValueArrayToPercentageArray(accuracyArray)

	elseif (mergeType == "best") then

		local areAllZeroes = checkIfAllValuesAreZeroesInArray(accuracyArray)
		
		local bestModelParametersIndex

		if (areAllZeroes == true) then 
			
			bestModelParametersIndex = Random.new():NextInteger(1, numberOfModelParameters)

			
		else
			
			bestModelParametersIndex = getIndexOfHighestAccuracy(accuracyArray)

		end
		
		percentageSplitArray = table.create(numberOfModelParameters, 0)

		percentageSplitArray[bestModelParametersIndex] = 1

	else

		error("Invalid merge type!")

	end
	
	return percentageSplitArray
	
end

local function mergeModelParameters(ModelParametersArray, percentageSplitArray)
	
	local NewModelParameters
	
	local isTable = checkIfIsTable(ModelParametersArray[1])
	
	if isTable then

		NewModelParameters = calculateScaledModelParametersTable(ModelParametersArray, percentageSplitArray)

	else

		NewModelParameters = calculateScaledModelParameters(ModelParametersArray, percentageSplitArray)

	end
	
	return NewModelParameters
	
end

function ModelParametersMerger:generate()

	local Model = self.Model
	
	local modelType = self.modelType
	
	local mergeType = self.mergeType

	local featureMatrix = self.featureMatrix

	local labelVector = self.labelVector

	local ModelParametersArray = self.ModelParametersArray
	
	local numberOfModelParameters = #ModelParametersArray
	
	local NewModelParameters
	
	if (typeof(ModelParametersArray) ~= "table") then error("No model parameters set!") end
	
	local accuracyArray = generateAccuracyForEachModel(Model, modelType, mergeType, ModelParametersArray, featureMatrix, labelVector) 
	
	local percentageSplitArray = getSplitPercentageArray(mergeType, accuracyArray, numberOfModelParameters)
	
	local NewModelParameters = mergeModelParameters(ModelParametersArray, percentageSplitArray)

	return NewModelParameters

end

return ModelParametersMerger
