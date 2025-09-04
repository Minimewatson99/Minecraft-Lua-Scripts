-- Prints the public IP address by calling an external service.
-- Requires the 'luasocket' library to be installed.

local http = require("socket.http")
local body, status = http.request("http://icanhazip.com")

if body then
  -- Trim leading/trailing whitespace (including newlines) from the output
  print(body:match('^%s*(.-)%s*$'))
else
  print("Error: Could not retrieve public IP address. Details: " .. tostring(status))
end
