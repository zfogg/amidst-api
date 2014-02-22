q    = require "q"
uuid = require "node-uuid"


module.exports = (app, db, io) ->

  io_dev = io.of "/dev"

  io_api = io.of "/api"


  query = require("./query")(db)


  app.get "/dev/register", (req, res) ->
    q()
      .then ->
        query "CREATE (a:Device {uuid: {uuid}}) RETURN a",
          uuid: uuid.v1()

      .spread ({a}) ->
        res.json 201, uuid: a.data.uuid
        a

      .then (a) ->
        io_api.emit "register", a.data

      .fail (err) ->
        console.log err
        res.send 500

      .done()


  app.post "/dev/meeting", (req, res) ->
    q()
      .then ->
        query """
          MATCH (a:Device {uuid: {me}}), (b:Device {uuid: {them}})
          CREATE (m:Meeting {time: {time}, signal: {signalStrength}})
          CREATE (a)-[:SCANNED]->(m)<-[:TRANSMITTED]-(b)
          RETURN a, m, b
          """,
          req.body

      .spread ({a, m, b}) ->
        setTimeout (-> res.json result: true), 300
        [a, m, b]

      .spread (a, m, b) ->
        ad = a.data; md = m.data; bd = b.data
        console.log "\n#{ad.uuid[..4]} <-(#{md.time.split(' ')[1]}@#{md.signal})-> #{bd.uuid[..4]}"
        io_api.emit "meeting", a.data, m.data, b.data

      .fail (err) ->
        console.log err
        res.send 500

      .done()

