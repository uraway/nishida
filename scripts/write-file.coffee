fs = require 'fs'
CronJob = require('cron').CronJob
random = "C0MMEQ0DN"
slack = require 'slack'
token = process.env.SLACK_TOKEN

module.exports = (robot) ->
  robot.respond /学習して/i, (res) ->
    res.reply {room: "#random"}, "学習開始！"
    slack.channels.history({token: token, channel: random}, (err, data) ->
      if err
        res.reply {room: "#random"}, err.error
      else
        for message in data.messages
          if message.type is "message"
            input += "#{message.text}。"
        input = input.replace /\s*/g, ''
        input = input.replace /hasjoinedthechannel/g, ''
        input = input.replace /(https?:\/\/[\x21-\x7e]+)/g, ''
        input = input.replace /</g, ''
        input = input.replace /。。/g, '。'
        fs.writeFile('input.txt', input, (err) ->
          if err
            throw err
          robot.send {room: "#random"}, "学習成功！"
        )
    )
  job = new CronJob({
    cronTime: '00 00 10 * * 1-5' # 秒　分　時　日　月　曜日
    onTick: () ->
      slack.channels.history({token: token, channel: random}, (err, data) ->
        robot.send {room: "#random"}, "学習開始！"
        if err
          robot.send {room: "#random"}, err.error
        else
          input = null
          for message in data.messages
            if message.type is "message"
              input += "#{message.text}。"
          input = input.replace /\s*/g, ''
          input = input.replace /hasjoinedthechannel/g, ''
          input = input.replace /(https?:\/\/[\x21-\x7e]+)/g, ''
          input = input.replace /</g, ''
          input = input.replace /。。/g, '。'
          input = input.replace /null/g, ''
          fs.writeFile('input.txt', input, (err) ->
            if err
              throw err
            robot.send {room: "#random"}, "学習成功！"
          )
      )
    start: true
    timeZone: "Asia/Tokyo"
  })
