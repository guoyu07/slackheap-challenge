require 'sinatra'
require 'tilt/erb'

module SlackPrizes
  class SinatraApp < Sinatra::Base
    def self.redis; @redis; end
    def self.redis=(redis); @redis = redis; end

    def self.resolve_user(user_id)
      @redis.hget(:users, user_id)
    end

    def self.highest_user_from_zset(set)
      user_id, score = SinatraApp.redis.zrange(set, -1, -1, withscores: true).first
      if user_id
        "#{resolve_user(user_id)} (#{score.to_i})"
      else
        "Unknown"
      end
    end

    def self.highest_pair_from_zset(set)
      user_ids, score = SinatraApp.redis.zrange(set, -1, -1, withscores: true).first
      if user_ids
        ids = user_ids.split(' ')
        users = ids.map { |id| resolve_user(id) }
        "#{users[0]} & #{users[1]} (#{score.to_i})"
      else
        "Unknown"
      end
    end

    def self.lowest_user_from_zset(set)
      user_id, score = SinatraApp.redis.zrevrange(set, -1, -1, withscores: true).first
      if user_id
        "#{resolve_user(user_id)} (#{score.to_i})"
      else
        "Unknown"
      end
    end

    set :public_folder, File.dirname(__FILE__) + '/static'

    CATEGORIES = [
      {
        name: '&#128588; GG',
        find: lambda { SinatraApp.highest_user_from_zset(:gg) }
      },
      {
        name: '&#128515; Happy',
        find: lambda { SinatraApp.highest_user_from_zset(:happy) }
      },
      {
        name: '&#127865; Helpful',
        find: lambda { SinatraApp.highest_user_from_zset(:thanks) }
      },
      {
        name: '&#128561; Emoji',
        find: lambda { SinatraApp.highest_user_from_zset(:emoji) }
      },
      {
        name: '&#128123; Spammer',
        find: lambda { SinatraApp.highest_user_from_zset(:spammer) }
      },
      {
        name: '&#128040; Quiet',
        find: lambda { SinatraApp.lowest_user_from_zset(:spammer) }
      },
      {
        name: '&#128129; Popular',
        find: lambda { SinatraApp.highest_user_from_zset(:popular) }
      },
      {
        name: '&#128145; Lovebirds',
        find: lambda { SinatraApp.highest_pair_from_zset(:lovebirds) }
      }
    ]

    get '/' do
      @data = CATEGORIES
      erb :index
    end
  end
end
