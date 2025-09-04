-- Prints the public IP address by calling an external service.
-- Requires 'curl' to be installed and in the system's PATH.

local handle = io.popen('curl -s icanhazip.com')
if handle then
  local ip = handle:read('*a')
  handle:close()
  -- Trim leading/trailing whitespace (including newlines) from the output
  print(ip:match('^%s*(.-)%s*$'))
end
