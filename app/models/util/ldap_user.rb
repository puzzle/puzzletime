class LdapUser < ActiveLdap::Base
  ldap_mapping :dn_attribute => 'uid', :prefix => "ou=puzzle,ou=users" 
  
  def self.login(username, password)
    begin
      ActiveLdap::Base.establish_connection(
        :host => "proximai.ww2.ch",
        :method => :ssl,
        :port => 636,
        :base => "ou=puzzle,ou=users,dc=puzzle,dc=itc",
        :bind_dn => "uid=#{username},ou=puzzle,ou=users,dc=puzzle,dc=itc",
        :password_block => Proc.new { password },
        :allow_anonymous => false,
        :timeout => 10
      )
      #ActiveLdap::Base.close
      return true
    rescue ActiveLdap::AuthenticationError
      puts $!
      return false
    end
  end
end