require 'net/http'
require 'json'
require 'uri'
require 'pry-byebug'

API_KEY = 'ac3d43316d5ad9b942f18e63be972f19'
BASE_URL = 'https://api.themoviedb.org/3'

movies = STDIN.readlines(chomp: true)
tabs = ARGV.include?('-t')
urls = ARGV.include?('-u')

def get_year_from(title)
  title[/(?<=\[).*?(?=\])/]
end


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
  urls = opts[:urls]

  space_format = "%-50s %-10s %-10s"
  space_format += " %s" if urls
  output_format = space_format

  if tabs
    tab_format = "%s\t%s\t%s"
    tab_format += "\t%s" if urls
    output_format = tab_format
  end

  if entry.empty?
    return output_format % ["Title", "Year", "TMDB ID", "TMDB URL"]
  end

  output_format % [entry[:title], entry[:release_year], entry[:tmdb_id], entry[:tmdb_url]]
end

movie_data_list = movies.map { |movie| get_movie_data(movie) }

# Print as a table
puts table_entry({}, header: true, tabs: tabs, urls: urls)
movie_data_list.each do |data|
  puts table_entry(data, tabs: tabs, urls: urls)
end
