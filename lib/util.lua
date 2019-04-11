
--- Split a string
--
--
local function split(inputstr, sep)
   if inputstr == nil then
      return {}
   end
   if sep == nil then
      sep = "%s"
   end
   local t={} ; i=1
   for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
      t[i] = str
      i = i + 1
   end
   return t
end

--- Match version strings
--
--
local function match_version(vers, check, oper)
   local vers_split  = split(vers,  ".")
   local check_split = split(check, ".")
   
   -- Operators: =, <=, >=, <, and >
   local function op_eq(v, c)
      return v == c
   end
   
   local function op_leq(v, c)
      return v <= c
   end
   
   local function op_geq(v, c)
      return v >= c
   end
   
   local function op_gt(v, c)
      return v > c
   end
   
   local function op_lt(v, c)
      return v < c
   end

   local op_table = {
      ["="]  = op_eq,
      ["<="] = op_leq,
      [">="] = op_geq,
      ["<"]  = op_lt,
      [">"]  = op_gt,
   }

   local match = false
   for i=1, #vers_split do
      local last = (i == #vers_split or i == #check_split)
      local v = vers_split[i]
      local c = check_split[i]

      local match_eq   = op_table["="](v, c)
      local match_oper = op_table[oper](v, c)
      
      if last then
         match = match_oper
      else
         match = match_oper or match_equal
      end

      if not match then
         break
      end
   end

   return match
end

local M = {} 

M.split         = split
M.match_version = match_version

return M
