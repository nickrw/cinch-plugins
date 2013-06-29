# WORK IN PROGRESS
# playing with getting a siri-style 'remind me about xyz in 5 hours / at 1 o clock / etc'
$remind_pattern = /^(!|NB: )remind (us|me|#[^ ]*) (?:about|to) (.*) (?:(in) ([0-9]+) (min(?:ute(s|)|s)?|hour(?:s)?)|(at) (.*))$/i

module NB
  class Remind
    include Cinch::Plugin
    match $remind_pattern, :method => :remind, :use_prefix => false
    match /^(!|NB: )remind (.*)$/i, :method => :check_parsable, :use_prefix => false
    match /poll/, :method => :poll_reminders
    timer 15, method: :poll_reminders

    def initialize(*args)
      super
      @reminders = {}
    end

    def remind(m, *args)
      # [addressed, who-to-remind, about-what, in/nil, count/nil, unit/nil, at/nil, human-timestamp]
      recipient = args[1]
      ack_recipient = recipient
      about = args[2]
      dowhen = {
        :in => {:set => !args[3].nil?, :count => args[4], :unit => args[5]},
	:at => {:set => !args[6].nil?, :human => args[7]}
      }
      prefix = ''

      if recipient == "us" && m.channel?
        recipient = m.channel
	ack_recipient = "this channel"
      elsif recipient == "us" && !m.channel?
        dont_follow(m)
	return
      elsif recipient == "me"
	ack_recipient = "you"
	if m.channel?
          recipient = m.channel
          prefix = m.user.to_s + ': ' if m.channel?
	  about.gsub!(/\bmy\b/, 'your')
	else
	  recipient = m.user
	end
      elsif @bot.config.channels.include?(recipient)
        recipient = Channel(recipient)
      else
        m.reply("Sorry, but I'm not in that channel.", :prefix => true)
	return
      end

      dowhen = normalise_timestamp(dowhen)
      @reminders[dowhen] = {:recipient => recipient, :about => about, :prefix => prefix}

      m.reply("I will remind #{ack_recipient} about \"#{about}\" at #{dowhen}", :prefix => true)
    end

    def poll_reminders(*args)
      timenow = Time.now
      @reminders.keys.each do |ts|
        if ts <= timenow
	  @reminders[ts][:recipient].send(@reminders[ts][:prefix]+@reminders[ts][:about])
	  @reminders.delete(ts)
	end
      end
    end

    def check_parsable(m, *args)
      unless m.params[1].match($remind_pattern)
        dont_follow(m)
      end
    end

    private

    def normalise_timestamp(abstract)
      puts abstract.inspect
      now = Time.now
      if abstract[:in][:set]
        count = abstract[:in][:count].to_i
        count *= 60
        count *= 60 if abstract[:in][:unit] =~ /^hours?$/i
        return Time.now + count
      elsif abstract[:at][:set]
        case abstract[:at][:human]
	when /^([1-9]|1[012])$/
	  nh = now.hour 
	  des_hour = abstract[:at][:human].to_i % 12
	  if (nh % 12) >= des_hour
	    set_day = now.day + 1
	    set_hour = des_hour
	  else
	    set_day = now.day
	    if nh >= 12
	      set_hour = des_hour + 12
	    else
	      set_hour = des_hour
	    end
	  end
	  return Time.local(now.year, now.month, set_day, set_hour, 0, 0)
	end
      end
      false
    end

    def dont_follow(m)
      m.reply("Sorry, I don't quite understand the phrasing", :prefix => true)
    end
  
  end
end
