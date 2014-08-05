class Game < ActiveRecord::Base
  has_many :channels

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

    client.query({"input"=>{"query"=>"server"},"connectorGuids"=>dota_uuids}, callback)
    #client.query({"input"=>{"query"=>"server"},"connectorGuids"=>["134b171b-c419-4cbb-9924-c952476c230a"]}, callback)
    client.join
    client.disconnect


    Channel.delete_all
    data_rows.each do |datas|
      datas.each do |data|
        channel = Channel.find_by(link: data['link'])
        vs = get_viewers(data['viewers'])
        if channel
          channel.update(title: data['title'], viewers: vs, image: data['image'])
        else
          game = Game.find_by(name: data['type'])
          game.channels.create(title: data['title'], viewers: vs, link:data['link'], player: data['player'], image: data['image'], source: data['source'])
        end
      end
    end
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

  def self.dota_uuids
    ["b0260b47-8da4-4ebb-84b0-67bc1d6a79bf","134b171b-c419-4cbb-9924-c952476c230a"]
  end

end
