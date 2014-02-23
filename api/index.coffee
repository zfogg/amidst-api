q = require "q"


module.exports = (app, db, io) ->

  io_dev = io.of "/dev"

  io_api = io.of "/api"


  query = require("../dev/query")(db)

  io_api.on "connection", (socket) ->
    q()
      .then ->
        query "MATCH (d:Device) RETURN d"
      .then (devices) ->
        socket.emit "devices", (dev.d.data for dev in devices)
      .fail (err) ->
        console.log err
        res.send 500

      .done()

    socket.on "query", (id, queryString, queryParams) ->
      q()
        .then ->
          query queryString, queryParams
        .then (results) ->
          console.log results
          socket.emit "query", {id, results}
