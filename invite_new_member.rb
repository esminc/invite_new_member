require 'yaml'

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
  end


  def initialize(account_list_file)
    @config = YAML.load_file(account_list_file)
  end

  def invite!
    p @config
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
