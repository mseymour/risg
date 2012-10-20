require 'time'
require 'ruby-progressbar'

module Risg
  # A log parser that parses logs.
  # The format used for testing here is the ZCBot format.
  class LogParser
    attr_reader :messages, :channel

    WELL_KNOWN_CHANNEL_USER_MODES = {'Y' => :official_oper, 'q' => :founder, 'a' => :admin, 'o' => :chanop, 'h' => :halfop, 'v' => :voice}
    MODE_CHANGE = {'+' => :add, '-' => :remove}
    DATE_TIME_REGEXP = /^(?<month>\d+)\/(?<day>\d+)\/(?<year>\d+) (?<hour>\d+):(?<min>\d+):(?<sec>\d+)/

    def initialize(*logs, channel)
      @logs, @messages, @channel = logs, [], channel
      @channel_message_format = /^(.+?) :(\S+!\S+@\S+) PRIVMSG (.+?) :(.+)$/
      @action_message_format = /^(.+?) :(\S+!\S+@\S+) PRIVMSG (.+?) :\x01ACTION (.+)\x01$/
      @other_message_format = /^(.+?) :(\S+!\S+@\S+) (\S+) (.+)$/
    end

    Message = Struct.new(:type, :timestamp, :hostmask, :channel, :message, :line)

    def parse
      #print 'Parsing %s (%s)...' % [File::basename(@log.path), kilo(@log.size)], $/
      @logs.each {|log|
        open(log).each_line {|line|
          case line
          when @action_message_format
            # Transform line into variables
            ts, hostmask, target, message = *line.scan(@channel_message_format).flatten
            # Ignore CTCP messages and channels that do not match the currently selected channel.
            next if !@channel.downcase.eql?(target.downcase)
            @messages.push Message.new(:action, parse_datetime_string(ts), hostmask, target, message, line)
          when @channel_message_format
            ts, hostmask, target, message = *line.scan(@channel_message_format).flatten
            # Ignore CTCP messages and channels that do not match the currently selected channel.
            next if message.start_with?("\x01") || !@channel.downcase.eql?(target.downcase)
            @messages.push Message.new(:message, parse_datetime_string(ts), hostmask, target, message, line)
          when @other_message_format
            # Do further processing on the line
            result = parse_other_content(line)
            next if !result
            @messages.push result
          end
        }
      }
      @messages.uniq!
    end

    private

    def parse_datetime_string(s)
      h = s.match DATE_TIME_REGEXP
      Time.utc(h[:year], h[:month], h[:day], h[:hour], h[:min], h[:sec])
    end

    def parse_other_content(line)
      if line =~ @other_message_format
        ts, hostmask, command, content = *line.scan(@other_message_format).flatten
        case command
        when 'NICK'
          Message.new(:nick, parse_datetime_string(ts), hostmask, channel, content[1..-1], line)
        when 'TOPIC'
          channel, newtopic = *content.scan(/^(\S+) :(.+)?/)
          Message.new(:topic, parse_datetime_string(ts), hostmask, channel, newtopic, line)
        when 'KICK'
          channel, kicked, message = *content.scan(/^(\S+) (\S+) :(.+)?/)
          Message.new(:kick, parse_datetime_string(ts), hostmask, channel, {nick: kicked, message: message}, line)
        when 'QUIT'
          Message.new(:quit, parse_datetime_string(ts), hostmask, channel, content[1..-1], line)
        when 'PART'
          channel, message = *content.scan(/^(\S+) :(.+)?/)
          Message.new(:part, parse_datetime_string(ts), hostmask, channel, message, line)
        when 'JOIN'
          Message.new(:join, parse_datetime_string(ts), hostmask, content, nil, line)
        when 'MODE'
          content = content.scan(/^\S+|\G [\+-]\w+|\G \S+/).map(&:strip)
          modes = content[1].scan(/^[+-]|\G\w/)
          modes[1..-1].each_with_index {|mode, index| content[index+2] = { nick: content[index+2], modechange: [WELL_KNOWN_CHANNEL_USER_MODES[mode], MODE_CHANGE[modes[0]]]} }
          content.delete_at(1)
          channel, modes = *content
          Message.new(:mode, parse_datetime_string(ts), hostmask, channel, modes, line)
        end
      end
    end
  end
end

$logfiles = Dir["#{File.join('C:/Users/Mark/Desktop/logconcat', '*')}.log"]

require 'benchmark'

Benchmark.bmbm do |results|
  results.report('%d logfiles' % $logfiles.size) {
    lp = Risg::LogParser.new(*$logfiles, '#shakesoda')
    lp.parse
  }
end