require 'net/http'
require 'json'
require 'uri'
require 'pry-byebug'
require 'getoptlong'

options = [
  { name: '--help', short_name: '-h', arg_flag: GetoptLong::NO_ARGUMENT, desc: 'Print help'},
  { name: '--tabs', short_name: '-t', arg_flag: GetoptLong::NO_ARGUMENT, desc: 'use tab separators (for | pbcopy)'},
  { name: '--urls', short_name: '-u', arg_flag: GetoptLong::NO_ARGUMENT, desc: 'display TMDB url'}
]

def print_usage(options)
  STDERR.puts "\nUsage: #{ARGV[0]} options"
  options.each do |opt|
    STDERR.puts " #{opt[:name]}, #{opt[:short_name]}:"
    STDERR.puts "    #{opt[:desc]}"
  end
  STDERR.puts
end

opts = GetoptLong.new(*options.map { |opt| [ opt[:name], opt[:short_name], opt[:arg_flag] ] })

API_KEY = 'ac3d43316d5ad9b942f18e63be972f19'
BASE_URL = 'https://api.themoviedb.org/3'

tabs = false
urls = false

begin
  opts.each do |opt, arg|
    case opt
    when '--tabs'
      tabs = true
    when '--urls'
      urls = true
    when '--help'
      print_usage(options)
      exit
    end
  end
rescue
  print_usage(options)
  exit 1
end

movies = STDIN.readlines(chomp: true)

def get_year_from(title)
  title[/(?<=\[).*?(?=\])/]
end


def get_movie_data(title_info)
  year = get_year_from(title_info)
  title = title_info.sub("[#{year}]", '').strip

  uri = URI("#{BASE_URL}/search/movie")
  params = { api_key: API_KEY, query: title, year: year }
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
