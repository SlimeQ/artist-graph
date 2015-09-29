#!/usr/bin/coffee

findCitationNeeded = (articleText, callback) ->
  regex = /{{citation needed\|[^}]*}}/gi
  matches = articleText.match regex
  console.log matches

#################################################################

# ____MAIN____
if !module.parent
  wiki = require './wiki_api'

  if process.argv.length > 2
    # use arguments if given
    title = process.argv[2]
    console.log "searching for --> #{title}"
    wiki.search title, (err, response, body) ->
      if err
        return console.log err
      findCitationNeeded body, (err, citation_needed) ->
        console.log citation_needed


  else
    console.log 'Usage: ./citation_needed.coffee #{title}'

module.exports =
  findCitationNeeded : findCitationNeeded
