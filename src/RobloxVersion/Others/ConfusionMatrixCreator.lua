local AqwamMatrixLibrary = require(script.Parent.Parent.AqwamMatrixLibraryLinker.Value)

ConfusionMatrixCreator = {}

ConfusionMatrixCreator.__index = ConfusionMatrixCreator

local function areNumbersOnlyInList(list)

	for i, value in ipairs(list) do

		if (typeof(value) ~= "number") then return false end

	end

	return true

end

local function createClassesList(labelVector)

	local classesList = {}

	local value

	for i = 1, #labelVector, 1 do

		value = labelVector[i][1]

		if not table.find(classesList, value) then

			table.insert(classesList, value)

		end

	end

	return classesList

end

local function checkIfAnyLabelVectorIsNotRecognized(labelVector, classesList)

	for i = 1, #labelVector, 1 do

		if table.find(classesList, labelVector[i][1]) then continue end

		return true

	end

	return false

end

function ConfusionMatrixCreator:checkLabelVectors(trueLabelVector, predictedLabelVector)

	if (#self.ClassesList == 0) then

		self.ClassesList = createClassesList(trueLabelVector)

		local areNumbersOnly = areNumbersOnlyInList(self.ClassesList)

		if (areNumbersOnly) then table.sort(self.ClassesList, function(a,b) return a < b end) end

	else

		if checkIfAnyLabelVectorIsNotRecognized(trueLabelVector, self.ClassesList) then error("A value does not exist in the classes list is present in the true label vector.") end
		
		if checkIfAnyLabelVectorIsNotRecognized(predictedLabelVector, self.ClassesList) then error("A value does not exist in the classes list is present in the predicted label vector.") end
		
	end

end

function ConfusionMatrixCreator.new(classesList)
	
	local NewConfusionMatrixCreator = {}
	
	setmetatable(NewConfusionMatrixCreator, ConfusionMatrixCreator)
	
	NewConfusionMatrixCreator.ClassesList = classesList or {}
	
	return NewConfusionMatrixCreator
	
end

function ConfusionMatrixCreator:setParameters(classesList)
	
	self.ClassesList = classesList or self.ClassesList
	
end

function ConfusionMatrixCreator:createConfusionMatrix(trueLabelVector, predictedLabelVector)
	
	if (#trueLabelVector ~= #predictedLabelVector) then error("The number of data are not equal!") end
	
	self:checkLabelVectors(trueLabelVector, predictedLabelVector)
	
	local classesList = self.ClassesList
	
	local confusionMatrix = AqwamMatrixLibrary:createMatrix(#classesList, #classesList)
	
	local numberOfUnknownClassifications = 0
	
	for i = 1, #trueLabelVector, 1 do -- row: true value, column: predictedLabel
		
		local trueLabel = trueLabelVector[i][1]
			
		local predictedLabel = predictedLabelVector[i][1]
			
		local trueClassIndex = table.find(classesList, trueLabel)
			
		local predictedClassIndex = table.find(classesList, predictedLabel)
		
		if (trueClassIndex) and (predictedClassIndex) then
			
			confusionMatrix[trueClassIndex][predictedClassIndex] = confusionMatrix[trueClassIndex][predictedClassIndex] + 1
			
		else
			
			numberOfUnknownClassifications += 1
			
		end
			
	end
	
	return confusionMatrix, numberOfUnknownClassifications
	
end

function ConfusionMatrixCreator:printConfusionMatrix(trueLabelVector, predictedLabelVector)
	
	local confusionMatrix = self:createConfusionMatrix(trueLabelVector, predictedLabelVector)
	
	local classesList = self.ClassesList
	
	local maxClassLabelLength = 0

	-- Find the maximum length of class labels for formatting
	for _, classLabel in ipairs(classesList) do
		
		maxClassLabelLength = math.max(maxClassLabelLength, #tostring(classLabel))
		
	end

	-- Print column headers (predicted labels)
	print(string.rep(" ", maxClassLabelLength + 2)) -- Space for row labels
	
	for _, predictedLabel in ipairs(classesList) do
		
		print(string.format("%-" .. maxClassLabelLength .. "s ", "Predicted " .. predictedLabel))
		
	end
	
	print("\n")

	-- Print rows (true labels) along with confusion matrix values
	for i, trueLabel in ipairs(classesList) do
		
		print(string.format("%-" .. maxClassLabelLength .. "s | ", "Actual " .. trueLabel))

		for j, predictedLabel in ipairs(classesList) do
			
			print(string.format("%-" .. maxClassLabelLength .. "d ", confusionMatrix[i][j]))
			
		end
		
		print("\n")
		
	end
	
	return confusionMatrix
	
end

return ConfusionMatrixCreator
