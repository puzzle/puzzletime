# frozen_string_literal: true

#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.


class LdapAuthenticator
  attr_reader :username, :password

  def initialize(username = nil, password = nil)
    @username = username
    @password = password
  end

  # Performs a login over LDAP with the passed data.
  # Returns the logged-in Employee or nil if the login failed.
  def login(username = nil, password = nil)
    @username = username if username
    @password = password if password
    return nil if config[:host].blank?
    return unless valid_user?

    Employee.find_by(ldapname: @username)
  end

  def auth_user(base_dn)
    connection.bind_as(
      base: base_dn,
      filter: "uid=#{username}",
      password: password
    )
  end

  # Returns a Array of LDAP user information
  def all_users
    connection.search(
      base: internal_dn,
      attributes: %w(uid sn givenname mail)
    )
  end

  private

  def valid_user?
    return if username.strip.empty?
    return unless internal_user? || external_user?

    true
  end

  def internal_user?
    auth_user(internal_dn)
  end

  def external_user?
    auth_user(external_dn) && group_member?
  end

  def group_member?
    group  = connection.search(base: group_dn, attributes: :member).first
    member = group[:member]
    member.any? { |m| m =~ /uid=#{username}/ }
  end

  def connection
    @connection ||=
      begin
        con = Net::LDAP.new(config)
        bindauth(con)
        con
      end
  end

  def bindauth(connection)
    return unless binduser
    return unless bindpassword

    connection.auth binduser, bindpassword
  end

  def config
    @config ||=
      begin
        cfg = Settings.ldap.connection.to_hash
        cfg[:encryption][:method] = cfg[:encryption][:method].to_sym if cfg.dig(:encryption, :method)
        cfg[:encryption][:tls_options] = tls_options if root_cert_file && chain_cert_file
        cfg
      end
  end

  def tls_options
    {
      verify_mode: OpenSSL::SSL::VERIFY_PEER,
      cert_store: cert_store
    }
  end

  def internal_dn
    @internal_dn ||= Settings.ldap.user_dn
  end

  def external_dn
    @external_dn ||= Settings.ldap.external_dn
  end

  def group_dn
    @group_dn ||= Settings.ldap.group
  end

  def binduser
    @binduser ||= Settings.ldap.auth.binduser
  end

  def bindpassword
    @bindpassword ||= Settings.ldap.auth.bindpassword
  end

  def root_cert_file
    @root_cert_file ||= Settings.ldap.auth.root_cert.presence
  end

  def chain_cert_file
    @chain_cert_file ||= Settings.ldap.auth.chain_cert.presence
  end

  def root_cert
    @root_cert ||= OpenSSL::X509::Certificate.new(Pathname.new(root_cert_file).read)
  end

  def chain_cert
    @chain_cert ||= OpenSSL::X509::Certificate.new(Pathname.new(chain_cert_file).read)
  end

  def cert_store
    @cert_store ||=
      begin
        store = OpenSSL::X509::Store.new
        store.add_cert root_cert
        store.add_cert chain_cert
        store
      end
  end

end
