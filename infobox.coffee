#!/usr/bin/coffee

newElement = (name) ->
  name : name
  children : []
  data : {}

prettyPrint = (root, prefix) ->
  if !prefix
    prefix = ""
  console.log "#{prefix}#{root.name}-->"
  prefix += "  "
  console.log "#{prefix}data-->"
  prefix += "  "
  for own key of root.data
    console.log "#{prefix}#{key} : #{root.data[key]}"
  console.log "#{prefix[0...-2]}children-->"
  if root.children.length > 0
    for child in root.children
      prettyPrint child, prefix


leadingWhitespaceRx = /^(\s)*/

tagOpenRegex = /.*{{([^\|}]*)[^\}]*$/
tagCloseRegex = /^\s*}}\s*/

elementRegex = /{{[^}]*}}/g
linkRegex = /\[\[([^\]]*)\]\]/g
keyvalRegex = /^\s*\|\s*([\S].*[\S])\s*=\s*(.*)\s*$/

multilineListRx = /^[*\s]*([^=}]*)$/m
# get the infobox for a given article (in raw text form)
findInfobox = (articleText, callback) ->
  # infobox = {}

  # trimmed = articleText.substring articleText.indexOf("{{Infobox")

  stack = [newElement "article"]
  return console.log articleText.match("\n")
  lines =  articleText.split("\n")
  # console.log lines
  line_index = 0
  try
    for i in [0...lines.length]
      line = lines[i].trim()

      currentNode = stack.pop()

      parsedLine = {original : line}

      tagOpen = line.match tagOpenRegex
      if tagOpen?
        parsedLine.tagOpen = tagOpen[1]
        stack.push currentNode
        currentNode = newElement tagOpen[1]

      if tagCloseRegex.test line
        console.log "tagclosed match --> #{line}"
        parent = stack.pop()
        parent.children.push currentNode
        currentNode = parent

      elements = line.match elementRegex
      if elements?
        parsedLine.elements = elements

      links = line.match linkRegex
      if links?
        parsedLine.links = links

      keyval = line.match keyvalRegex
      if keyval?
        console.log keyval
        if keyval[1] isnt '' and keyval[2] isnt ''
          if tagOpen
            console.log articleText[line_index...]
            currentNode.data[keyval[1]] = articleText[line_index...].match multilineListRx
          parsedLine.keyval = [keyval[1], keyval[2]]
          currentNode.data[keyval[1]] = keyval[2]
      console.log parsedLine

      stack.push currentNode
      line_index += lines[i].length

  catch e
    console.log e
  prettyPrint stack[0]



#################################################################





# ____MAIN____
if !module.parent
  wiki = require './wiki_api'

  if process.argv.length > 2
    # use arguments if given
    title = process.argv[2]
    console.log "searching for --> #{title}"
    wiki.search title, (error, response, body) ->
      if error
        console.log error

      findInfobox body, (err, infobox) ->
        if err
          return console.log "ERROR: #{err}"

        console.log infobox
  else
    console.log 'Usage: ./infobox.coffee #{title}'

module.exports =
  findInfobox : findInfobox
