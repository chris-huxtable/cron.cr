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


class Cron::Task

	KEYS = Set.new(%w[@reboot @yearly @annually @monthly @weekly @daily @midnight @hourly])


	# MARK: - Initializer

	def initialize(@command : String, @fields : String|Array(UInt8?), @user : String|System::User|Nil = nil, @enabled : Bool = true)
	end


	# MARK: - Factories

	def self.reboot(command : String, user : String|System::User|Nil = nil)
		return Cron::Task.new(command, "@reboot", user)
	end

	def self.yearly(command : String, user : String|System::User|Nil = nil)
		return Cron::Task.new(command, "@yearly", user)
	end

	def self.monthly(command : String, user : String|System::User|Nil = nil)
		return Cron::Task.new(command, "@monthly", user)
	end

	def self.weekly(command : String, user : String|System::User|Nil = nil)
		return Cron::Task.new(command, "@weekly", user)
	end

	def self.daily(command : String, user : String|System::User|Nil = nil)
		return Cron::Task.new(command, "@daily", user)
	end

	def self.hourly(command : String, user : String|System::User|Nil = nil)
		return Cron::Task.new(command, "@hourly", user)
	end

	def self.task(command : String, minute : Int32? = nil, hour : Int32? = nil, day_of_month : Int32? = nil, month : Int32? = nil, day_of_week : Int32? = nil, user : String|System::User|Nil = nil)
		return Cron::Task.new(command, [minute, hour, day_of_month, month, day_of_week], user)
	end

	def self.new(command : String, fields : String, user : String|System::User|Nil = nil, enabled : Bool = true) : Task
		task = new?(command, fields, user, enabled)
		return task if ( task )
		raise "Failed to create cron task."
	end

	def self.new?(command : String, fields : String, user : String|System::User|Nil = nil, enabled : Bool = true) : Task?
		return nil if ( !command_valid?(command) )

		return nil if ( !fields.starts_with?('@') )
		return nil if ( !KEYS.includes?(fields) )

		user = System::User.get(user) if ( user.is_a?(String) )

		instance = self.allocate
		instance.initialize(command, fields, user, enabled)
		return instance
	end

	def self.new(command : String, fields : Array(Int32?), user : String|System::User|Nil = nil, enabled : Bool = true) : Task
		task = new?(command, fields, user, enabled)
		return task if ( task )
		raise "Failed to create cron task."
	end

	def self.new?(command : String, fields : Array(Int32?), user : String|System::User|Nil = nil, enabled : Bool = true) : Task?
		return nil if ( !command_valid?(command) )

		return nil if ( fields.empty?() )
		return nil if ( fields.size > 5 )
		return nil if ( !fields.find(false) { |elm| next elm} )

		fields = Array(UInt8?).build(5) { |buffer|
			buffer[0] = map_field(fields, 0, 0, 59)
			buffer[1] = map_field(fields, 1, 0, 23)
			buffer[2] = map_field(fields, 2, 1, 31)
			buffer[3] = map_field(fields, 3, 1, 12)
			buffer[4] = map_field(fields, 4, 0, 7)
			next 5
		}

		user = System::User.get(user) if ( user.is_a?(String) )

		instance = self.allocate
		instance.initialize(command, fields, user, enabled)
		return instance
	end

	protected def self.map_field(fields : Array(Int32?), idx : Int, min : Int, max : Int) : UInt8?
		cur = fields[idx]
		return nil if ( !cur )
		return cur.to_u8 if ( cur >= min && cur <= max )
		raise MalformedFieldError.new("Field #{idx} - was: #{cur.inspect}, expected in [#{min}..#{max}]")
	end


	# MARK: - Properties

	getter(command : String)
	getter(fields : String|Array(UInt8?))
	getter(user : System::User|Nil)

	def enabled?()
		return @enabled
	end


	# MARK: - Stringification

	def to_s(tag : String)
		String.build() { |io| to_s(tag, io) }
	end

	def to_s(tag : String, io : IO)
		Tab.tag_valid!(tag)
		to_s(io)
		io << " # tagged: " << tag
	end

	def to_s(io : IO)
		io << "# " if ( !enabled?() )
		fields = @fields

		case fields
			when Array
				fields.each() { |field|
					if ( field.nil? )
						io << "*       "
					else
						io << field.to_s().ljust(2) << "      "
					end
				}

			when String
				io << fields.ljust(40)

			else
				raise "Something is wrong."
		end

		if ( user = @user )
			user.to_s(io)
			io << user.name << ' '
		end

		io << '(' << @command << ')'
	end


	# MARK: - Utilities

	def self.command_valid?(command : String) : Bool
		return false if ( !command )
		return false if ( command.empty? )

		brackets = 0
		quotes = 0
		command.each_char() { |char|
			return false if ( char == '\n' )
			return false if ( char == '#' )

			if ( char == '(' )
				brackets += 1
			elsif ( char == ')')
				return false if ( brackets <= 0 )
				brackets -= 1
			end

			if ( char == '"' )
				quotes += 1
			end
		}
		return false if ( brackets != 0 )
		return false if ( quotes % 2 != 0 )

		# FIXME: Make safer...

		return true
	end


	# MARK: - Errors

	class MalformedFieldError < Exception; end

end
