-------------------------------------------------------------------------------
--	Natural Deduction Logic Module
--
--	This module defines the logic of proving utilizing Natural Deduction.
--
--	@authors: bpalkmim
--
-------------------------------------------------------------------------------

require "Logic/NatDGraph"
require "Logic/ConstantsForNatD"
require "logging"
require "logging.file"

local logger = logging.file("aux/prover%s.log", "%Y-%m-%d")
logger:setLevel(logging.INFO)

LogicModule = {}

-- Lista dos ramos ativos no momento
local openBranchesList = {}
-- O grafo em si (global ao módulo)
local graph = nil
-- Variável para indexação de descartes de hipótese
-- Também utilizado para indexação das →-Intro
local currentStepNumber = 0
-- Contagem das →-Elim
local elimIndex = 0
-- Array com os nós que representam átomos
local atoms = {}

-- Lista das hipóteses a serem descartadas (também chamados de Goals).
-- Uma hipótese é um predicado lógico. Na prática, essa lista contém os
-- nós do grafo da prova.
LogicModule.dischargeable = {}

-- Private functions

-- Remove um ramo aberto da lista de ramos abertos.
-- Uso principal: quando o ramo já foi expandido/descartado.
local function removeOpenBranch(natDNode)
	local foundInTable = false

	for i, node in ipairs(openBranchesList) do
		if LogicModule.nodeEquals(node, natDNode) then
			table.remove(openBranchesList, i)
			foundInTable = true
		end
	end

	if not foundInTable then
		logger:info("WARNING - Attempted to remove a node from openBranchesList which was not in it.")
	end
end

-- Adiciona um novo ramo aberto na lista de ramos abertos.
local function addNewOpenBranch(natDNode)
	openBranchesList[#openBranchesList + 1] = natDNode
end

-- Função que verifica se o goal corrente pode ser alcançado pelo nó (ramo) recebido, diretamente.
-- Caso seja, retorna true, e false caso contrário. Em caso de reotrno positivo também retorna o label
-- da regra a ser utilizada (no caso, →-Intro ou →-Elim).
-- A preferência de retorno é dada à →-Intro, pois há menos possibilidade de aumento do tamanho da
-- demonstração por só abrir um ramo.
local function isGoalReachable(currentGoalNode, currentNode)
	-- Verifica se é alcançável via →-Intro
	-- currentNode deve ser uma implicação e seu nó à direita deve ser currentGoalNode
	if currentNode:getInformation("type") == opImp.graph then
		if LogicModule.nodeEquals(currentGoalNode, currentNode:getEdgeOut(lblEdgeDir):getDestino()) then
			return true, lblRuleImpIntro
		end
	end

	-- Verifica se é alcançável via →-Elim
	-- currentNode deve ser o nó à direita de currentGoalNode
	if currentGoalNode:getInformation("type") == opImp.graph then
		if LogicModule.nodeEquals(currentNode, currentGoalNode:getEdgeOut(lblEdgeDir):getDestino()) then
			return true, lblRuleImpElim
		end
	end

	return false, ""
end

local function createGraphEmpty()

	local NatDGraph = Graph:new()
	NatDNode:resetCounters()
	
	local NodeGG = NatDNode:new(lblNodeGG)
	local nodes = {NodeGG}
	local edges = {}

	NatDGraph:addNodes(nodes)
	NatDGraph:addEdges(edges)
	NatDGraph:setRoot(NodeGG)
	return NatDGraph
end

-- @param letters Stores all atoms.  
local function createGraphFormula(formulasTable, letters)

	local S1
	local S2
	local nodes
	local edges
	local NodeLetter = nil	
	local FormulaGraph = Graph:new()

	if formulasTable.tag == "Atom" then 
		local prop_letter = formulasTable["1"]
		for k,v in pairs(letters) do 
			if k == prop_letter then 
				NodeLetter = v
			end
		end
		if not NodeLetter then	
			NodeLetter = NatDNode:new(prop_letter)
			letters[prop_letter] = NodeLetter
		end
	
		nodes = {NodeLetter}
		edges = {}

		NodeLetter:setInformation("nextDED", 1)
		
		FormulaGraph:addNodes(nodes)
		FormulaGraph:addEdges(edges)
		FormulaGraph:setRoot(NodeLetter)
		
	elseif formulasTable.tag == "imp" then

		S1, letters = createGraphFormula(formulasTable["1"],letters)
		S2, letters = createGraphFormula(formulasTable["2"],letters)

		local NodeImp = NatDNode:new(opImp.graph)
		local EdgeEsq = NatDEdge:new(lblEdgeEsq, NodeImp, S1.root)
		local EdgeDir = NatDEdge:new(lblEdgeDir, NodeImp, S2.root)

		nodes = {NodeImp}
		edges = {EdgeEsq, EdgeDir}

		NodeImp:setInformation("nextDED", 1)

		FormulaGraph:addNodes(S1.nodes)
		FormulaGraph:addNodes(S2.nodes)
		FormulaGraph:addNodes(nodes)
		FormulaGraph:addEdges(S1.edges)
		FormulaGraph:addEdges(S2.edges)
		FormulaGraph:addEdges(edges)
		FormulaGraph:setRoot(NodeImp)

		-- TODO criar demais casos que não só implicação
	end

	return FormulaGraph, letters
end	

local function createGraphNatD(form_table, letters)

	local NatDGraph = Graph:new()
	local S,L
	local NodeGG = NatDNode:new(lblNodeGG)
	S,L = createGraphFormula(form_table, letters)

	atoms = L

	local newEdge = NatDEdge:new(lblRootEdge, NodeGG, S.root)

	local nodes = {NodeGG}
	NatDGraph:addNodes(nodes)
	NatDGraph:addNodes(S.nodes)
	local edges = {newEdge}
	NatDGraph:addEdges(edges)
	NatDGraph:addEdges(S.edges)

	currentStepNumber = 0
	elimIndex = 0

	return NatDGraph
end

-- TODO ⊥ classico, ⊥ intuicionista, ¬ intro e ¬ elim.

-- Aplica a regra de introdução da implicação no nó selecionado, adicionando um elemento à lista
-- de hipóteses para descarte posterior.
local function applyImplyIntroRule(formulaNode)
	logger:debug("ImplyIntro: Expanding "..formulaNode:getLabel())

	local impLeft = formulaNode:getEdgeOut(lblEdgeEsq):getDestino()
	local impRight = formulaNode:getEdgeOut(lblEdgeDir):getDestino()

	-- Nós e arestas novos.
	local introStepNode = NatDNode:new(lblRuleImpIntro)
	local introStepEdge = NatDEdge:new(lblEdgeDeduction..formulaNode:getInformation("nextDED"), formulaNode, introStepNode)
	local hypothesisEdge = NatDEdge:new(lblEdgeHypothesis, introStepNode, impLeft)
	local predicateEdge = NatDEdge:new(lblEdgePredicate, introStepNode, impRight)

	currentStepNumber = currentStepNumber + 1
	introStepEdge:setInformation("rule", opImp.tex.." \\mbox{intro}".."_{"..currentStepNumber.."}")

	-- Adiciona a hipótese à lista de hipóteses descartáveis
	LogicModule.dischargeable[currentStepNumber] = impLeft

	local newEdges = {introStepEdge, hypothesisEdge, predicateEdge}

	graph:addNode(introStepNode)
	graph:addEdges(newEdges)

	formulaNode:setInformation("isExpanded", true)

	logger:info("applyImplyIntroRule - "..formulaNode:getLabel().." was expanded")

	-- Aqui verificamos se o nó presente na parte superior da prova pode ser hipótese a descartar.
	introStepNode:setInformation("isClosed", true)
	impRight:setInformation("discharged", false)
	for _, node in ipairs(LogicModule.dischargeable) do
		if LogicModule.nodeEquals(node, impRight) then
			introStepNode:setInformation("isClosed", true)
			impRight:setInformation("discharged", true)
			break
		end
	end

	-- Caso não seja hipótese a descartar, adicionamos o ramo à lista de ramos abertos.
	if not impRight:getInformation("discharged") then
		addNewOpenBranch(impRight)
	end

	-- Remove o nó corrente da lista de ramos abertos.
	removeOpenBranch(formulaNode)
	formulaNode:setInformation("nextDED", formulaNode:getInformation("nextDED") + 1)

	return graph, formulaNode:getInformation("nextDED") - 1
end

-- Função que aplica a →-Elim em formulaNode.
-- Ela pode receber também outros nós: hypNode (que representa o predicado sem a implicação a ser eliminada),
-- e implyNode (que representa o predicado cuja implicação será eliminada). Caso sejam recebidos juntos é
-- verificado se são compatíveis.
-- Sempre é verificada a compatibilidade da conclusão de implyNode com formulaNode (caso contrário não faria
-- sentido a →-Elim).
-- Caso seja recebido apenas hypNode, implyNode será gerado ao criar uma implicação hypNode → formulaNode.
-- Caso seja recebido apenas implyNode, hypNode será gerado a partir da premissa da implicação de implyNode.
local function applyImplyElimRule(formulaNode, hypNode, implyNode)
	logger:debug("ImplyElim: Expanding "..formulaNode:getLabel())

	-- Nós novos
	local hypothesisNode, elimStepNode, impNode = nil
	local newNodes = {}
	-- Arestas novas
	local impLeftEdge, impRightEdge, elimStepEdge, predicateHypEdge, predicateImpEdge = nil
	local newEdges = {}

	-- Ambos os nós recebidos
	if hypNode ~= nil and implyNode ~= nil then
		-- Nós incompatíveis
		if not LogicModule.nodeEquals(implyNode:getEdgesOut(lblEdgeEsq):getDestino(), hypNode) then
			logger:info("applyImpElimRule recieved 3 unrelated nodes.")
			return graph
		-- Nós compatíveis
		else
			hypothesisNode = hypNode
			impNode = implyNode
			impLeftEdge = impNode:getEdgeOut(lblEdgeEsq)
			impRightEdge = impNode:getEdgeOut(lblEdgeDir)
		end

	-- Recebeu apenas o nó de hipótese
	elseif hypNode ~= nil and implyNode == nil then
		hypothesisNode = hypNode
		impNode = NatDNode:new(opImp.graph)
		impLeftEdge = NatDEdge:new(lblEdgeEsq, impNode, hypothesisNode)
		impRightEdge = NatDEdge:new(lblEdgeDir, impNode, formulaNode)
		table.insert(newNodes, impNode)
		table.insert(newEdges, impLeftEdge)
		table.insert(newEdges, impRightEdge)

	-- Recebeu apenas o nó de implicação
	elseif hypNode == nil and implyNode ~= nil then
		impNode = implyNode
		impLeftEdge = impNode:getEdgeOut(lblEdgeEsq)
		impRightEdge = impNode:getEdgeOut(lblEdgeDir)
		hypothesisNode = impLeftEdge:getDestino()

	-- Ambos nulos; não recebeu nenhum dos dois.
	else
		-- TODO ver como tratar esse caso
		logger:info("applyImpElimRule recieved 1 node only, when it needs at least 2.")
		return graph
	end

	elimStepNode = NatDNode:new(lblRuleImpElim)
	elimStepEdge = NatDEdge:new(lblEdgeDeduction..formulaNode:getInformation("nextDED"), formulaNode, elimStepNode)
	predicateHypEdge = NatDEdge:new(lblEdgePredicate.."1", elimStepNode, hypothesisNode)
	predicateImpEdge = NatDEdge:new(lblEdgePredicate.."2", elimStepNode, impNode)

	elimIndex = elimIndex + 1
	elimStepEdge:setInformation("rule", opImp.tex.." \\mbox{elim}".."_{"..elimIndex.."}")

	table.insert(newNodes, elimStepNode)
	table.insert(newEdges, elimStepEdge)
	table.insert(newEdges, predicateHypEdge)
	table.insert(newEdges, predicateImpEdge)

	graph:addNodes(newNodes)
	graph:addEdges(newEdges)

	formulaNode:setInformation("isExpanded", true)

	logger:info("applyImplyElimRule - "..formulaNode:getLabel().." was expanded")

	-- Aqui verificamos se os nós presentes na parte superior da prova podem ser hipóteses a descartar.
	elimStepNode:setInformation("isLeftClosed", false)
	elimStepNode:setInformation("isRightClosed", false)
	hypothesisNode:setInformation("discharged", false)
	impNode:setInformation("discharged", false)
	for i, node in ipairs(LogicModule.dischargeable) do
		if LogicModule.nodeEquals(node, hypothesisNode) then
			elimStepNode:setInformation("isLeftClosed", true)
			hypothesisNode:setInformation("discharged", true)
		elseif LogicModule.nodeEquals(node, impNode) then
			elimStepNode:setInformation("isRightClosed", true)
			impNode:setInformation("discharged", true)
		end
	end

	-- Caso não seja hipótese a descartar, adicionamos o ramo à lista de ramos abertos.
	-- hypothesisNode (pred1)
	if not hypothesisNode:getInformation("discharged") then
		addNewOpenBranch(hypothesisNode)
	end
	-- impNode (pred2)
	if not impNode:getInformation("discharged") then
		addNewOpenBranch(impNode)
	end

	-- Remove o nó corrente da lista de ramos abertos.
	removeOpenBranch(formulaNode)
	formulaNode:setInformation("nextDED", formulaNode:getInformation("nextDED") + 1)

	return graph, formulaNode:getInformation("nextDED") - 1
end

function LogicModule.expandImplyIntroRule(agraph, formulaNode)
	local typeOfNode = formulaNode:getInformation("type")

	graph = agraph
	if typeOfNode == opImp.graph then
		graph = applyImplyIntroRule(formulaNode)
		print_all()
	else
		logger:info("WARNING - ImpIntro used on an non-implication node.")
	end

	return true, graph
end

function LogicModule.expandImplyElimRule(agraph, formulaNode, hypothesisNode)

	graph = agraph
	graph = applyImplyElimRule(formulaNode, hypothesisNode)
	print_all()

	return true, graph
end

-- Public functions

--- Create a graph from a formula in table form.
--- Returns a graph that represents the given formula.
--- @param form_table - Formula in table form.
function LogicModule.createGraphFromTable(form_table)
	local letters = {}
	local graph = nil
	
	if form_table =="empty" then 
		graph = createGraphEmpty()
	else
		graph = createGraphNatD(form_table, letters)
	end

	return graph
end

-- Função principal do módulo, que realiza a expansão geral dos nós do grafo.
function LogicModule.expandAll(agraph, natDNode)

	graph = agraph

	local deductionStep = 1
	local numBla = 0

	-- Começar a prova pelo nó inicial caso não tenha sido dado um nó
	local currentNode = natDNode
	if currentNode == nil then
		currentNode = graph:getNode(lblNodeGG):getEdgeOut(lblRootEdge):getDestino()
	end

	-- Primeiros passos: realizar repetidamente ImpIntros até não ter mais uma implicação
	while currentNode:getInformation("type") == opImp.graph do
		graph, deductionStep = applyImplyIntroRule(currentNode)
		if #openBranchesList == 0 then
			break
		else
			currentNode = currentNode:getEdgeOut(lblEdgeDeduction..deductionStep):getDestino():getEdgeOut(lblEdgePredicate):getDestino()
		end
	end

	-- Até aqui, temos a certeza de que há apenas um ramo a ser expandido, então guardamos esse nó.
	-- subRootNode será um nó fixo, para o qual voltaremos com currentNode caso necessário.
	local subRootNode = currentNode

	-- Passos seguintes: realizar ImpElims e ImpIntros conforme necessário nos ramos livres.
	-- Ramo aberto: sentença lógica ainda não provada.
	-- Ramo fechado: hipótese descartada.
	-- Goals: serão retirados da lista de dischargeable.
	local currentGoalNode = LogicModule.dischargeable[1]
	local parentGoalNode = currentGoalNode
	local currentGoalIndex = 1
	local isReachable = nil
	local ruleToApply = ""

	while #openBranchesList > 0 do
		currentNode = openBranchesList[1]
		if currentNode:getInformation("Attempts") == nil then
			currentNode:setInformation("Attempts", 0)
		end
		
		isReachable, ruleToApply = isGoalReachable(currentGoalNode, currentNode)

		if isReachable then 
			-- Nó que não é de implicação. Não é possível realizar ImpIntro, então deveremos realizar ImpElim.
			-- TODO A VER: nesse caso, realizamos ImpElim utilizando a hipótese descartável de menor tamanho
			-- para ser o nó maior da →-Elim.
			if currentNode:getInformation("type") ~= opImp.graph then
				if currentGoalNode:getInformation("type") == opImp.graph then
					--print("ping")
					--print(currentNode:getLabel())
					--print(currentGoalNode:getLabel())
					graph, deductionStep = applyImplyElimRule(currentNode, nil, currentGoalNode)
				else
					graph, deductionStep = applyImplyElimRule(currentNode, currentGoalNode, nil)
				end

			-- Nó de implicação. Devemos decidir entre ImpElim ou ImpIntro.
			else
				if ruleToApply == lblRuleImpIntro then
					--print("pong")
					--print(currentNode:getLabel())
					--print(currentGoalNode:getLabel())
					graph, deductionStep = applyImplyIntroRule(currentNode)
					--[[numBla = numBla + 1
					if numBla > 5 then
						logger:info("INFO - A prova não pôde ser concluída. Teorema não válido.")
						currentNode:setInformation("Invalid", true)

						-- Marca os demais nós abertos como inválidos
						for i, node in ipairs(openBranchesList) do
							node:setInformation("Invalid", true)
						end

						print(numBla)
						-- Reseta os valores de nextDED dos nós para imprimir
						for i, node in ipairs(graph:getNodes()) do
							node:setInformation("nextDED", 1)
						end
						return false, graph
					end
					--]]
				-- TODO verificar se nesse caso é sempre esse tratamento
				elseif ruleToApply == lblRuleImpElim then
					if currentGoalNode:getInformation("type") == opImp.graph then
						graph, deductionStep = applyImplyElimRule(currentNode, nil, currentGoalNode)

					else
						graph, deductionStep = applyImplyElimRule(currentNode, currentGoalNode, nil)
					end
				
				else
					logger:info("ERRO - ruleToApply em LogicModule.expandAll não apresenta valor válido.")
					return false, graph
				end
			end

			currentGoalNode = parentGoalNode

		-- Goal atual não alcançável. Passamos para o subgoal (caso não seja possível, vamos para outro goal).
		-- Subgoal: o nó à direita da implicação do goal atual.
		else
			if currentGoalNode:getInformation("type") == opImp.graph then
				--print("pang")
				--print(currentNode:getLabel())
				--print(currentGoalNode:getLabel())
				parentGoalNode = currentGoalNode
				currentGoalNode = currentGoalNode:getEdgeOut(lblEdgeDir):getDestino()

			-- Não sendo uma implicação, partimos para o Goal seguinte. Não havendo um Goal seguinte,
			-- voltamos ao inicial.
			-- Caso não seja possível continuar aprova após mais de duas passadas para esse currentNode,
			-- temor que o teorema não é válido.
			-- TODO podemos ter essa certeza?
			else
				if currentGoalIndex + 1 > #LogicModule.dischargeable then
					-- Nesse caso, aplicar a regra de →-Intro.
					if currentNode:getInformation("type") == opImp.graph then
						graph, deductionStep = applyImplyIntroRule(currentNode)
						currentGoalNode = parentGoalNode

					-- O número máximo de tentativas é 2^{i}, onde i é o número de fórmulas atômicas.	
					-- doi do artigo fonte: j.entcs.2015.06.004
					elseif currentNode:getInformation("Attempts") > math.pow(2, #atoms) then 
						logger:info("INFO - A prova não pôde ser concluída. Teorema não válido.")
						currentNode:setInformation("Invalid", true)

						-- Marca os demais nós abertos como inválidos
						for i, node in ipairs(openBranchesList) do
							node:setInformation("Invalid", true)
						end

						-- Reseta os valores de nextDED dos nós para imprimir
						for i, node in ipairs(graph:getNodes()) do
							node:setInformation("nextDED", 1)
						end
						return false, graph

					-- Voltamos ao primeiro Goal.
					else
						currentNode:setInformation("Attempts", currentNode:getInformation("Attempts") + 1)
						currentGoalNode = LogicModule.dischargeable[1]
						parentGoalNode = currentGoalNode
						currentGoalIndex = 1
					end
				-- Goal seguinte.
				else
					currentGoalNode = LogicModule.dischargeable[currentGoalIndex + 1]
					parentGoalNode = currentGoalNode
					currentGoalIndex = currentGoalIndex + 1
				end
			end
		end
	end

	-- Reseta os valores de nextDED dos nós para imprimir
	for i, node in ipairs(graph:getNodes()) do
		node:setInformation("nextDED", 1)
	end
	return true, graph
end

function LogicModule.getGraph()
	return graph
end

local numRecursions = 0

-- Função auxiliar recursiva para verificar igualdade de dois nós do grafo.
-- Adaptada apenas para implicações e termos atômicos, utilizada principalmente
-- para verificar se uma proposição lógica é uma hipótese a ser descartada.
-- @param node1 Primeiro nó.
-- @param node2 Segundo nó.
-- @return true se são iguais, ou false caso sejam diferentes.
function LogicModule.nodeEquals(node1, node2)
	local node1Left, node1Right, node2Left, node2Right = nil

	-- Checagem de nós nulos. Aqui não é utilizado assert pois dois nós nulos teoricamente são iguais.
	--- Casos base
	if node1 == nil then
		logger:info("WARNING - function nodeEquals in module NaturalDeductionLogic recieved first parameter nil")
		-- Ambos os nós nulos, tecnicamente são iguais (mas é lançado um aviso).
		if node2 == nil then
			logger:info("WARNING - function nodeEquals in module NaturalDeductionLogic recieved second parameter nil")
			return true
		-- Primeiro nó nulo e segundo não nulo.
		else
			return false
		end
	else
		-- Primeiro nó não nulo e segundo nulo.
		if node2 == nil then
			logger:info("WARNING - function nodeEquals in module NaturalDeductionLogic recieved second parameter nil")
			return false
		end
	end

	-- Ambos os nós não nulos

	-- Ambos nós atômicos; basta comparar seus labels
	if node1:getInformation("type") ~= opImp.graph and node2:getInformation("type") ~= opImp.graph then
		return node1:getLabel() == node2:getLabel()
	-- Primeiro nó implicação, segundo nó atômico
	elseif node1:getInformation("type") == opImp.graph and node2:getInformation("type") ~= opImp.graph then
		return false
	-- Primeiro nó atômico, segundo nó implicação
	elseif node1:getInformation("type") ~= opImp.graph then
		return false

	-- Ambos nós de implicação.
	else
		-- São a mesma implicação.
		if node1:getLabel() == node2:getLabel() then
			return true
		end

		numRecursions = numRecursions + 1
		print(numRecursions)

		-- São implicações diferentes.
		-- Passo indutivo
		for i, edge in ipairs(node1:getEdgesOut()) do
			if edge:getLabel() == lblEdgeEsq then
				node1Left = edge:getDestino()
			elseif edge:getLabel() == lblEdgeDir then
				node1Right = edge:getDestino()
			end
		end

		for i, edge in ipairs(node2:getEdgesOut()) do
			if edge:getLabel() == lblEdgeEsq then
				node2Left = edge:getDestino()
			elseif edge:getLabel() == lblEdgeDir then
				node2Right = edge:getDestino()
			end
		end
		
		print(node1:getLabel())
		print(node2:getLabel())

		return LogicModule.nodeEquals(node1Left, node2Left) and LogicModule.nodeEquals(node1Right, node2Right)
	end
end
--[[
function load()
	local f = loadfile("commands.lua")
	f()
end

function run()
	LogicModule.expandAll(graph)
end

function step(pstep)
	LogicModule.expandAll(graph, pstep)
end

function print_all()
	PrintModule.printProof(graph, "")
	os.showProofOnBrowser()	
	clear()	
end
]]