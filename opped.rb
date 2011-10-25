# dicking around with detecting op/deop, useful future reference

module NB
  class Opped
    include Cinch::Plugin
    listen_to :op, :method => :opped
    listen_to :deop, :method => :opped
      
    def opped(m, *args)
      @bot.logger.debug "Opped: %s" % m.params.inspect 
      mode = m.params[1]
      user = m.params[2]
      if mode == "+o" && user != @bot.nick
        m.reply user + ": 'gratz"
      elsif mode == "-o" && user != @bot.nick
        m.reply user + ": Sorry for your loss."
      end
    end
  
  end
end
