require 'yaml'
require 'json'
require 'httpclient'
require 'mail'

class InviteNewMember
  class Service
    def initialize(config)
      @config = config
    end

    def invite
      p @config
    end
  end

  class MailInviteService < Service
    def invite
      mail = Mail.new
      mail.charset = 'utf-8'

      mail.from    @config['from_address']
      mail.to      @config['to_address']
      mail.subject @config['title']
      mail.body    body_message

      mail.delivery_method :smtp, options
      mail.deliver
    end

    private

    def body_message
      <<-BODY
#{@config['message']}

#{@config['invite_url']}
      BODY
    end

    def options
      {
        address:              ENV['SMTP_ADDRESS'],
        port:                 ENV['SMTP_PORT'].to_i,
        domain:               ENV['SMTP_DOMAIN'],
        user_name:            ENV['SMTP_USER_NAME'],
        password:             ENV['SMTP_PASSWORD'],
        authentication:       ENV['SMTP_AUTHENTICATION'].to_sym,
        enable_starttls_auto: ENV['SMTP_ENABLE_STARTTLS_AUTO'] == 'true'
      }
    end
  end

  class Idobata < MailInviteService
  end

  class Esa < MailInviteService
  end

  class GitHub < Service
    def invite
      url = "https://api.github.com/orgs/#{@config['organization']}/memberships/#{@config['username']}"
      client.put(url, {'role' => @config['role']}.to_json, header)
    end

    def header
      {
        'Content-Type'  => 'application/json',
        'Authorization' => "token #{ENV['GITHUB_TOKEN']}",
        'User-Agent'    => 'invite user',
        'Accept'        => 'application/vnd.github.v3+json'
      }
    end

    def client
      @client ||= HTTPClient.new
    end
  end

  class Dropbox < Service
    def invite
      invite_request get_folder_id
    end

    private

    def get_folder_id
      url = 'https://api.dropboxapi.com/2/files/list_folder'
      response_body = client.post_content(url, {'path' => ''}.to_json, header)
      response = JSON.load(response_body)

      target_entry = response['entries'].find {|entry| entry['name'] == @config['shared_folder'] }
      raise "#{@config['shared_folder']} is not found" unless target_entry

      target_entry['shared_folder_id']
    end

    def invite_request(folder_id)
      url = 'https://api.dropboxapi.com/2/sharing/add_folder_member'
      client.post_content(url, invite_params(folder_id).to_json, header)
    end

    def client
      @client ||= HTTPClient.new
    end

    def header
      {
        'Content-Type'  => 'application/json',
        'Authorization' => "Bearer #{ENV['DROPBOX_TOKEN']}",
        'User-Agent'    => 'invite user'
      }
    end

    def invite_params(folder_id)
      {
        'shared_folder_id' => folder_id,
        'members' => [
          {
            'member' => {
              '.tag'  => 'email',
              'email' => @config['email']
            }
          }
        ]
      }
    end
  end

  def initialize(account_list_file)
    @config = YAML.load_file(account_list_file)
  end

  def invite!
    services.each do |key, klass|
      next unless @config[key.to_s]

      klass.new(@config[key.to_s]).invite
    end
  end

  def services
    {
      idobata: Idobata,
      esa:     Esa,
      github:  GitHub,
      dropbox: Dropbox
    }
  end
end

if __FILE__ == $0
  InviteNewMember.new(ARGV[0]).invite!
end
