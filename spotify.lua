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

-- Helper function to print a line and clear the rest of it.
local function print_line(y, text)
    term.setCursorPos(1, y)
    term.clearLine()
    print(text)
end

-- Function to draw the main "Now Playing" display.
local function draw_now_playing(track_name, artists, progress_ms, duration_ms)
    print_line(1, "Now Playing on Spotify:")
    print_line(2, "-----------------------")
    print_line(3, "Track: " .. track_name)
    print_line(4, "Artist(s): " .. artists)

    local progress_str = format_time(progress_ms)
    local duration_str = format_time(duration_ms)
    print_line(6, string.format("%s / %s", progress_str, duration_str))

    -- Draw progress bar.
    local term_width, _ = term.getSize()
    local progress_bar_width = term_width - 2 -- for [ and ]
    if progress_bar_width < 1 then progress_bar_width = 1 end

    local progress = progress_ms / duration_ms
    local filled_width = math.floor(progress * progress_bar_width)
    if filled_width < 0 then filled_width = 0 end
    if filled_width > progress_bar_width then filled_width = progress_bar_width end

    local empty_width = progress_bar_width - filled_width

    local progress_bar = "[" .. string.rep("=", filled_width) .. string.rep(" ", empty_width) .. "]"
    print_line(7, progress_bar)
end

-- Function to draw a simple message, clearing the screen first.
local function draw_message(message)
    term.clear()
    term.setCursorPos(1, 1)
    print(message)
end

local API_URL = "https://mivra.net/api/spotify/now-playing"
local REFRESH_INTERVAL = 5 -- seconds
local last_fetch_time = 0
local last_data = nil
local last_track_id = nil

print("Starting Spotify Now Playing monitor...")
os.sleep(1)
term.clear()

while true do
    local current_time_ms = os.epoch()

    -- Fetch from API if it's time
    if current_time_ms - last_fetch_time >= REFRESH_INTERVAL * 1000 then
        local response = http.get(API_URL)
        if response then
            local data_str = response.readAll()
            response.close()
            local ok, data = pcall(json_decode, data_str)
            if ok and data then
                last_data = data
            else
                last_data = { error = "Failed to parse JSON response." }
            end
        else
            last_data = { error = "Failed to fetch data from API." }
        end
        last_fetch_time = current_time_ms
    end

    -- Render display
    if not last_data then
        draw_message("Fetching data...")
    elseif last_data.error then
        draw_message("Error: " .. last_data.error)
    elseif last_data.is_playing and last_data.item then
        -- If the track has changed, clear the screen to prevent artifacts from different text lengths
        if last_data.item.id ~= last_track_id then
            term.clear()
            last_track_id = last_data.item.id
        end

        local elapsed_since_fetch_ms = current_time_ms - last_fetch_time
        local current_progress_ms = last_data.progress_ms + elapsed_since_fetch_ms

        if current_progress_ms > last_data.item.duration_ms then
            current_progress_ms = last_data.item.duration_ms
        end

        draw_now_playing(
            last_data.item.name,
            get_artist_names(last_data.item.artists),
            current_progress_ms,
            last_data.item.duration_ms
        )
    else
        -- This covers the "not playing" case
        draw_message("Spotify is not currently playing a track.")
        last_track_id = nil -- Reset track ID when nothing is playing
    end

    os.sleep(1) -- Update screen every second.
end
