CronJob = require('cron').CronJob

module.exports = (robot) ->
  message = "おはようございます。\n今日の予定は\n"
  meeting = "火曜日3限にB408でミーティング"
  job = new CronJob({
    cronTime: '0 0 9 * * 2' # 秒　分　時　日　月　曜日
    onTick: () ->
      robot.send {room: "#general"}, "#{message} #{meeting}です！"
    start: true
    timeZone: "Asia/Tokyo"
  })
