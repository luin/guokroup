request = require 'request'
async = require 'async'
mu = require 'mu2'
fs = require 'fs'
http = require 'http'
util = require 'util'

# 要读取的小组ID
groupID = [155, 172, 160, 155, 119, 116, 91, 94, 62, 27, 65, 36, 39, 38, 148, 99, 93, 63, 127, 79, 69, 30, 31]


all = []
task = ->
  nall = []
  antiDuplicate = {}
  async.forEach groupID, (id, next) ->
    request "http://www.guokr.com/group/posts/#{id}/", (err, res, body) ->
      if not body
        next()
        return
      body = body.replace /\n/g, ''
      body = body.replace /\r/g, ''
      belong = body.replace /^.+top-main-n2\"\>[^\>].+?\>([^\<]+?)\<.+$/, "$1"
      result = body.match /ul class=\"titles\"\>.*?ul/
      result = result[0]
      list = result.match /\<li\>.+?\<\/li\>/g
      for data in list
        title = data.match /h2.+h2/
        if not title then continue
        title = title[0].replace /^.+\>.+\>(.+?)\<.+$/, "$1"

        author = data.replace /^.+\<span class=\"titles-b-l\"\>发表：\<a href="[^"]+?" target=\"_blank\"\>(.+?)\<.+$/, "$1"

        lastAuthor = data.replace /^.+\<span class=\"titles-b-r\">最后回应： \<a href=\"[^"]+?">(.+?)\<.+$/, "$1"

        reply = data.replace /^.+\<span class=\"titles-r-grey\"\>(\d+?)\<\/span\>.+$/, "$1"

        time = data.replace /^.+&nbsp;&nbsp;(.+?)\<.+$/, "$1"
        time = time.trim()

        url = data.replace /^.+\/post\/(\d+).+$/, "http://www.guokr.com/post/$1/"
        if antiDuplicate [url] then continue
        antiDuplicate[url] = true

        currentData =
          belong: belong
          belongid: id
          title: title
          author: author
          lastAuthor: lastAuthor
          reply: reply
          time: time
          url: url

        nall.push currentData
      next()

  , ->
    all = nall.sort (x, y) ->
      if x.time < y.time then 1 else -1

task()
setInterval task, 1000 * 60 * 10


http.createServer((req, res) ->
  if process.env.NODE_ENV is 'DEVELOPMENT'
    mu.clearCache()

  stream = mu.compileAndRender 'index.html', items: all
  util.pump stream, res

).listen 8000

