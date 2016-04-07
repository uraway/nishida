MarkovChain = require('markov-chain-kuromoji')
fs = require 'fs'

module.exports = (robot) ->
  robot.hear /(.*)。/g, (res) ->
    markov = new MarkovChain(fs.readFileSync('input.txt', 'utf8'))
    markov.start(1, (output) ->
      output = output.replace /。/, ''
      robot.send {room: "#random"}, "#{output}"
    )
