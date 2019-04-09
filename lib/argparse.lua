local argparse = assert(require "argparse")

local version = assert(require "lib.version")
local ftable  = assert(require "lib.ftable")

local M = {}

local function create(description)
   -- Some general arguments
   local parser = argparse("lslurmes", version.get_description().script_name)
   
   -- General stuff
   parser:group("General options",
      parser:flag("--dry"  , "do not submit but just print script to terminal"),
      parser:flag("--debug", "print debug information (mostly for developers)"),
      parser:flag("--quiet", "do not print anything to stdout"),
      parser:option("--format", "set printout format", "fancy"),
      parser:option("--submit-name", "set submit file name", "submit.sh"),
      parser:flag("-v --version", "print '" .. version.get_version() .. "' and exit"):action(function()
         print(version.get_version())
         os.exit(0)
      end)
   )

   -- Run-time
   --parser:group("Run-time options",
   --   parser:option("--precmd"            , "add command before invocation of program (must be surrounded by '')", default=[], action="append")
   --   parser:option("--postcmd"           , "add command after invocation of program (must be surrounded by '')" , default=[], action="append")
   --   parser:option("--no-local-scratch"  , "disable use of node-local scratch directory (not recommended!)", action="store_true")
   --)
   
   -- Slurm stuff
   parser:group("SLURM options",
      --
      parser:option("-t --time"              , "set wall time as HH:MM:SS"    , "8:00:00"),
      parser:option("-q --partition"         , "set queue/partition"          , "q20"),
      parser:option("-j --jobname"           , "set jobname"                  , "myslurmjob"),
      parser:option("-n --nodes"             , "set number of nodes"          , 1),
      parser:option("-np --ntasks-per-node"  , "set number of tasks per node" , 1),
      parser:option("-c --cpus-per-task"     , "set number of cpus per task"  , 1),
      parser:option("--mem"                  , "set memory"                   , ""),
      
      -- mail args
      parser:option("--mail-user", "set user mail"                            , ""),
      parser:option("--mail-type", "set user mail type e.g. ALL, BEGIN, etc." , "ALL")
   )

   return parser
end

local function create_lslurmes_parser(parser, symbtable)
   local ftable_def = {
      add_argument  = 
         function(name, desc) 
            parser:argument(name, desc) 
         end,
   }

   local lslurmes_parser = ftable.create_ftable()
   lslurmes_parser:push(ftable_def)

   return lslurmes_parser
end

M.create = create
M.create_lslurmes_parser = create_lslurmes_parser

return M
