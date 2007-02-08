class LdapUser < ActiveLdap::Base
  ldap_mapping :prefix => "ou=users" 
  
  def self.login(username, password)
    begin
      ActiveLdap::Base.connect(
        :host => "proximai.ww2.ch",
        :port => 636,
        :base => "dc=puzzle,dc=itc",
        :bind_format => "uid=#{username},ou=puzzle,ou=users,dc=puzzle,dc=itc",
        :password_block => Proc.new { password },
        :allow_anonymous => false
      )
      ActiveLdap::Base.close
      return true
    rescue ActiveLdap::AuthenticationError
      puts $!
      return false
    end
  end
end