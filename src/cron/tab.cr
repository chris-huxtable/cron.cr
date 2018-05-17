# Copyright (c) 2018 Christian Huxtable <chris@huxtable.ca>.
#
# Permission to use, copy, modify, and/or distribute this software for any
# purpose with or without fee is hereby granted, provided that the above
# copyright notice and this permission notice appear in all copies.
#
# THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
# WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
# MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
# ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
# WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
# ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
# OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.

require "user_group"
require "file_atomic_write"


class Cron::Tab

	ROOT = "/var/cron/tabs/"

	@dirty_flag : Bool = false
	@lines : Array(String)
	@path : String


	# MARK: - Initializer

	protected def initialize(@path : String)
		@lines = Array(String).new()
		reset()
		mark_clean()
	end


	# MARK: - Factories

	def self.new(user : System::User) : Tab?
		return new(ROOT + user.name)
	end

	def self.new(path : String) : Tab?
		path = File.expand_path(path)
		return nil if ( !File.exists?(path) )
		return nil if ( !File.file?(path) )

		instance = self.allocate
		instance.initialize(path)
		return instance
	end

	def self.new!(value : String|System::User) : Tab
		tmp = new(value)
		return tmp if ( tmp )
		raise NotFoundError.new(value.to_s)
	end


	# MARK: - Task Management

	def add_task(tag : String, task : Task)
		@lines << task.to_s(tag)

		mark_dirty()
		return true
	end

	def replace_task(tag : String, task : Task) : Bool
		found = map_tagged(tag) { |line|
			task.to_s(tag)
		}
		return true if ( found )
		return add_task(tag, task)
	end

	def remove_task(tag : String) : Bool
		tag = Tab.tag_comment(tag)
		success_flag = false

		@lines.reject!() { |line|
			next false if ( line.empty?() )
			next false if ( !line.ends_with?(tag) )

			mark_dirty()
			success_flag = true
			next true
		}

		return success_flag
	end

	def enable_task(tag : String) : Bool
		return map_tagged(tag) { |line|
			next if ( !line.starts_with?('#') )
			line = line.lchop()
			next line.lstrip()
		}
	end

	def disable_task(tag : String) : Bool
		return map_tagged(tag) { |line|
			next if ( line.starts_with?('#') )
			next "# " + line
		}
	end


	# MARK: - Tags

	def self.tag_valid?(tag : String) : Bool
		return false if ( !tag )
		return false if ( tag.empty? )

		tag.each_char() { |char|
			next if ( char.alphanumeric?() || char == '.' )
			return false
		}

		return true
	end

	def self.tag_valid!(tag : String) : String
		return tag if ( tag_valid?(tag) )
		raise MalformedTagError.new(tag)
	end

	def self.tag_comment(tag : String) : String
		return String.build() { |io| tag_comment(tag, io) }
	end

	def self.tag_comment(tag : String, io : IO) : Nil
		Tab.tag_valid!(tag)
		io << "# tagged: " << tag
	end


	# MARK: - IO

	def write(path : String = @path) : Bool
		return false if ( !dirty?() && path == @path )

		File.atomic_write(path) { |fd| to_s(fd) }
		mark_clean()

		return true
	end

	def reset() : Nil
		@lines.clear

		read_file() { |fd|
			fd.each_line() { |line| @lines << line.rstrip }
		}
		mark_clean()
	end


	# MARK: - Stringification

	def to_s(io : IO)
		@lines.each() { |line| io << line << "\n" }
	end


	# MARK: - Utilities

	protected def read_file(&block : IO::FileDescriptor -> Nil) : Nil
		check_file_exists()
		File.open(@path, "r") { |fd| yield(fd) }
	end

	protected def check_file_exists() : Nil
		raise NotFoundError.new() if ( !File.exists?(@path) )
		raise NotFoundError.new() if ( !File.file?(@path) )
	end

	protected def map_tagged(tag : String, &block) : Bool
		Tab.tag_valid!(tag)
		tag = Tab.tag_comment(tag)
		matches_found = false
		remove = Array(Int32).new()

		@lines.map_with_index!() { |line, idx|
			next line if ( line.empty?() )
			next line if ( !line.ends_with?(tag) )

			matches_found = true if ( !matches_found )
			new_line = yield(line, tag)

			if ( !new_line )
				remove << idx
				mark_dirty()
				next line
			end

			next line if ( line == new_line )
			mark_dirty()
			next new_line
		}

		# Cleanup
		remove.each() { |idx| @lines.delete_at(idx, 1) }

		return matches_found
	end

	protected def mark_dirty() : Nil
		@dirty_flag = true if ( !@dirty_flag )
	end

	protected def mark_clean() : Nil
		@dirty_flag = false if ( @dirty_flag )
	end

	protected def dirty?() : Bool
		return @dirty_flag
	end


	# MARK: - Errors

	class NotFoundError < Exception
		def self.new(name : String)
			super("Crontab for #{name.inspect}, not found.")
		end
	end

	class MalformedTagError < Exception
		def self.new(was : String)
			super("Malformed tag - was: #{was.inspect}.")
		end
	end

end
