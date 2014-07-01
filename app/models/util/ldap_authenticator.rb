# encoding: UTF-8

class LdapAuthenticator

  # Performs a login over LDAP with the passed data.
  # Returns the logged-in Employee or nil if the login failed.
  def login(username, pwd)
    if !username.strip.empty? &&
       (auth_user(Settings.ldap.user_dn, username, pwd) ||
        (auth_user(Settings.ldap.external_dn, username, pwd) && group_member(username)))
      Employee.find_by_ldapname(username)
    end
  end

  def auth_user(dn, username, pwd)
    connection.bind_as(base: dn,
                       filter: "uid=#{username}",
                       password: pwd)
  end

  def group_member(username)
    result = connection.search(base: Settings.ldap.group,
                               filter: Net::LDAP::Filter.eq('memberUid', username))
    !result.empty?
  end

  # Returns a Array of LDAP user information
  def all_users
    connection.search(base: Settings.ldap.user_dn,
                      attributes: %w(uid sn givenname mail))
  end

  private

  def connection
    config = Settings.ldap.connection.to_hash
    config[:encryption] = config[:encryption].to_sym if config[:encryption]
    Net::LDAP.new(config)
  end

end