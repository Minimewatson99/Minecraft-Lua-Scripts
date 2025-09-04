-- A ComputerCraft script to display the currently playing Spotify track.

-- Use the modern JSON API if available, otherwise fall back to the old one.
local json_decode = textutils.decodeJSON or textutils.unserializeJSON

-- Helper function to format milliseconds into MM:SS format.
local function format_time(ms)
    local total_seconds = math.floor(ms / 1000)
    local minutes = math.floor(total_seconds / 60)
    local seconds = total_seconds % 60
    return string.format("%02d:%02d", minutes, seconds)
end

-- Helper function to join artist names from the artists table.
local function get_artist_names(artists)
    local names = {}
    for i, artist in ipairs(artists) do
        table.insert(names, artist.name)
    end
    return table.concat(names, ", ")
end

local API_URL = "https://mivra.net/api/spotify/now-playing"

print("Starting Spotify Now Playing monitor...")
os.sleep(1)

while true do
    term.clear()
    term.setCursorPos(1, 1)

    -- Make the HTTP GET request.
    local response = http.get(API_URL)
    if not response then
        print("Error: Failed to fetch data from API.")
        os.sleep(5)
        goto continue_loop
    end

    local data_str = response.readAll()
    response.close()

    -- Safely decode the JSON response.
    local ok, data = pcall(json_decode, data_str)
    if not ok or not data then
        print("Error: Failed to parse JSON response.")
        os.sleep(5)
        goto continue_loop
    end

    if data.is_playing and data.item then
        -- Extract data from the response.
        local track_name = data.item.name
        local artists = get_artist_names(data.item.artists)
        local progress_ms = data.progress_ms
        local duration_ms = data.item.duration_ms

        -- Format for display.
        local progress_str = format_time(progress_ms)
        local duration_str = format_time(duration_ms)

        -- Print track info.
        print("Now Playing on Spotify:")
        print("-----------------------")
        print("Track: " .. track_name)
        print("Artist(s): " .. artists)
        print(string.format("\n%s / %s", progress_str, duration_str))

        -- Draw progress bar.
        local term_width, _ = term.getSize()
        local progress_bar_width = term_width - 2 -- for [ and ]
        local progress = progress_ms / duration_ms
        local filled_width = math.floor(progress * progress_bar_width)
        local empty_width = progress_bar_width - filled_width
        
        local progress_bar = "[" .. string.rep("=", filled_width) .. string.rep(" ", empty_width) .. "]"
        print(progress_bar)
    else
        print("Spotify is not currently playing a track.")
    end

    ::continue_loop::
    os.sleep(5) -- Refresh every 5 seconds.
end
