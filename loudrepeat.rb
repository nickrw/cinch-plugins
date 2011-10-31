# Nick Robinson-Wall 2011
# Description: Cinch plugin to loudly repeat selected users' into a given channel, bolding and exclaiming on the way.
# Source:      https://github.com/nickrw/cinch-plugins
# Cinch:       https://github.com/cinchrb/cinch


# Configuration required when bot is initialised, add this to your configure.do stanza:
#
#    c.plugins.options[NCinchPlugins::LoudRepeat] = {
#      :loud_users => [],        # An array of Regexps of users to repeat
#      :channel => '#somechan'   # The channel to repeat into
#    }

module NCinchPlugins
  class LoudRepeat
    include Cinch::Plugin
    listen_to :message, :method => :shouty

    def shouty(m, *args)
      relaychan = Channel(config[:channel])
      config[:loud_users].each do |regex|
        if m.user.to_s =~ regex
	  unless relaychan.has_user?(m.user)
	    raaaaah = m.message.upcase
	    raaaaah.sub!(/\.$/,'')
	    raaaaah = "<#{m.user.to_s}>\u0002 #{raaaaah}!"
            relaychan.send(raaaaah)
	  else
	    @bot.logger.debug "User #{m.user.to_s} matches the loud user list, but is present in the repeat channel #{config[:channel]}"
	  end
        end
      end
    end
      
  end
end
