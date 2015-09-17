#!/usr/bin/coffee

wiki = require './wiki_api'

removeComments = (articleText) -> articleText.replace  /<!--[\s\S]*?-->/g, ''
parseFlatlist = (lines) ->
  flatlist = []
  lines = lines[1...]

  for i in [0...lines.length]
    line = lines[i]
    if line[0] == '*'
      line = line[1...]
    if line.indexOf("[[") > -1
      flatlist.push
        title : line.trim()[2...-2].split("|")[0].trim()
        link  : true
    else
      flatlist.push
        title : line.trim().split("|")[0].trim()
        link  : false
  return flatlist

parseList = (items) ->
  list = []
  for item in items
    item = item.trim()
    # console.log "item = #{item}"
    if item.indexOf("[[") > -1 and item.indexOf("]]") > -1
      list.push
        "title" : item[2...-2]
        "link" : true
    else
      list.push
        "title" : item
        "link" : false
  return list

blacklist = []
findInfobox = (articleText, callback) ->
  infobox = {}

  trimmed = articleText.substring articleText.indexOf("{{Infobox musical artist")
  if trimmed == -1
    callback "no musician infobox found"
  lines = trimmed.split "\n"

  nest_depth = 0
  end_line = -1
  flatlist_start = -1
  for i in [0...lines.length]
    # console.log i + ") " + lines[i]

    trimmed = lines[i].trim()
    # Infobox property
    if trimmed[0] == "|"
      # console.log lines[i]
      [key, val] = trimmed[1...].split(/\=(.+)?/)
      key = key.trim().toLowerCase()
      if val != undefined and !(key in blacklist)
        val = val.trim()
        # console.log "#{key} : #{val}"
        if key != undefined
          if val.indexOf("{{") > -1 and val.indexOf("flatlist") > -1
            flatlist_start = i
            flatlist_depth = nest_depth
            flatlist_label = key
          else if val.indexOf("<br") > -1
            infobox[key] = parseList(val.split(/<br[ /]*>/))
          else if val.indexOf(",") > -1
            infobox[key] = parseList(val.split(","))
          else
            if val.match(/^\[\[/) and val.match(/\]\]$/)
              val =
                title : val[1...].trim()
                link  : true
            else
              val =
                title : val.trim()
                link  : false
            if val != ""
              infobox[key] = val

          # console.log "#{key} --> "
          # console.log infobox[key]


    left_i = lines[i].indexOf "{{"
    right_i = lines[i].indexOf "}}"

    if left_i > -1
      nest_depth++
    if right_i > -1
      nest_depth--
    # console.log "nest_depth=#{nest_depth}, flatlist_depth=#{flatlist_depth}"
    if nest_depth == flatlist_depth
      # console.log 'case1'
      infobox[flatlist_label] = parseFlatlist lines[flatlist_start...i]
      flatlist_depth = undefined
    if flatlist_depth != undefined and lines[i].indexOf("{{endflatlist}}") > -1
      # console.log 'case2'
      infobox[flatlist_label] = parseFlatlist lines[flatlist_start...i+1]
      flatlist_depth = undefined
    if nest_depth == 0
      end_line = i
      break

  return callback null, infobox


crawled_list = []
crawl = (title, collection, callback, stack) ->
  # console.log stack
  if stack == undefined
    stack = [title]

  if stack.length == 0
    return callback("done!")

  # get next artist off the stack
  title = stack.pop()
  while title in crawled_list
    title = stack.pop()
  console.log title
  if title == undefined
    return continueCrawl(undefined, collection, callback, stack);
  wiki.search title, (error, response, body) ->
    if error
      console.log "err in wiki.search: #{error}"
      return continueCrawl(undefined, collection, callback, stack)

    if body.indexOf("#REDIRECT") > -1
      return continueCrawl(undefined, collection, callback, stack)
    # else
    # parse
    # console.log body

    body = removeComments body
    findInfobox body, (err, infobox) ->
      if error
        console.log error
        return continueCrawl(undefined, collection, callback, stack)
      if infobox == undefined or infobox == {}
        return continueCrawl(undefined, collection, callback, stack)

      console.log infobox
      # save to mongodb
      save(collection, infobox, infobox.name)

      crawled_list.push title
      if infobox.associated_acts != undefined
        # console.log(infobox.associated_acts)
        for act in infobox.associated_acts
          if act.title != undefined and act.link == true
            if !(act.title in crawled_list)
              # console.log "pushing " + act.title
              stack.push act.title
      if infobox.current_members != undefined
        for member in infobox.current_members
          if member.title != undefined and member.link == true
            if !(member.title in crawled_list)
              # console.log "pushing " + member.title
              stack.push member.title
      if infobox.past_members != undefined
        for member in infobox.past_members
          if member.title != undefined and member.link == true
            if !(member.title in crawled_list)
              # console.log "pushing " + member.title
              stack.push member.title
      console.log "stacklen = #{stack.length}"
      continueCrawl(undefined, collection, callback, stack)

continueCrawl = (title, coll, cb, stack) ->
  console.log stack
  if stack.length == 0
    return cb("done!")
  else
    return crawl(title, coll, cb, stack);



mongo = require 'mongodb'

server = new mongo.Server "127.0.0.1", 27017, {}
client = new mongo.Db 'artist-graph', server, {w:1}

# save() updates existing records or inserts new ones as needed
save = (collection, item, id) ->
  item._id = id
  console.log "Saving item -->"
  console.log item
  collection.save item, (err, docs) ->
    console.log "Unable to save record: #{err}" if err
    # console.log docs
    # client.close()

#-----------------------------------
# do this when run from command line
# ----------------------------------
# if __name__ == '__main__':
if !module.parent
  #check args
  if process.argv.length > 2

    # keep an open db connection
    client.open (err, database) ->
      database.collection 'infobox', (dbErr, collection) ->
        if dbErr
          console.log "Unable to access database: #{dbErr}"
          client.close()
        else
          # use arguments if given
          crawl process.argv[2], collection, (ret) ->
            console.log ret
            client.close()
  else
    console.log 'Usage: ./main.coffee #{title}'

# module.exports =
#   parse
