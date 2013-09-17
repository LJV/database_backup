module LJV
  class DatabaseBackup

    def initialize(config)
      @db_name = config[:db_name] || raise StandardError, "You must specify a database"
      @db_username = config[:db_username] || raise StandardError, "You must specify a database username"
      @db_password = config[:db_password] || raise StandardError, "You must specify a database password"
      @backup_dir = config[:backup_dir] || raise StandardError, "You must specify a backup dir"
      @num_backups = config[:num_backups] || 2
    end

    def backup!
      FileUtils.mkdir_p(backup_folder)
      `mysqldump -u #{@db_username} -p#{@db_password} -Q --add-drop-table --add-locks=FALSE --single-transaction --skip-lock-tables #{@db_name} | gzip -c > #{backup_filepath}`
      puts "Created backup: #{backup_filepath}"
      return backup_filepath
    end

    def cleanup!
      dir = Dir.new(@backup_dir)
      all_backups = dir.entries.sort[2..-1].reverse
      unwanted_backups = all_backups[@num_backups..-1] || []
      unwanted_backups.each do |ub|
        FileUtils.rm_rf(File.join(backup_base, ub))
        puts "Deleted #{ub}" 
      end
      puts "Deleted #{unwanted_backups.length} backups, #{all_backups.length - unwanted_backups.length} backups available" 
    end

    private

      def datestamp
        @datestamp ||= Time.now.strftime("%Y-%m-%d_%H%M%S")
      end

      def backup_filename
        "database_dump_#{datestamp}.sql.gz"
      end

      def backup_filepath
        File.join(@backup_dir, backup_filename)
      end
  end
end