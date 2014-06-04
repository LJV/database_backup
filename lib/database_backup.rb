# Note: 
# Some of this backup code was originally inspired and copied from a rake task written by
# Craig Ambrose: http://www.craigambrose.com/blog/2007/03/01/a-rake-task-for-database-backups/

require 'fileutils'
require 'escape'

module LJV
  class DatabaseBackup

    def initialize(config)
      @db_name = config[:db_name] || (raise StandardError, "You must specify a database")
      @db_username = config[:db_username] || (raise StandardError, "You must specify a database username")
      @db_password = config[:db_password] || (raise StandardError, "You must specify a database password")
      @backup_dir = config[:backup_dir] || (raise StandardError, "You must specify a backup dir")
      @num_backups = config[:num_backups] || 2
    end

    def backup!
      FileUtils.mkdir_p(@backup_dir)
      `mysqldump -u #{@db_username} -p#{Escape.shell_single_word(@db_password)} -Q --add-drop-table --add-locks=FALSE --single-transaction --skip-lock-tables #{@db_name} | gzip -c > #{backup_filepath}`
      return backup_filepath
    end

    def cleanup!
      dir = Dir.new(@backup_dir)
      all_backups = dir.entries.sort[2..-1].reverse
      unwanted_backups = all_backups[@num_backups..-1] || []
      unwanted_backups.each do |ub|
        FileUtils.rm_rf(File.join(@backup_dir, ub))
      end
      return {:deleted_backups => unwanted_backups.length, :remaining_backups => all_backups.length - unwanted_backups.length}
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