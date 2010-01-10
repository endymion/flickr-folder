require 'uri'
require 'net/http'
require 'FileUtils'
require 'flickr_fu'
require 'sqlite3'
require 'sequel'

class FlickrFolder

  attr :config, true
  attr :flickr, true
  
  def initialize(config)
    if !config or
      [:search, :folder, :config].any? {|either| config[either].nil?}
      raise ArgumentError, 'Configuration hash required with :search, :folder and :config parameters.'
    end
    @config = config
    @flickr = Flickr.new(@config[:config])
    data_setup
  end

  def update
    photos = []

    # Count existing photo files to figure out how many new ones are needed.
    return photos.size unless (files_needed_count = @config[:folder][:number] -
      Dir.new(@config[:folder][:path]).entries.size + 3) > 0 # The three is for '.', '..', and '.flickr-folder.db'

    page = 1
    while true do

      # Get a list of matching images from Flikr.
      (unfiltered_photos = (@flickr.photos.search @config[:search].merge({:page => page}))).each do |photo|
      
        # Filter results.
        next unless @config[:filter].nil? or @config[:filter].call(photo)
      
        # Skip known photos.
        cached_photos = @data[:photos]
        next if cached_photos.filter(:id => photo.id).count > 0
      
        puts "New photo: #{photo.id}, \"#{photo.title}\", max #{photo.sizes.last.width.to_s}px wide" if @config[:verbose]

        # Pick the first photo that's above the minimum size, if specified.  Otherwise grab the largest size.
        selected_size = photo.sizes.last
        photo.sizes.each do |size|
          if size.width.to_i > @config[:folder][:minimum_resolution] or
            size.height.to_i > @config[:folder][:minimum_resolution]
            selected_size = size
            break
          end
        end if @config[:folder][:minimum_resolution]

        puts "Downloading size: #{selected_size.width} x #{selected_size.height}" if @config[:verbose]
        url = URI.parse(selected_size.source)
        request = Net::HTTP::Get.new(url.path)
        response = Net::HTTP.start(url.host, url.port) do |http|
          http.request(request)
        end
        format = photo.original_format || (photo.sizes.first.source =~ /\.(\w+)$/; $1)
        open(File.join(@config[:folder][:path], "#{photo.id}.#{format}"), "wb") do |file|
            file.write(response.body)
        end

        photos << photo
        cached_photos.insert(:id => photo.id)      

        puts "Size: #{photos.size}"
        return photos.size if photos.size >= files_needed_count
        
      end

      page += 1
            
    end

  end

  private
  
  def data_path
    File.join(@config[:folder][:path], '.flickr-folder.db')
  end
  
  def data_setup
    create_table = false
    unless File.file?(data_path)
      FileUtils::mkpath(@config[:folder][:path])
      SQLite3::Database.new(data_path)
      create_table = true
    end
    @data = Sequel.sqlite(data_path)
    @data.create_table :photos do
      primary_key :id
    end if create_table    
  end

end
