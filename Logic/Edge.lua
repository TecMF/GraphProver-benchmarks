------------------------------------------------------------------------------
--   Edge Module
--
--   This module defines ...
--
--   @authors: Vitor
--
-------------------------------------------------------------------------------

Edge = {}

Edge_Metatable = { __index = Edge }

--- Class Constructor
function Edge:new (label, origem, destino)
   assert( getmetatable(origem) == Node_Metatable , "Edge:new expects a Node. Origin is not a node.")
   assert( getmetatable(destino) == Node_Metatable , "Edge:new expects a Node. Destination is not a node.")
   assert( type(label) == "string" , "Edge:new expects a string." )
   
   local ini = {}
   ini = {label = label, origem = origem, destino = destino, info = {}}
   
   local newEdge = setmetatable( ini, Edge_Metatable )
   
   origem:setEdgeOut(newEdge)
   destino:setEdgeIn(newEdge)
   
   return newEdge
end

--- Define the label of the edge
function Edge:setLabel( label )
   assert( type(label) == "string" , "Edge:setLabel expects a string." )
   self.label = label
end

--- Return the label of the edge
function Edge:getLabel()
   return self.label
end

--- Create a field named "infoName" with the value "infoValue". If the field already exists, the value of it is atualized
-- @param infoName: A string or a number containing the name of the field of the desired information.
-- @param infoValue: A value which the field "infoName" will have.
function Edge:setInformation(infoName, infoValue)	
   self.info[infoName] = infoValue
end

--- Retorna o valor da informaçao do campo infoName
-- @param infoName: A string or a number containing the name of the field of the desired information.
function Edge:getInformation(infoName)
   return self.info[infoName]
end

function Edge:getInformationTable()
   return self.info
end

--- Return the origin node of the edge
function Edge:getOrigem()
   return self.origem
end

--- Define the origin node of the edge
function Edge:setOrigem(node)
   assert( getmetatable(node) == Node_Metatable , "Edge:setOrigem expects a Node.") -- Garantir que é um vertice
   
   self.origem = node
end

--- Return the destination node of the edge
function Edge:getDestino()
   return self.destino
end

--- Define the destination node of the edge
function Edge:setDestino(node)
   assert( getmetatable(node) == Node_Metatable , "Edge:setDestino expects a Node.") -- Garantir que é um vertice
   self.destino = node
end

--- Define the origin node and the destination node of the edge
-- @param origin: A node that is the origin of the edge
-- @param destination: A node that is the destination of the edge 
function Edge:setConections(origin, destination)
   assert( getmetatable(origin) == Node_Metatable , "Edge:setConections expects a Node, origin is not a node.") -- Garantir que é um vertice
   assert( getmetatable(destination) == Node_Metatable , "Edge:setConections expects a Node, destination is not a node.") -- Garantir que é um vertice
   self.origem = origin
   self.destino = destination
end

-- Return two nodes: the origin and the destination of the edge
function Edge:getConections()
   return self.origem, self.destino
end

