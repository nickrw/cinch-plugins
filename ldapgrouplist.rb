require 'net/ldap'
# Nick Robinson-Wall 2011
# Description: Cinch plugin to query and list a group of users
# Source:      https://github.com/nickrw/cinch-plugins
# Cinch:       https://github.com/cinchrb/cinch


# Configuration required when bot is initialised, add this to your configure.do stanza:
# 
#    c.nb_ldapglist = {
#      :host => "my-ldap-server-hostname",    # LDAP Server's hostname / IP
#      :basedn => "dc=companyname,dc=com",    # Your LDAP's base DN
#      :grouptype => :posixgroup,             # :posixgroup or :groupofnames
#      :group => "cn=oncall",                 # Name of the group to list, prefixed with cn= (or applicable)
#      :telephone => false,                   # True to fetch 'telephoneNumber' attribute for each member and display it along side. Posix group only.
#      :prefix => true,                       # Prefix nick to missive reply?
#      :missive => "The following people are members of this group:"
#    }  

module NCinchPlugins
  class LDAPGroupList
    include Cinch::Plugin
    match /on-?call/i, :method => :oncall
      
    def oncall(m)
      begin
        
        m.reply @bot.config.nb_ldapglist[:missive], @bot.config.nb_ldapglist[:prefix]
	ldap = Net::LDAP.new :host => @bot.config.nb_ldapglist[:host]
        base = @bot.config.nb_ldapglist[:basedn]

        gfilter = "(&(objectClass=" + ((@bot.config.nb_ldapglist[:grouptype] == :posixgroup) ? 'posixGroup' : 'groupOfNames') + ")(" + @bot.config.nb_ldapglist[:group] + "))"
        filter = Net::LDAP::Filter.construct(gfilter)

        candidates = []
        ldap.search(:base => base, :filter => filter, :attributes => ['memberUid']) do |entry|
          candidates = entry.memberuid
        end 
        
        tnum = []
        if @bot.config.nb_ldapglist[:telephone]
          philter = Net::LDAP::Filter.construct("(&(objectClass=person)(|(uid=" + candidates.join(")(uid=") + ")))")
          ldap.search(:base => base, :filter => philter, :attributes => ['telephoneNumber']) do |entry|
            tnum << entry.dn.sub(/^uid=([^,]+),.*$/, '\1') + " (" + entry.telephoneNumber.join(", ") + ")"
          end
        else
          tnum = candidates
        end

        m.reply tnum.join(", ")
      
      rescue Net::LDAP::LdapError => e
	m.reply "An error occured querying LDAP: " + e.message
      end
    end
  
  end
end
