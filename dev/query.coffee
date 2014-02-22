q = require "q"


module.exports = (db) ->
  (queryString, data) ->
    d = q.defer()

    db.query queryString, data , (err, node) ->
      if err
      then d.reject err
      else d.resolve node

    return d.promise
