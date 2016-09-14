#!/usr/bin/env ruby

require 'optparse'
require 'fileutils'
require 'pp'
require 'find'
require 'wpcli'
require 'uri'
require 'highline/import'

class WPParser

	Version = 0.1

	def self.parse(args)
		# The options specified on the command line will be collected in *options*.
		# We set default values here.
		options = {
			target: './',
			update: 'false',
		}

		opts = OptionParser.new do |opts|
			opts.banner = "Usage: #$0 [options]"
			opts.separator ""
			opts.separator "Specific options:"

			# Cast 'target dir' argument to a  object.
			opts.on("-t", "--target TARGET", "Path to begin searching from") do |target| 
				options[:target] = target
			end

			# Boolean Switch for the "Update" variable
			opts.on("-u", "--update-all", "Trigger Cron") do |u|
				options[:update] = u
			end

			# Boolean switch.
			opts.on("-v", "--[no-]verbose", "Run verbosely") do |v|
				options[:verbose] = v
			end

			opts.separator ""
			opts.separator "Common options:"

			# No argument, shows at tail.  This will print an options summary.
			opts.on_tail("-h", "--help", "Show this message") do
				puts opts
				exit
			end

			opts.on_tail("-V", "--version", "Show version") do
				puts Version
				exit
			end
		end

		opts.parse!
		options

	end  # parse
end  # class OptionParser

class Iterator

	def initialize(options)
		@options = options 
		@target = @options[:target]
	end


	def wp_found(options)
		begin
			puts "Hello, #{@options[:target]} shall be searched to find WP installations..."
			Dir.chdir(@target)
			wpconfigs = Array.new()
			Find.find(@options[:target]) do |path|
				wpconfigs << path if path =~ /\/(wp|local)\-config\.php$/
			end

			wpconfigs.each do |file|
				if file =~ /(bak|repo|archive|backup|safe|db|html\w|html\.)/
					next	
				end
				@wpcli = Wpcli::Client.new File.dirname(file)
				puts "Will trigger wp_cron for..." 

				ugly_site_name = @wpcli.run "option get siteurl --allow-root"
				site_name = ugly_site_name.to_s.match(URI.regexp).to_s.sub(/^https?\:\/\//, '').sub(/^www./,'')
				puts site_name

				puts @options[:update]

				if @options[:update] == true
					exit unless HighLine.agree('This will attempt to run any scheduled crons that are due now')
					puts doing_cron()
				end
			end
		rescue => e
			puts e
		end
	end

	def doing_cron()
		begin
			@wpcli.run "cron event run --due-now"
		rescue => e
			puts e
		end
	end
end # class Iterator


### EXECUTE ###
begin
	options = WPParser.parse(ARGV)

	if options[:verbose]
		pp options 
	else	
		options
	end

	Iterator.new(options).wp_found(options)

rescue => e
	puts e
end


