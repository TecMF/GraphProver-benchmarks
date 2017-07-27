-------------------------------------------------------------------------------
--   This module defines the Set structure.
--
--   @author: Jefferson
-------------------------------------------------------------------------------


Set = {}

Set_Metatable = { __index = Set }

function Set:new (t)
   local ini = {}

   if t ~= nil then
      for _,v in pairs(t) do ini[v] = true end
   end

   return setmetatable( ini, Set_Metatable )
end

function Set:contains(e)
   return self[e]
end

function Set:add(e)
   self[e] = true
end

function Set:union(set2)
   local s = Set:new()

   for k, _ in pairs(self) do 
      s[k] = true
   end

   for k, _ in pairs(set2) do 
      s[k] = true
   end

   return s
end
