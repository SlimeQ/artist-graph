#!/usr/bin/coffee

request = require 'request'
_ = require 'underscore-plus'

params =
  "format":"json"
  "action":"query"
  "prop"  :"revisions"
  "rvprop":"timestamp|user|comment|content"

qs =  "action=#{params.action}&prop=#{params.prop}&rvprop=#{params.rvprop}&format=#{params.format}&titles="

getArticle = (title, callback) ->
  console.log "http://en.wikipedia.org/w/api.php?#{qs}#{encodeURIComponent title}"
  request.get
    uri:"http://en.wikipedia.org/w/api.php?#{qs}#{encodeURIComponent title}"
    json: true
    (err, response, body) ->
      if err
        console.log "response --> "
        console.log response
        console.log "body --> "
        console.log body
        return callback(err)

      max_len = 0
      max_key = undefined
      page = Object.keys body.query.pages
      if page.length > 1
        # console.log page
        for num in page
          # console.log body.query.pages[num].revisions
          if body.query.pages[num].revisions != undefined
            len = body.query.pages[num].revisions[0]['*'].length
            if len > max_len
              max_key = num
              max_len = len
        # console.log max_key
      else
        max_key = page[0]
      if body.query.pages[max_key] == undefined or body.query.pages[max_key].revisions == undefined
        return callback "no content found"
      return callback null, response, body.query.pages[max_key].revisions[0]['*']

if !module.parent
  if process.argv.length > 2
    # use arguments if given
    getArticle process.argv.slice(2), (error, response, body) ->
      if error
        console.log error
      console.log body
  else
    console.log 'Usage: ./wikiscrape.coffee #{title}'

module.exports =
  search : getArticle
