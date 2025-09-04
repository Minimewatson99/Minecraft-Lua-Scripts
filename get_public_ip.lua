-- Prints the public IP address by calling an external service.
-- Requires 'powershell' to be available in the system's PATH.

local command = 'powershell -NoProfile -Command "Invoke-RestMethod http://icanhazip.com"'
local handle = io.popen(command)
if handle then
  local ip = handle:read('*a')
  handle:close()
  -- Trim leading/trailing whitespace (including newlines) from the output
  print(ip:match('^%s*(.-)%s*$'))
else
  print("Error: Could not execute command. Is PowerShell available in your PATH?")
end
