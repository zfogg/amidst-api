express = require "express"

neo4j   = require "neo4j"


app = express()

app.use express.urlencoded()
app.use express.json()
app.use express.cookieParser("secret")
app.use express.cookieSession()


server = app.listen (process.env.PORT or 8000), ->
  console.log "amidst-api: Started!"

io = require("socket.io").listen(server, log: false)

db = new neo4j.GraphDatabase "http://localhost:7474"


app.configure "development", ->
  app.use express.errorHandler()
  app.use express.logger "dev"


app.configure ->
  app.use app.router

  app.all "*", (req, res, next) ->
    res.header "Access-Control-Allow-Origin", "*"
    res.header "Access-Control-Allow-Headers", "X-Requested-With"
    next()

  app.use (req, res, next) ->
    res.set 'Content-Type', 'application/json'
    next()


app.get "/", (req, res) ->
  res.json amidst: true

require("./dev")(app, db, io)

require("./api")(app, db, io)
