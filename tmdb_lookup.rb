require 'net/http'
require 'json'
require 'uri'
require 'pry-byebug'


API_KEY = 'ac3d43316d5ad9b942f18e63be972f19'
BASE_URL = 'https://api.themoviedb.org/3'

movies = [
  "Napoleon Dynamite",
  "Narnia 01 - The Lion The Witch and the Wardrobe",
  "Narnia 02 - Prince Caspian",
  "National Treasure",
  "National Treasure 2",
  "National Velvet",
  "Neverending Story, The",
  "Night At the Museum - Battle of the Smithsonian",
  "Nightmare Before Christmas",
  "Noises Off!",
  "Notebook, The",
  "Notting Hill",
  "Nurse Betty",
  "Ocean's Eleven",
  "Ocean's Twelve",
  "Old Dogs",
  "Pacific Rim",
  "Pain and Gain",
  "Paris, Je T'Aime",
  "Patch Adams",
  "Patriot Games",
  "Patriot, The",
  "Patton",
  "Paycheck",
  "PDQ Bach - Houston, We have a Problem",
  "Pink Panther Strikes Again, The",
  "PoTC 01 - Curse of the Black Pearl",
  "PoTC 02 - Dead Man's Chest",
  "PoTC 03 - At World's End",
  "PoTC 04 - On Stranger Tides",
  "Pride of the Yankees, The",
  "Princess Bride",
  "Public Enemies",
  "Whale Rider",
  "Wizard of Oz, The"
]

def get_movie_data(title)
  uri = URI("#{BASE_URL}/search/movie")
  params = { api_key: API_KEY, query: title }
  uri.query = URI.encode_www_form(params)
  sequence_re = /^\w+\s\d+\s- /

  response = Net::HTTP.get_response(uri)

  unless response.is_a?(Net::HTTPSuccess)
    return { title: title, release_year: 'Error', tmdb_id: 'Error', tmdb_url: 'Error' }
  end

  results = JSON.parse(response.body)['results']
  if results.any?
    movie = results.first
    return {
      title: title,
      release_year: movie['release_date'].to_s.split('-').first,
      tmdb_id: movie['id'],
      tmdb_url: "https://www.themoviedb.org/movie/#{movie['id']}"
    }
  end

  # if we got no results and we have a "sequence" prefix, i.e., "Narnia 01 - "
  # then remove the sequence prefix and have another try
  if title.match(sequence_re)
    adjusted_title = title.sub(sequence_re, '')
    movie_data = get_movie_data(adjusted_title)
    movie_data[:title] = title
    return movie_data
  end

  { title: title, release_year: 'N/A', tmdb_id: 'N/A', tmdb_url: 'N/A' }
end

movie_data_list = movies.map { |movie| get_movie_data(movie) }

# Print as a table
puts "%-50s %-10s %-10s %s" % ["Title", "Year", "TMDB ID", "TMDB URL"]
movie_data_list.each do |data|
  puts "%-50s %-10s %-10s %s" % [data[:title], data[:release_year], data[:tmdb_id], data[:tmdb_url]]
end