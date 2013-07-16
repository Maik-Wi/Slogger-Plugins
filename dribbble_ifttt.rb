=begin
Plugin: Dribbble IFTTT
Description: Brief description (one line)
Author: [Maik W](http://buntepixel.org)
Configuration:
  'ifttt_file_path': 'Apps/ifttt/slogger-temp/dribble'
  'Dribbble_tags': '#social #Dribbble'
Notes:
  - Dribbble txt file
  - This will take a txt file of img url, caption and date posted
=end

require 'fileutils'

config = { # description and a primary key (username, url, etc.) required
  'description' => ['Dribbble txt file',
                    'This will take a txt file of img url, caption and date posted'],
  'ifttt_file_path' => '/home/maik/Dropbox/Apps/slogger-temp/dribbble/',
  'Dribbble_tags' => '#social #Dribbble'
}
# Update the class key to match the unique classname below
$slog.register_plugin({ 'class' => 'Dribbble', 'config' => config })

# unique class name: leave '< Slogger' but change ServiceLogger (e.g. LastFMLogger)
class Dribbble < Slogger
  # every plugin must contain a do_log function which creates a new entry using the DayOne class (example below)
  # @config is available with all of the keys defined in "config" above
  # @timespan and @dayonepath are also available
  # returns: nothing
  def do_log
    if @config.key?(self.class.name)
      config = @config[self.class.name]
      # check for a required key to determine whether setup has been completed or not
      if !config.key?('ifttt_file_path') || config['ifttt_file_path'] == []
        @log.warn("Dribbble has not been configured or an option is invalid, please edit your slogger_config file.")
        return
      else
        # set any local variables as needed
        ifttt_file_path = config['ifttt_file_path']
      end
    else
      @log.warn("Dribbble has not been configured or a feed is invalid, please edit your slogger_config file.")
      return
    end
    @log.info("Logging Dribbble Shots")

    today = @timespan

    # Perform necessary functions to retrieve posts

    # create an options array to pass to 'to_dayone'
    # all options have default fallbacks, so you only need to create the options you want to specify

    #Get the images from the files for Dribbble
    def create_content(file)
      if @config.key?(self.class.name)
        config = @config[self.class.name]
      end
      config['Dribbble_tags'] ||= ''
      @tags = "\n\n#{config['Dribbble_tags']}\n" unless config['Dribbble_tags'] == ''
      file_name = file
      file_read = File.readlines(file_name)
      
      file_read.each do |item|
        item.strip()
      end
      
      #
      #   This is to assume that the file reads like this:
      #   File URL
      #   Dribbble comment
      #   Date posted
      #
      image_url = file_read[0]
      image_caption = file_read[1]
      date_posted = Time.parse(file_read[2])

      options = {}
      options['datestamp'] = date_posted.utc.iso8601
      options['starred'] = false
      options['uuid'] = %x{uuidgen}.gsub(/-/,'').strip
      options['content'] = "## Dribbble Photo\n\n#{image_caption}#{@tags}"
            
      sl = DayOne.new
      sl.save_image(image_url,options['uuid']) if image_url
      sl.to_dayone(options)
    end

    file_path = config['ifttt_file_path']
    
    Dir.glob(file_path + '/*.txt') do |inst_file|
      self.create_content(inst_file)
      unless File.directory?(file_path + '/logged/')
        FileUtils.mkdir_p(file_path + '/logged/')
      end
      FileUtils.mv(inst_file, file_path + '/logged/' + File.basename(inst_file))
    end

  end

end
