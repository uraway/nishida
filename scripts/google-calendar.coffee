# Description
#   A Hubot script for google calendar
#
# Dependencies:
#   None
#
# Configuration:
#   None
#
# Commands:
#   hubot calendar - list up today event
#   hubot calendar <today|tomorrow> - list up today or tomorrow event
#   hubot create an event <event> - creates an event with the given quick add text
#

fs = require('fs')
readline = require('readline')
google = require('googleapis')
googleAuth = require('google-auth-library')
calendar = google.calendar('v3')
moment = require('moment')
SCOPES = [ 'https://www.googleapis.com/auth/calendar' ]
TOKEN_DIR = './.credentials/'
TOKEN_PATH = TOKEN_DIR + 'calendar-api-quickstart.json'
require('twix')

# Create an OAuth2 client with the given credentials, and then execute the
# given callback function.
#
# @param {Object} credentials The authorization client credentials.
# @param {function} callback The callback to call with the authorized client.

authorize = (callback, robot, msg) ->
  clientSecret = "#{process.env.HUBOT_GOOGLE_OAUTH_CLIENT_SECRET}"
  clientId = "#{process.env.HUBOT_GOOGLE_OAUTH_CLIENT_ID}"
  redirectUrl = "urn:ietf:wg:oauth:2.0:oob"
  auth = new googleAuth
  oauth2Client = new (auth.OAuth2)(clientId, clientSecret, redirectUrl)
  # Check if we have previously stored a token.
  fs.readFile TOKEN_PATH, (err, token) ->
    if err
      getNewToken oauth2Client, callback, robot, msg
    else
      oauth2Client.credentials = JSON.parse(token)
      callback oauth2Client, robot, msg
    return
  return

# Get and store new token after prompting for user authorization, and then
# execute the given callback with the authorized OAuth2 client.
#
# @param {google.auth.OAuth2} oauth2Client The OAuth2 client to get token for.
# @param {getEventsCallback} callback The callback to call with the authorized
#     client.

getNewToken = (oauth2Client, callback, robot, msg) ->
  authUrl = oauth2Client.generateAuthUrl(
    access_type: 'offline'
    scope: SCOPES)
  console.log 'Authorize this app by visiting this url: ', authUrl
  rl = readline.createInterface(
    input: process.stdin
    output: process.stdout)
  rl.question 'Enter the code from that page here: ', (code) ->
    rl.close()
    oauth2Client.getToken code, (err, token) ->
      if err
        console.log 'Error while trying to retrieve access token', err
        return
      oauth2Client.credentials = token
      storeToken token
      callback oauth2Client, robot, msg
      return
    return
  return

# Store token to disk be used in later program executions.
#
# @param {Object} token The token to store to disk.

storeToken = (token) ->
  try
    fs.mkdirSync TOKEN_DIR
  catch err
    if err.code != 'EEXIST'
      throw err
  fs.writeFile TOKEN_PATH, JSON.stringify(token)
  console.log 'Token stored to ' + TOKEN_PATH
  return

# Gets the next 10 events on the user's primary calendar.
#
# @param {google.auth.OAuth2} auth An authorized OAuth2 client.

getEvents = (auth, robot, msg) ->
  moment.locale('ja')

  switch msg.match[2] || msg
    when "morning"
      date_ja = "おはようございます！今日"
    when "evening"
      date_ja = "今日もお疲れ様でした。明日"
    when "today"
      date_ja = "今日"
    when "tomorrow"
      date_ja = "明日"
    else
      date_ja = "今日"

  message = "#{date_ja}の予定は\n"

  switch msg.match[2] || msg
    when "morning"
      num = 0
    when "evening"
      num = 1
    when "today"
      num = 0
    when "tomorrow"
      num = 1
    else
      num = 0

  room = if msg.envelope.room then msg.envelope.room else 'random'

  calendar.events.list {
    auth: auth
    calendarId: 'primary'
    timeMin: moment().startOf('day').add(num,'days').toDate().toISOString()
    timeMax: moment().endOf('day').add(num, 'days').toDate().toISOString()
    maxResults: 10
    singleEvents: true
    orderBy: 'startTime'
  }, (err, response) ->
    if err
      console.log 'There was an error contacting the Calendar service: ' + err
      return
    events = response.items
    if events.length == 0
      robot.send {room: room}, "#{message}ありません。"
    else
      i = 0
      while i < events.length
        event = events[i]
        start = event.start.dateTime or event.start.date
        if start.indexOf("T") >= 0
          start = start.split("T")[1].split("+")[0]
          message = "#{message}#{start}に#{event.summary}\n"
        else
          message = "#{message}#{event.summary}\n"
        i++
      robot.send {room: room}, "#{message}です。"
    return
  return

createEvents = (auth, robot, msg) ->
  calendar.events.quickAdd {
    auth: auth
    calendarId: 'primary'
    text: msg.match[2]
  }, (error, event) ->
    if error
      msg.reply "Error while creating an event!"
    else
      range = moment.parseZone(event.start.dateTime || event.start.date).twix(moment.parseZone(event.end.dateTime || event.end.date)).simpleFormat("MMM Do [at] HH:mm")
      location = "" || event.location
      msg.reply """
        OK, I created an event for you:
            #{event.summary} #{event.htmlLink}
            When: #{range}
            Location: #{location}
      """

request = require('request');
cronJob = require('cron').CronJob;

module.exports = (robot) ->
  # 朝の
  cronJob1 = new cronJob(
    cronTime: "0 * 9 * * 1-5" # 秒 分 時 日 月 週
    start: true
    timeZone: "Asia/Tokyo"
    onTick: ->
      authorize getEvents, robot, "morning"
    )
  cronJob2 = new cronJob(
    cronTime: "0 * 17 * * 1-5"
    start: true
    timeZone: "Asia/Tokyo"
    onTick: ->
      authorize getEvents, robot, "evening"
    )

  robot.respond /calendar$/i, (msg) ->
    authorize getEvents, robot, msg

  robot.respond /calendar (today|tomorrow)$/i, (msg) ->
    authorize getEvents, robot, msg

  robot.respond /create (an)? event (.*)/i, (msg) ->
    authorize createEvents, robot, msg
