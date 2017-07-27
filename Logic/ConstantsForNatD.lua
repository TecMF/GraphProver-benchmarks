-------------------------------------------------------------------------------
--   Constants for Natural Deduction Module
--
--   Contains all the constants used by the Natural Deduction Logic Module.
--
--   @authors: Vitor, Jefferson, Bernardo
--
-------------------------------------------------------------------------------

-- Operators definitions
opAnd = {}
opAnd.tex = '\\land'
opAnd.print = '&'
opAnd.graph = "and"

opOr = {}
opOr.tex = '\\lor' 
opOr.print = '|'
opOr.graph = "or"

opImp = {}
opImp.tex = '\\to'
opImp.print = '->'
opImp.graph = "imp"

opNot = {}
opNot.tex = '\\neg'
opNot.print = '~'
opNot.graph = "not"

lblBot = {}
lblBot.tex = '\\bot'
lblBot.print = 'Bottom'
lblBot.graph = "bot"

operators = {} -- Tabela que contém todos os operadores
operators[1] = opAnd
operators[2] = opOr
operators[3] = opImp
operators[4] = opNot

-- Labels for graph definitions
lblRootEdge = "root"
lblEdgeEsq = "left"
lblEdgeDir = "right"
lblEdgeDeduction = "DED"
lblEdgeImpIntro = "impIntro"
lblEdgeImpElim = "impElim"
lblEdgeHypothesis = "hyp"
lblEdgePredicate = "pred"
lblEdgeGoal = "Goal"
lblEdgeCounterModel = "COUNTER"
lblEdgeAccessability = "Access"
lblEdgeSatisfy = "sat"
lblEdgeUnsatisfy = "unsat"
lblFormulaReference = "ref"

lblNodeGG = "GG"
lblNodeEsq = "e"
lblNodeDir = "d"
lblNodeWorld = "w"

lblRuleImpLeft = "REMOVER IMPLY LEFT"
lblRuleImpRight = "REMOVER IMPLY RIGHT"
lblRuleImpIntro = "impIntro"
lblRuleImpElim = "impElim"
lblRuleRestart = "restart"

-- Side definitions
leftSide = "Left"
rightSide = "Right"
