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

require "../spec_helper"


private def task_valid(task : Cron::Task, string : String) : Nil
	task.to_s("tag").should eq(string)
end

private def task_raises(&block) : Nil
	expect_raises Exception do
		 yield()
	 end
end


describe Cron::Task do

	it "makes *ly tasks correctly" do
		task_valid(Cron::Task.reboot("test"),	"@reboot                                 (test) # tagged: tag")
		task_valid(Cron::Task.yearly("test"),	"@yearly                                 (test) # tagged: tag")
		task_valid(Cron::Task.monthly("test"),	"@monthly                                (test) # tagged: tag")
		task_valid(Cron::Task.weekly("test"),	"@weekly                                 (test) # tagged: tag")
		task_valid(Cron::Task.daily("test"),	"@daily                                  (test) # tagged: tag")
		task_valid(Cron::Task.hourly("test"),	"@hourly                                 (test) # tagged: tag")

		task_raises() { Cron::Task.new("test", "@fake") }
		task_raises() { Cron::Task.new("test", "fake") }
	end

	it "set minute field correctly" do
		task_valid(Cron::Task.task("test", minute: 1),			"1       *       *       *       *       (test) # tagged: tag")
		task_valid(Cron::Task.task("test", minute: 0),			"0       *       *       *       *       (test) # tagged: tag")
		task_valid(Cron::Task.task("test", minute: 59),			"59      *       *       *       *       (test) # tagged: tag")

		task_raises() { Cron::Task.task("test", minute: -1) }
		task_raises() { Cron::Task.task("test", minute: 60) }
	end

	it "set hour field correctly" do
		task_valid(Cron::Task.task("test", hour: 1),			"*       1       *       *       *       (test) # tagged: tag")
		task_valid(Cron::Task.task("test", hour: 0),			"*       0       *       *       *       (test) # tagged: tag")
		task_valid(Cron::Task.task("test", hour: 23),			"*       23      *       *       *       (test) # tagged: tag")

		task_raises() { Cron::Task.task("test", hour: -1) }
		task_raises() { Cron::Task.task("test", hour: 24) }
	end

	it "set day_of_month field correctly" do
		task_valid(Cron::Task.task("test", day_of_month: 15),	"*       *       15      *       *       (test) # tagged: tag")
		task_valid(Cron::Task.task("test", day_of_month: 1),	"*       *       1       *       *       (test) # tagged: tag")
		task_valid(Cron::Task.task("test", day_of_month: 31),	"*       *       31      *       *       (test) # tagged: tag")

		task_raises() { Cron::Task.task("test", day_of_month: -1) }
		task_raises() { Cron::Task.task("test", day_of_month: 32) }
	end

	it "set month field correctly" do
		task_valid(Cron::Task.task("test", month: 6),			"*       *       *       6       *       (test) # tagged: tag")
		task_valid(Cron::Task.task("test", month: 1),			"*       *       *       1       *       (test) # tagged: tag")
		task_valid(Cron::Task.task("test", month: 12),			"*       *       *       12      *       (test) # tagged: tag")

		task_raises() { Cron::Task.task("test", month: 0) }
		task_raises() { Cron::Task.task("test", month: 13) }
	end

	it "set day_of_week field correctly" do
		task_valid(Cron::Task.task("test", day_of_week: 1),		"*       *       *       *       1       (test) # tagged: tag")
		task_valid(Cron::Task.task("test", day_of_week: 0),		"*       *       *       *       0       (test) # tagged: tag")
		task_valid(Cron::Task.task("test", day_of_week: 7),		"*       *       *       *       7       (test) # tagged: tag")

		task_raises() { Cron::Task.task("test", day_of_week: -1) }
		task_raises() { Cron::Task.task("test", day_of_week: 8) }
	end

	it "rejects bad commands" do
		task_valid(Cron::Task.reboot("test"),			"@reboot                                 (test) # tagged: tag")
		task_valid(Cron::Task.reboot("(test)"),			"@reboot                                 ((test)) # tagged: tag")
		task_valid(Cron::Task.reboot("(test)(test)"),	"@reboot                                 ((test)(test)) # tagged: tag")
		task_valid(Cron::Task.reboot("((test)(test))"),	"@reboot                                 (((test)(test))) # tagged: tag")
		task_valid(Cron::Task.reboot("\"test\""),		"@reboot                                 (\"test\") # tagged: tag")
		task_valid(Cron::Task.reboot("\"t\"es\"t\""),	"@reboot                                 (\"t\"es\"t\") # tagged: tag")

		task_raises() { Cron::Task.reboot("tes#t)") }
		task_raises() { Cron::Task.reboot("test)") }
		task_raises() { Cron::Task.reboot("(test") }
		task_raises() { Cron::Task.reboot(")test(") }
		task_raises() { Cron::Task.reboot("(test)(") }
		task_raises() { Cron::Task.reboot("(te)st)(") }
		task_raises() { Cron::Task.reboot("\"test") }
		task_raises() { Cron::Task.reboot("\"te\"st\"") }
	end

end
