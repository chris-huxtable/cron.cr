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

TAB0 = <<-STRING
# (Cron version V5.0)
SHELL=/bin/sh
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin
HOME=/var/log

# tag managed cron tasks
@daily                                  (test) # tagged: daily.test
0       2       *       *       *       (test) # tagged: another.test

STRING

TAB1 = <<-STRING
# (Cron version V5.0)
SHELL=/bin/sh
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin
HOME=/var/log

# tag managed cron tasks
@daily                                  (test) # tagged: daily.test
0       2       *       *       *       (test) # tagged: another.test
@reboot                                 (test) # tagged: reboot.test
0       1       *       *       *       (test) # tagged: yet.another.test

STRING

TAB2 = <<-STRING
# (Cron version V5.0)
SHELL=/bin/sh
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin
HOME=/var/log

# tag managed cron tasks
# @daily                                  (test) # tagged: daily.test
30      1       *       *       *       (replaced) # tagged: another.test
0       1       *       *       *       (test) # tagged: yet.another.test

STRING

describe Cron::Tab do

	it "works correctly" do

		tab = Cron::Tab.new!("spec/sample.crontab")
		tab.to_s.should eq(TAB0)

		tab.add_task("reboot.test", Cron::Task.reboot("test"))
		tab.add_task("yet.another.test", Cron::Task.task("test", 0, 1))
		tab.to_s.should eq(TAB1)

		tab.remove_task("reboot.test")
		tab.replace_task("another.test", Cron::Task.task("replaced", 30, 1))
		tab.disable_task("daily.test")
		tab.to_s.should eq(TAB2)

		tab.remove_task("yet.another.test")
		tab.replace_task("another.test", Cron::Task.task("test", 0, 2))
		tab.enable_task("daily.test")
		tab.to_s.should eq(TAB0)

	end

	it "writes correctly" do

		tab = Cron::Tab.new!("spec/sample.crontab")
		tab.write("/tmp/spec_cron.cr")

		File.read("/tmp/spec_cron.cr").should eq(tab.to_s)
	end

end
