#!/usr/bin/coffee

findInfobox = (articleText, callback) ->
  infobox = {}

  trimmed = articleText.substring articleText.indexOf("{{Infobox musical artist")

  lines = trimmed.split("\n")
  for i in [0...lines.length]
    console.log lines.length

if !module.parent
  wiki = require './wiki_api'

  if process.argv.length > 2
    # use arguments if given
    title = process.argv[2]
    console.log "searching for --> #{title}"
    wiki.search title, (error, response, body) ->
      if error
        console.log error
      console.log body
  else
    console.log 'Usage: ./infobox.coffee #{title}'

module.exports =
  findInfobox : findInfobox
