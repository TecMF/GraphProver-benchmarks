#!/usr/bin/env lua
local arg = arg
local assert = assert
local io = io
local ipairs = ipairs
local math = math
local os = os
local pairs = pairs
local print = print
local table = table
local tonumber = tonumber
local tostring = tostring

require'Logic.Graph'
local Graph = assert (Graph)
local Node = assert (Node)
local Edge = assert (Edge)

_ENV = nil

local function usage ()
   io.stderr:write (('usage: %s [-d] NUM_V NUM_E X\n'):format (arg[0]))
   os.exit (1)
end

local NUM_V
local NUM_E
local X
local DEBUG = false
do
   if #arg < 3 or #arg > 4 then
      usage ()
   end
   if arg[1] == '-d' then
      DEBUG = true
      table.remove (arg, 1)
   end
   NUM_V = tonumber (arg[1])
   assert (NUM_V and NUM_V > 0, 'bad NUM_V')
   NUM_E = tonumber (arg[2])
   assert (NUM_E and NUM_E > 0, 'bad NUM_E')
   X = tonumber (arg[3])
   assert (X and X >= 0. and X <= 1., 'bad X')
   math.randomseed (os.time ())
end

local function dump (G)
   local nodes = G:getNodes ()
   local edges = G:getEdges () or {}
   print (('graph %s: %d vertices, %d edges')
         :format (tostring (G), #nodes, #edges))
   for _,e in ipairs (edges) do
      print (('  %s:(%s,%s)'):format
         (tostring (e),
          e:getOrigem ():getLabel (),
          e:getDestino ():getLabel ()))
   end
end

local function add_random_nodes (G, n)
   local nodes = G:getNodes () or {}
   local vcount = #nodes
   for i=1,n do
      nodes[#nodes+1] = Node:new (tostring (vcount + i), 0, 0)
   end
   G:addNodes (nodes)
end

local function add_random_edges (G, n)
   local nodes = G:getNodes ()
   local edges = {}
   for i=1,n do
      local from = nodes[math.random (1,#nodes)]
      local to = nodes[math.random (1,#nodes)]
      edges[#edges+1]=Edge:new (tostring (i), from, to)
   end
   G:addEdges (edges)
end

local function del_random_edges (G, n)
   for i=1,n do
      local edges = G:getEdges () or {}
      local e = edges[math.random (1,#edges)]
      if DEBUG then
         print (('--> delete %s:(%s,%s)')
               :format (tostring (e),
                        e:getOrigem ():getLabel (),
                        e:getDestino ():getLabel ()))
      end
      G:removeEdge (e)
   end
end

local function search_random_edges (G, n)
   local nodes = G:getNodes ()
   local edges = G:getEdges ()
   for i=1,n do
      local from = nodes[math.random (1,#nodes)]
      local to = nodes[math.random (1,#nodes)]
      local found = nil
      for _,e in ipairs (edges) do
         if e:getOrigem () == from and e:getDestino () == to then
            found = e
            break
         end
      end
      if DEBUG then
         if found then
            print (('--> found %s:(%s,%s)')
                  :format (tostring (found),
                           from:getLabel (),
                           to:getLabel ()))
         else
            print (('--> not found (%s,%s)')
                  :format (from:getLabel (), to:getLabel ()))
         end
      end
   end
end

-- Main.
do
   local G = Graph:new ()
   assert (G)

   add_random_nodes (G, NUM_V)
   add_random_edges (G, NUM_E)
   add_random_nodes (G, NUM_V * X)
   add_random_edges (G, NUM_E * X)

   if DEBUG then
      print'\nInitial graph:'
      dump (G)
   end

   search_random_edges (G, NUM_E * X)
   del_random_edges (G, NUM_E * X)

   if DEBUG then
      print'\nFinal graph:'
      dump (G);
   end
end
