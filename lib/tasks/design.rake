## Design rake tasks
require 'aws-sdk'
require 'yaml'
require 'pathname'

namespace :design do

  desc "Post updated designs to S3"
  task :update => :environment do

    s3 = AWS::S3.new

    Rails.application.config.s3[:designs].each { | key, val |

      if s3.buckets[Rails.application.config.s3[:bucket_name][key]].exists?
        puts "update for #{key}"
        #Rake::Task['design:empty_bucket'].invoke( key )
        Rake::Task['design:populate_bucket'].invoke( key )
      else
        Rake::Task['design:create_bucket'].invoke( key )
        #Rake::Task['design:populate_bucket'].invoke( key )
      end

    }

  end

  desc "Create S3 buckets"
  task :create_bucket, :design_name do |t, args|

    s3 = AWS::S3.new

    if args[:design_name]
      puts "Creating #{args[:design_name]} @ #{ Rails.application.config.s3[:bucket_name][args[:design_name]] }"
      bucket = s3.buckets.create( Rails.application.config.s3[:bucket_name][args[:design_name]], :acl => :public_read )
      bucket.configure_website do |cfg|
        cfg.index_document_suffix = 'index.html'
        cfg.error_document_key = 'error.html'
      end
    end

  end

  desc "Populate S3 buckets"
  task :populate_bucket, :design_name do |t, args|

    s3 = AWS::S3.new
    current_bucket = s3.buckets[ args[:design_name] ]
    puts "current_bucket #{current_bucket}"

    if args[:design_name]

      puts "Populating #{ Rails.application.config.s3[:bucket_name][args[:design_name]] }"
      root = File.join( Dir.pwd, Rails.application.config.s3[:path][args[:design_name]] )
      puts "root: #{root}"

      path_prefix = root.length

      Dir[root + "*"].each { |f| 
        if File.directory?(f)
          puts "Directory: #{f}"
        elsif File.file?(f)
          puts "File: #{f}"
          puts "Prefix: #{f[ path_prefix .. f.length]}"
          puts "AWS_SECRET_ACCESS_KEY #{ENV['AWS_SECRET_ACCESS_KEY']}"
          puts "AWS_ACCESS_KEY_ID #{ENV['AWS_ACCESS_KEY_ID']}"
          file = File.open( f, 'rb' )
          obj = current_bucket.objects.create( f[ path_prefix .. f.length], file )
          #obj.write( file )
        else
          puts "Neither: #{f}"
        end
      }
      
    end

  end

  desc "Delete required S3 buckets"
  task :delete=> :environment do

    s3 = AWS::S3.new

    Rails.application.config.s3[:designs].each { | key, val |
      puts "Deleting #{ key } @ #{s3.buckets[Rails.application.config.s3[:bucket_name][key]]}"
      if s3.buckets[Rails.application.config.s3[:bucket_name][key]].exists?
        s3.buckets[Rails.application.config.s3[:bucket_name][key]].delete
      end
    }

  end
end
