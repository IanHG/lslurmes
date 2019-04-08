local class   = assert(require "lib.class")
local symbtab = assert(require "lib.symbtab")

local batchwriter_class = class.create_class()

function batchwriter_class:__init()
   self.filepath = "submit.sh"
   self.copy_cmd = "scp"

   self.shebang = "#!/bin/bash"
   
   -- Header
   self.header_cmd = "#SBATCH"
   self.header = {
      "-J                %jobname%           # Job name (you can try to change it).",
      "--partition       %partition%         # Which partition to use.",
      "--time            %timelimit%         # Time limit.",
      "--nodes           %nodes%             # The number of nodes to allocate.",
      "--ntasks-per-node %tasks_per_node%    # The number of tasks to run on each node.",
      "--cpus-per-task   %cpus_per_task%     # The number of cpus per task (threading).",
   }

   -- Setup
   self.setup = {
      "# Set scratch",
      "SCRATCH=/scratch/$SLURM_JOBID",
   }

   -- Files to copy to scratch (table with src and dest)
   self.files_to_copy      = {}
   self.files_to_copy_back = {}
   
   -- Commands to run
   self.commands           = {}
   
   -- Setup symbol table
   self.symbtab = symbtab.create()
   self.symbtab:add_symbol("jobname",        "default")
   self.symbtab:add_symbol("partition",      "default_partition")
   self.symbtab:add_symbol("timelimit",      "1:00:00")
   self.symbtab:add_symbol("nodes",          "1")
   self.symbtab:add_symbol("tasks_per_node", "1")
   self.symbtab:add_symbol("cpus_per_task",  "1")
end

function batchwriter_class:add_file_to_copy(src, dest)
   table.insert(self.files_to_copy, {src = src, dest = dest })
end

function batchwriter_class:add_file_to_copy_back(src, dest)
   table.insert(self.files_to_copy_back, {src = src, dest = dest})
end

function batchwriter_class:add_command(cmd)
   table.insert(self.commands, cmd)
end

function batchwriter_class:write()
   file = io.open(self.filepath, "w")
   
   file:write(self.shebang .. "\n")

   -- Write header
   for k,v in pairs(self.header) do
      file:write(self.header_cmd .. " " .. self.symbtab:substitute(v) .. "\n")
   end
   file:write("\n")
   file:write("echo \"========= Job started  at `date` ==========\"\n")
   file:write("\n")
    
   -- Setup
   for k, v in pairs(self.setup) do
      file:write(v .. "\n")
   end
   file:write("\n")

   -- Copy files
   file:write("# Copy data to nodes\n")
   for k,v in pairs(self.files_to_copy) do
      file:write(self.copy_cmd .. " " .. v.src .. " " .. v.dest .. "\n")
   end
   file:write("\n")

   -- Commands
   file:write("# Run commands\n")
   for k,v in pairs(self.commands) do
      file:write(v .. "\n")
   end
   file:write("\n")

   -- Copy back
   file:write("# Copy data from nodes\n")
   for k,v in pairs(self.files_to_copy_back) do
      file:write(self.copy_cmd .. " " .. v.src .. " " .. v.dest .. "\n")
   end
   file:write("\n")

   file:write("echo \"========= Job finished at `date` ==========\"\n")

   file:close()
end

local M = {}

local function create(...)
   local  bw = batchwriter_class:create(...)
   return bw
end

M.create = create

return M
