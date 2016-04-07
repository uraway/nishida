module.exports = (robot) ->
  robot.hear /疲れた/i, (res) ->
    res.reply "頑張って！"

  omikuji = ["大吉", "中吉", "吉", "凶"]
  robot.hear /おみくじ/i, (res) ->
    res.reply res.random omikuji

  enterReplies = ['Hi', 'こんちは', 'Firing', 'Hello friend.', 'Gotcha', 'I see you']
  leaveReplies = ['Are you still there?', '目標を見失いました', 'Searching']
  robot.enter (res) ->
    res.reply res.random enterReplies
  robot.leave (res) ->
    res.reply res.random leaveReplies
