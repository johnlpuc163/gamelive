class Game < ActiveRecord::Base
  has_many :channels

  def self.delete_data
    Channel.delete_all
  end

  def self.update_data
    require "importio"
    client = Importio.new("c676d33a-07d7-46ef-8d08-a6920ea7daf6", "ToGGkRNT60bqadUUNW66knixXKB9uw8HwHCIDTQz8ocY1OBklyKXesXgYX1yUFooW4sMYgEG4WBqaTsQuT8j5w==")
    client.connect
    data_rows = []

    callback = lambda do |query, message|
      # Disconnect messages happen if we disconnect the client library while a query is in progress
      if message["type"] == "DISCONNECT"
        puts "The query was cancelled as the client was disconnected"
      end
      if message["type"] == "MESSAGE"
        if message["data"].key?("errorType")
          # In this case, we received a message, but it was an error from the external service
          puts "Got an error!"
          puts JSON.pretty_generate(message["data"])
        else
          # We got a message and it was not an error, so we can process the data
          puts "Got data!"
          #puts JSON.pretty_generate(message["data"])
          # Save the data we got in our dataRows variable for later
          data_rows << message["data"]["results"]
        end
      end
      if query.finished
        puts "Query finished"
      end
    end

    douyu_urls = ["http://www.douyutv.com/directory/game/CF", "http://www.douyutv.com/directory/game/How", "http://www.douyutv.com/directory/game/LOL", "http://www.douyutv.com/directory/game/DOTA2", "http://www.douyutv.com/directory/game/WOW"]
    game17173_urls = ['http://v.17173.com/live/game/421','http://v.17173.com/live/game/1137','http://v.17173.com/live/game/21', 'http://v.17173.com/live/game/2007', 'http://v.17173.com/live/game/1589']

    #client.query({"input"=>{"query"=>"server"},"connectorGuids"=>dota_uuids}, callback)
    douyu_urls.each do |url|
      client.query({"input"=>{"webpage/url"=>url},"connectorGuids"=>["002249e6-3a8e-4181-ab71-7c8cf7728ee2"]}, callback)
    end
    game17173_urls.each do |url|
      client.query({"input"=>{"webpage/url"=>url},"connectorGuids"=>["1efc0b47-5f9a-4bd4-abf2-53b1d5f9e302"]}, callback)
    end


    puts "Going to join"
    client.join
    puts "Join completed"
    puts "Going to disconnect"
    client.disconnect
    puts "Disconnected"

    # Channel.delete_alla
    #all_live_channels.update_all(status: false)
    update_begin_time = Time.now

    data_rows.each do |datas|
      datas.each do |data|
        channel = Channel.find_by(link: data['link'])
        vs = get_viewers(data['viewers'])
        if channel
          channel.update(title: data['title'], viewers: vs, image: data['image'], status: true)
        else
          game = Game.find_by(name: data['type'])
          game.channels.create(title: data['title'], viewers: vs, link:data['link'], player: data['player'], image: data['image'], source: data['source'], status: true)
        end
        # vs = get_viewers(data['viewers'])
        # game = Game.find_by(name: data['type'])
        # game.channels.create(title: data['title'], viewers: vs, link:data['link'], player: data['player'], image: data['image'], source: data['source'])
      end
    end

    closed_channels = Channel.where("updated_at < ? AND status = ?", update_begin_time, true)
    closed_channels.update_all(status: false)

    puts "All done!"
  end

  def self.init_db
    #names = ['DOTA2','英雄联盟','炉石传说','穿越火线','魔兽世界']
    games = {'DOTA2'=>'http://staticlive.douyutv.com/upload/game_cate/0d0ccaa16a0dc5ea4a4741a7e4433386.png','英雄联盟'=>'http://staticlive.douyutv.com/upload/game_cate/be8db394d66ec6f51c12d287141ff99e.jpg','炉石传说'=>'http://staticlive.douyutv.com/upload/game_cate/8be974233e4ac4cb8db246f3dc29e4d8.jpg','穿越火线'=>'http://staticlive.douyutv.com/upload/game_cate/fbf130f9ad4cb3c76190357b47cd1f23.png','魔兽世界'=>'http://staticlive.douyutv.com/upload/game_cate/644537f4bd14901732f01e1ab9d8322b.png'}
    games.each do |name,image|
      game = Game.find_by(name: name)
      Game.create(name: name,image: image) unless game
    end
  end

  def self.all_live_channels
    Channel.all.where(status: true)
  end


  def get_live_channels
    channels.where(status: true)
  end



  private

  def self.get_viewers (str)
    str.slice! '人'
    str.slice! ','
    if str.include? '万'
      str.slice! '万'
      str = str.to_f*10000
    end
    str.to_i
  end


end
