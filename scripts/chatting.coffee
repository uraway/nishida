module.exports = (robot) ->
  robot.hear /疲れた/i, (res) ->
    res.send "頑張って！"

  omikuji = ["大吉", "中吉", "吉", "凶"]
  robot.hear /おみくじ/i, (res) ->
    res.send res.random omikuji
