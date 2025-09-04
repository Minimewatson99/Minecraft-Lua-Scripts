-- Prints the public IP address using the ComputerCraft http API.

-- Make a GET request to icanhazip.com
local response = http.get("http://icanhazip.com")

if response then
  -- Read the entire response body
  local ip = response.readAll()
  response.close()
  
  -- The response includes a trailing newline, so we trim whitespace before printing.
  print(ip:match('^%s*(.-)%s*$'))
else
  print("Error: HTTP request failed.")
end
