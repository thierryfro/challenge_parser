require 'json'
# Initialize variables to store game data
games = {}
current_game = nil
current_game_kills = {}
current_players = []
current_game_deaths_means = {}

# Read the Quake log file
File.open('qgames.log', 'r') do |file|
  file.each_line do |line|
    # Check for the start of a new game
    if line.include?('InitGame:')
      # If a game is already in progress, save its data
      if current_game
        games[current_game] = {
          'total_kills' => current_game_kills.values.sum,
          'players' => current_players.uniq,
          'kills' => current_game_kills,
          'kills_by_means' => current_game_deaths_means
        }
      end

      # Initialize variables for the new game
      current_game = "game_#{games.length + 1}"
      current_game_kills = {}
      current_players = []
      current_game_deaths_means = {}

    # Check for kill events
    elsif line.include?('Kill:')
      players = line.match(/Kill: \d+ \d+ \d+: (.+) killed (.+) by/)
      killer_name = players[1]
      victim_name = players[2]

      # add the players
      unless killer_name == '<world>'
        current_players << killer_name
        current_players << victim_name

        # Update kill count for the killer
        current_game_kills[killer_name] ||= 0
        current_game_kills[killer_name] += 1

        # add the death means to the report
        killed_way = line.match(/by (.+)/)
        current_game_deaths_means[killed_way[1]] ||= 0
        current_game_deaths_means[killed_way[1]] += 1
      end

      # If the killer's name is "<world>", discount one kill point for the victim kills count
      # Can be negative the value?
      if killer_name == '<world>'
        current_game_kills[victim_name] -= 1 unless current_game_kills[victim_name].nil?
      end

    end
  end
end

# Save the last game's data
if current_game
  games[current_game] = {
    'total_kills' => current_game_kills.values.sum,
    'players' => current_players.uniq,
    'kills' => current_game_kills,
    'kills_by_means' => current_game_deaths_means
  }
end

# Print the game data as JSON
puts games.to_json