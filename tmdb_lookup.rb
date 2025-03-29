require 'net/http'
require 'json'
require 'uri'
require 'pry-byebug'

API_KEY = 'ac3d43316d5ad9b942f18e63be972f19'
BASE_URL = 'https://api.themoviedb.org/3'

movies = STDIN.readlines(chomp: true)

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

def table_entry(entry, opts)
  tabs = opts[:tabs]

  if entry.empty?
    return "%s\t%s\t%s\t%s" % ["Title", "Year", "TMDB ID", "TMDB URL"] if tabs
    return "%-50s %-10s %-10s %s" % ["Title", "Year", "TMDB ID", "TMDB URL"]
  end

  return "%s\t%s\t%s\t%s" % [entry[:title], entry[:release_year], entry[:tmdb_id], entry[:tmdb_url]] if tabs
  "%-50s %-10s %-10s %s" % [entry[:title], entry[:release_year], entry[:tmdb_id], entry[:tmdb_url]]
end

movie_data_list = movies.map { |movie| get_movie_data(movie) }

# Print as a table
tabs = true
puts table_entry({}, header: true, tabs: tabs)
movie_data_list.each do |data|
  puts table_entry(data, tabs: tabs)
end
