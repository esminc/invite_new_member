require 'yaml'
require 'json'
require 'httpclient'

class InviteNewMember
  class Service
    def initialize(config)
      @config = config
    end

    def invite
      p @config
    end
  end

  class Idobata < Service
  end

  class Esa < Service
  end

  class GitHub < Service
  end

  class Dropbox < Service
    def invite
      invite_request get_folder_id
    end

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
