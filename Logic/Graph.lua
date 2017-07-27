-------------------------------------------------------------------------------
--   This module defines the graph structure.
--
--   @author: Vitor
--   @author: Hermann
-------------------------------------------------------------------------------

require 'Logic/Node'
require 'Logic/Edge'


Graph = {}

Graph_Metatable = { __index = Graph }

--- Graph constructor
function Graph:new ()
   return setmetatable( {}, Graph_Metatable )
end

--- This function is used only in the Graph module
-- @param listOfObj A list of objects that are nodes or edges.
-- @param newElement An object that is a edge or a node.
-- @return true if the label of the newElement do not exist in any of the
--         objects within the listOfObj and false otherwise.
local function verifyLabel(listOfObj, newElement)
   assert( (getmetatable(newElement) == Edge_Metatable) or (getmetatable(newElement) == Node_Metatable), "verifyLabel expects a edge or a node.")
   for i=1, #listOfObj do
      if listOfObj[i]:getLabel() == newElement:getLabel() then
	 return false
      end
   end
   return true
end

--- This function is used only in the Graph module
-- @param listOfObj A list of objects that are nodes.
-- @param element An object that is a node.
-- @return true if the label ofelement is the label of some member of lisstOfObj
--         and false otherwise.
local function membership(element, listOfObj)
   assert(getmetatable(element) == Node_Metatable, "membership expects a node.")
   local r = false
   for i=1, #listOfObj do
      if listOfObj[i]:getLabel() == element:getLabel() then
         r = true
      end
   end
   return r
end

--- Sets the root of the Graph
-- @param node A node of the graph.
function Graph:setRoot( node )
   -- Verifica se o vertice raiz já existe no grafo (tem que existir) 
   for i=1, #self.nodes do
      assert( membership(node, self.nodes), "There is no vertex labeled as \""..node:getLabel().."\" in the graph")
   end
   if self.root == nil then
      self.root = node
   end
end

--- Adds a list of nodes in the graph
-- @param nodes Uma lista contendo todos os vertices que serão adicionados
function Graph:addNodes( nodes )

   if self.nodes == nil then
      self.nodes = {}
   end

   local posInicial = #self.nodes
   local j=1
   for i=1, #nodes do
      assert( getmetatable(nodes[i]) == Node_Metatable , "Graph:addNodes expects a Node")                 
      if not membership(nodes[i], self.nodes) then 
         self.nodes[posInicial + j] = nodes[i]
         j=j+1
      end
   end
end

--- Adds a node in the graph
-- @param node O vertice que será adicionado
function Graph:addNode( node )

   assert( getmetatable(node) == Node_Metatable , "Graph:addNode expects a Node") -- Garantir que é um vertice
   
   if self.nodes == nil then
      self.nodes = {}
   end
   
   self.nodes[#self.nodes+1] = node
end

--- Returns the list of the nodes.
function Graph:getNodes()
   return self.nodes
end

--- Returns the node with the specific label.
-- @param label O string contendo o label do vertice desejado 
function Graph:getNode(label)	
   assert( type(label) == "string", "Graph:getNode expects a string" )
   
   if self.nodes == nil then
      return nil
   end
   
   for i=1, #self.nodes do	
      if self.nodes[i]:getLabel() == label then
         return self.nodes[i]
      end
   end
end

--- Returns the list of the edges.
function Graph:getEdges()
   return self.edges
end

--- Returns the edge with a specific label
-- @param label A string with the label of the desired edge
function Graph:getEdge(label)
   assert( type(label) == "string", "Graph:getEdge expects a string" )
   
   if self.edges == nil then
      return nil
   end
   
   for i=1, #self.edges do	
      if self.edges[i]:getLabel() == label then
         return self.edges[i]
      end
   end
end

---  Adds a list of edges in the graph.
-- @param edges A list of edges
function Graph:addEdges(edges)

   if self.edges == nil then
      self.edges = {}
   end
   
   posInicial = #self.edges
   for i=1, #edges do
      assert( getmetatable(edges[i]) == Edge_Metatable , "Graph:addEdges expects an edge")
      self.edges[posInicial + i] = edges[i]
   end
end

--- Adds an edge in the graph.
-- @param edge: An edge
function Graph:addEdge(edge)

   assert( getmetatable(edge) == Edge_Metatable , "Graph:addEdge expects a edge")
   
   if self.edges == nil then
      self.edges = {}
   end
   self.edges[#self.edges +1] = edge
end

--- Removes an edge from the graph.
-- @param The edge that you want to delete from the graph.
-- @return true, if the edge was deleted.
--         false, if the edge was not found, so it was not deleted.
function Graph:removeEdge(edge)
   assert( getmetatable(edge) == Edge_Metatable , "Graph:removeEdge expects a edge")
   
   -- atualizar lista de arestas do grafo
   edges = self:getEdges()
   
   local isEdgeDeleted = false
   local positionOfTheEdge = nil
   local numEdges = #edges
   for i=1, numEdges do
      if edges[i]:getOrigem():getLabel() == edge:getOrigem():getLabel() and edges[i]:getDestino():getLabel() == edge:getDestino():getLabel()then
         
         edges[i] = nil			
         isEdgeDeleted = true
         positionOfTheEdge = i			
         
         for j = positionOfTheEdge, numEdges do
            if j+1 > numEdges then
               break
            end
            
            edges[j] = edges[j+1]
            edges[j+1] = nil							
         end
         
         local origem = edge:getOrigem()
         origem:deleteEdgeOut(edge)
         
         local destino = edge:getDestino()
         destino:deleteEdgeIn(edge)					
         
         break
      end
   end
   
   return isEdgeDeleted
end

--- Removes a node from the graph
-- @param node The node to be removed
function Graph:removeNode(node)
   assert( getmetatable(node) == Node_Metatable , "Graph:removeNode expects a Node")
   
   local nodeList = self:getNodes()
   if nodeList == nil then
      return false
   end
   
   local numNodes = #nodeList	
   
   local isNodeDeleted = false
   for i=1, numNodes do
      if nodeList[i]:getLabel() == node:getLabel() then
         
         local edgesIn = nodeList[i]:getEdgesIn()
         local tamEdgesIn = #edgesIn
         for j=1, tamEdgesIn do
            self:removeEdge(edgesIn[j])
         end			
         
         local edgesOut = nodeList[i]:getEdgesOut()
         local tamEdgesOut = #edgesOut
         for j=1, tamEdgesOut do
            self:removeEdge(edgesOut[j])
         end			
         
         nodeList[i] = nil
         isNodeDeleted = true
         
         for j = i, numNodes do
            if j+1 > numNodes then	
               break
            end
            
            nodeList[j] = nodeList[j+1]
            nodeList[j+1] = nil							
         end
         break
      end
   end
   
   return isNodeDeleted
end

