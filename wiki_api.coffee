#!/usr/bin/coffee

request = require 'request'
_ = require 'underscore-plus'

params =
  "format":"json"
  "action":"query"
  "prop"  :"revisions"
  "rvprop":"content"

qs =  "action=#{params.action}&prop=#{params.prop}&rvprop=#{params.rvprop}&format=#{params.format}&titles="

removeComments = (articleText) -> articleText.replace  /<!--[\s\S]*?-->/g, ''

getArticle = (title, callback) ->
  console.log "http://en.wikipedia.org/w/api.php?#{qs}#{encodeURIComponent title}"
  request.get
    uri:"http://en.wikipedia.org/w/api.php?#{qs}#{encodeURIComponent title}"
    json: true
    (err, response, body) ->
      if err
        return callback(err, response, body)

      # try
      page = Object.keys body.query.pages

      if page.length == 0
        return callback("no pages found", response, body)

      if page.length == 1
        return verify(response, body.query.pages[page[0]], callback)

      if page.length > 1
        # find the longest page
        max_len = 0
        max_key = undefined
        for num in page
          len = body.query.pages[num].revisions[0]['*'].length
          if len > max_len
            max_key = num
            max_len = len

        if max_key == undefined or body.query.pages[max_key] == undefined or body.query.pages[max_key].revisions == undefined
          return callback "no content found"
        else
          return verify response, body.query.pages[max_key], callback
      # catch err
      #   return callback(err, response, body)

verify = (response, body, callback) ->
  # console.log body
  if /#REDIRECT/.test body.revisions[0]['*']
    return callback "longest page found is a redirect", response, body
  else
    return callback null, response, removeComments body.revisions[0]['*']

if !module.parent
  if process.argv.length > 2
    # use arguments if given
    getArticle process.argv.slice(2), (error, response, body) ->
      if error
        console.log error
      console.log body
  else
    console.log 'Usage: ./wiki_api.coffee #{title}'

module.exports =
  search : getArticle
