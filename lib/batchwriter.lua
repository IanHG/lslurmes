local class   = assert(require "lib.class")
local symbtab = assert(require "lib.symbtab")
local ftable  = assert(require "lib.ftable")
local path    = assert(require "lib.path")

local batchwriter_class = class.create_class()

function batchwriter_class:__init()
   self.filepath = "%submit_name%"
   self.copy_cmd = "scp"

   self.shebang = "#!/bin/bash"
   
   -- Header
   self.header_cmd = "#SBATCH"
   self.header = {
      "-J                %jobname%           # Job name (you can try to change it).",
      "--partition       %partition%         # Which partition to use.",
      "--time            %time%              # Time limit.",
      "--nodes           %nodes%             # The number of nodes to allocate.",
      "--ntasks-per-node %ntasks_per_node%   # The number of tasks to run on each node.",
      "--cpus-per-task   %cpus_per_task%     # The number of cpus per task (threading).",
   }

   -- Setup
   self.scratch    = "$SCRATCH"
   self.submit_dir = "$SLURM_SUBMIT_DIR"
   self.setup   = {
      "# Set scratch",
      "SCRATCH=/scratch/$SLURM_JOBID",
   }

   -- Files to copy to scratch (table with src and dest)
   self.files_to_copy      = {}
   self.files_to_copy_back = {}
   
   -- Commands to run
   self.commands           = {}
   self.precommands        = {}
   self.postcommands       = {}
   
end

function batchwriter_class:add_file_to_copy(src, dest)
   if dest == nil then
      dest = self.scratch .. "/."
   elseif path.is_rel_path(dest) then
      src = path.join(self.scratch, dest)
   end

   if path.is_rel_path(src) then
      src = path.join(self.submit_dir, src)
   end
   
   table.insert(self.files_to_copy, {src = src, dest = dest })
end

function batchwriter_class:add_file_to_copy_back(src, dest)
   if dest == nil then
      dest = self.submit_dir .. "/."
   elseif path.is_rel_path(dest) then
      src = path.join(self.submit_dir, dest)
   end

   if path.is_rel_path(src) then
      src = path.join(self.scratch, src)
   end

   table.insert(self.files_to_copy_back, {src = src, dest = dest})
end

function batchwriter_class:add_command(cmd, ctype)
   if type(cmd) == "table" then
      local cmd_str = ""
      local first   = true
      for k, v in pairs(cmd) do
         if first then
            cmd_str = v
            first = false
         else
            cmd_str = cmd_str .. " " .. v
         end
      end
      cmd = cmd_str
   end

   if (not ctype) or (ctype == "") or (ctype == "cmd") then
      table.insert(self.commands, cmd)
   elseif ctype == "pre" then
      table.insert(self.precommands, cmd)
   elseif ctype == "post" then
      table.insert(self.postcommands, cmd)
   end
end

function batchwriter_class:write_line(line)
   local subline = self.symbtable:substitute(line)
   if type(self.file.file) == "string" then
      self.file.file = self.file.file .. subline
   elseif type(self.file.file) == "file" then
      self.file.file:write(subline)
   end
end

function batchwriter_class:write(symbtable, file)
   -- Setup
   self.file      = file
   self.symbtable = symbtable
   
   -- Write file
   self:write_line(self.shebang .. "\n")

   -- Write header
   for k,v in pairs(self.header) do
      self:write_line(self.header_cmd .. " " .. v .. "\n")
   end
   self:write_line("\n")
   self:write_line("echo \"========= Job started  at `date` ==========\"\n")
   self:write_line("\n")
    
   -- Setup
   for k, v in pairs(self.setup) do
      self:write_line(v .. "\n")
   end
   self:write_line("\n")

   -- Copy files
   if (#self.files_to_copy > 0) then
      self:write_line("# Copy data to nodes\n")
      for k,v in pairs(self.files_to_copy) do
         self:write_line(self.copy_cmd .. " " .. v.src .. " " .. v.dest .. "\n")
      end
      self:write_line("\n")
   end

   -- Pre commands
   if (#self.precommands > 0) then
      self:write_line("# Pre-commands\n")
      for k,v in pairs(self.precommands) do
         self:write_line(v .. "\n")
      end
      self:write_line("\n")
   end      

   -- Commands
   if (#self.commands > 0) then
      self:write_line("# Run commands\n")
      for k,v in pairs(self.commands) do
         self:write_line(v .. "\n")
      end
      self:write_line("\n")
   end

   -- Post commands
   if (#self.postcommands > 0) then
      self:write_line("# Post-commands\n")
      for k,v in pairs(self.postcommands) do
         self:write_line(v .. "\n")
      end
      self:write_line("\n")
   end

   -- Copy back
   if (#self.files_to_copy_back > 0) then
      self:write_line("# Copy data from nodes\n")
      for k,v in pairs(self.files_to_copy_back) do
         self:write_line(self.copy_cmd .. " " .. v.src .. " " .. v.dest .. "\n")
      end
      self:write_line("\n")
   end

   self:write_line("echo \"========= Job finished at `date` ==========\"\n")
end

--
-- Create module
--
local M = {}

-- Create batchwriter
local function create(...)
   local  bw = batchwriter_class:create(...)
   return bw
end

-- Create batchwriter ftable
local function create_lslurmes_writer(bw)
   local ftable_def = {
      add_command    = function(cmd) bw:add_command(cmd) end,
      copy_file      = function(src, dest) bw:add_file_to_copy     (src, dest) end,
      copy_file_back = function(src, dest) bw:add_file_to_copy_back(src, dest) end
   }
   
   local lslurmes_writer = ftable.create_ftable()
   lslurmes_writer:push(ftable_def)

   return lslurmes_writer
end

-- Export module
M.create                 = create
M.create_lslurmes_writer = create_lslurmes_writer

return M
