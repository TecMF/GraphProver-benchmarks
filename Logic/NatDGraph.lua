-------------------------------------------------------------------------------
--Natural Deduction Graph Module
--
--Extends Node and Edge modules. 
--Here is defined the node estructure of the Natural Deduction Graph.
--
--@authors: bpalkmim
--
-------------------------------------------------------------------------------

require "Logic/ConstantsForNatD"
require "Logic/Graph"

-- Utility counters
edgeCount = 0
andNodeCount = 0
notNodeCount = 0
orNodeCount  = 0
implyNodeCount = 0
botNodeCount = 0
impIntroNodeCount = 0
impElimNodeCount = 0

-- Defining the NatDNode, extends Node
NatDNode = {}

-- Creates a NatDNode.
-- @param labelNode The label of the NatDNode to be created.
function NatDNode:new(labelNode)
	local typeNode = labelNode

	if labelNode == opNot.graph then
		labelNode = labelNode .. notNodeCount
		notNodeCount = notNodeCount + 1

	elseif labelNode == opOr.graph then
		labelNode = labelNode .. orNodeCount
		orNodeCount = orNodeCount + 1
	elseif labelNode == opAnd.graph then
		labelNode = labelNode .. andNodeCount
		andNodeCount = andNodeCount + 1
	elseif labelNode == opImp.graph then
		labelNode = labelNode .. implyNodeCount
		implyNodeCount = implyNodeCount + 1
	
	elseif labelNode == lblBot then
		labelNode = labelNode .. botNodeCount
		botNodeCount = botNodeCount + 1

	elseif labelNode == lblRuleImpIntro then		
		labelNode = labelNode .. impIntroNodeCount
		impIntroNodeCount = impIntroNodeCount + 1
	elseif labelNode == lblRuleImpElim then		
		labelNode = labelNode .. impElimNodeCount
		impElimNodeCount = impElimNodeCount + 1
	end

	local newNode = Node:new(labelNode)

	newNode:setInformation("type", typeNode)
	newNode:setInformation("isExpanded", false)

	newNode:initEdgesIn()
	newNode:initEdgesOut()

	return newNode
end

function NatDNode:resetCounters()
	edgeCount = 0
	andNodeCount = 0
	notNodeCount = 0
	orNodeCount  = 0
	implyNodeCount = 0
	botNodeCount = 0
	impIntroNodeCount = 0
	impElimNodeCount = 0
end

-- Defining the NatDEdge, extends Edge
NatDEdge = {}

--- If label is equal to "", then a number is created acording to the origin node edgeCount field.	
function NatDEdge:new(label, origin, destination)

	local edgeCount = nil

	if label ~= '' then
		return Edge:new(label, origin, destination)
	end

	local labelNodeOrigin = string.sub(origin:getLabel(), 2)		

	if tonumber(labelNodeOrigin) == nil then
		return Edge:new(label, origin, destination)
	end

	edgeCount = origin:getInformation("edgeCount")

	if edgeCount == nil then		
		origin:setInformation("edgeCount", 0)
		edgeCount = 0
	else
		edgeCount = edgeCount + 1
		origin:setInformation("edgeCount", edgeCount)
	end

	label = label .. edgeCount

	return Edge:new(label, origin, destination)
end

