fs = require('fs')
readline = require('readline')
google = require('googleapis')
googleAuth = require('google-auth-library')
calendar = google.calendar('v3')
SCOPES = [ 'https://www.googleapis.com/auth/calendar.readonly' ]
TOKEN_DIR = (process.env.HOME or process.env.HOMEPATH or process.env.USERPROFILE) + '/.credentials/'
TOKEN_PATH = TOKEN_DIR + 'calendar-api-quickstart.json'

# Create an OAuth2 client with the given credentials, and then execute the
# given callback function.
#
# @param {Object} credentials The authorization client credentials.
# @param {function} callback The callback to call with the authorized client.

authorize = (callback, robot) ->
  clientSecret = process.env.HUBOT_GOOGLE_OAUTH_CLIENT_ID
  clientId = process.env.HUBOT_GOOGLE_OAUTH_CLIENT_SECRET
  redirectUrl = "urn:ietf:wg:oauth:2.0:oob"
  auth = new googleAuth
  oauth2Client = new (auth.OAuth2)(clientId, clientSecret, redirectUrl)
  # Check if we have previously stored a token.
  fs.readFile TOKEN_PATH, (err, token) ->
    if err
      getNewToken oauth2Client, callback, robot
    else
      oauth2Client.credentials = JSON.parse(token)
      callback oauth2Client, robot
    return
  return

# Get and store new token after prompting for user authorization, and then
# execute the given callback with the authorized OAuth2 client.
#
# @param {google.auth.OAuth2} oauth2Client The OAuth2 client to get token for.
# @param {getEventsCallback} callback The callback to call with the authorized
#     client.

getNewToken = (oauth2Client, callback, robot) ->
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
      callback oauth2Client, robot
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

getEvents = (auth, robot) ->
  moment.locale('ja')

  message = "おはようございます！\n今日の予定は\n"

  calendar.events.list {
    auth: auth
    calendarId: 'primary'
    timeMin: moment().startOf('day').toDate().toISOString()
    timeMax: moment().endOf('day').toDate().toISOString()
    maxResults: 10
    singleEvents: true
    orderBy: 'startTime'
  }, (err, response) ->
    if err
      console.log 'There was an error contacting the Calendar service: ' + err
      return
    events = response.items
    if events.length == 0
      # console.log 'No upcoming events found.'
      robot.send {room: "#general"}, "#{message}ありません。"
    else
      # console.log 'Upcoming 10 events:'
      i = 0
      while i < events.length
        event = events[i]
        start = event.start.dateTime or event.start.date
        # setting time?
        if start.indexOf("T") >= 0
          start = start.split("T")[1].split("+")[0]
          message = "#{message}#{start}に#{event.summary}\n"
        else
          message = "#{message}#{event.summary}\n"
        i++
      # console.log "#{message}があります。"
      robot.send {room: "#bot-test"}, "#{message}です。"
    return
  return


# hubot部分
request = require('request');
cronJob = require('cron').CronJob;

module.exports = (robot) ->
  # 朝の
  cronJob = new cronJob(
    cronTime: "00,30 * * * * *" # 秒 分 時 日 月 週
    start: true # すぐに実行するか
    timeZone: "Asia/Tokyo"
    onTick: ->
      authorize getEvents, robot
    )
