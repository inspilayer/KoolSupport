-- Portable Lua 5.3/5.4 syntax checker; does not execute addon source.
for i=1,#arg do
  local chunk,why=loadfile(arg[i])
  if not chunk then io.stderr:write(tostring(why)..'\n');os.exit(1) end
end
print('PASS Lua syntax for '..#arg..' files')
