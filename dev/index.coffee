q    = require "q"
uuid = require "node-uuid"

util = require "util"

log = (s) ->
  console.log(util.inspect(s,
    showHidden: true
    depth:      null
    colors:     true
  ))


module.exports = (app, db, io) ->

  io_dev = io.of "/dev"

  io_api = io.of "/api"


  query = require("./query")(db)


  app.get "/dev/register", (req, res) ->
    q()
      .then ->
        query "CREATE (a:Device {uuid: {uuid}, create: {created}}) RETURN a",
          uuid:    uuid.v1()[..5]
          created: +(new Date()).getTime()

      .spread ({a}) ->
        res.json 201, uuid: a.data.uuid
        a

      .then (a) ->
        io_api.emit "register", a.data

      .fail (err) ->
        log err
        res.send 500

      .done()


  app.post "/dev/meeting", (req, res) ->
    req.body.time = Date.parse(req.body.time)
    q()
      .then ->
        query """
          MATCH (a:Device {uuid: {me}}), (b:Device {uuid: {them}})
          CREATE (m:Meeting {time: {time}, signal: {signalStrength}, interim: {counter}})
          SET a.name = ({name})
          CREATE (a)-[:SCANNED]->(m)<-[:TRANSMITTED]-(b)
          RETURN a, m, b
          """,
          req.body

      .spread ({a, m, b}) ->
        setTimeout (-> res.json result: true), 100
        [a, m, b]

      .spread (a, m, b) ->
        ad = a.data; md = m.data; bd = b.data
        if req.body.geoTime is undefined
          io_api.emit "meeting", a.data, m.data, b.data
        [a, m, b]

      .spread (a, m, b) ->
        if req.body.geoTime
          req.body.mID = m.id
          query """
            START m = node({mID})
            MATCH (a:Device {uuid: {me}}), (b:Device {uuid: {them}})
            MERGE (l:Location {geoTime: {geoTime}, latitude: {latitude}, longitude: {longitude}, accuracy: {accuracy}})
            MERGE (m)-[:TOOK_PLACE_AT]->(l)
            RETURN a, m, b, l
            """, req.body
        else []

      .spread (results) ->
        if results and req.body.geoTime
          {a, m, b, l} = results
          io_api.emit "meeting", a.data, m.data, b.data, l.data

      .fail (err) ->
        log err
        res.send 500

      .done ->
        log req.body

