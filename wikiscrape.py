import lxml.etree
import urllib

import sys

def search(title):
  params = { "format":"xml", "action":"query", "prop":"revisions", "rvprop":"timestamp|user|comment|content" }
  params["titles"] = "API|%s" % urllib.quote(title.encode("utf8"))
  qs = "&".join("%s=%s" % (k, v)  for k, v in params.items())
  url = "http://en.wikipedia.org/w/api.php?%s" % qs
  print url
  tree = lxml.etree.parse(urllib.urlopen(url))
  revs = tree.xpath('//rev')
  # i = 0
  # for r in revs:
  #   print i
  #   print r.text
  #   i += 1

  for r in revs:
    # print r.text
    if "#REDIRECT" not in r.text:
      return r.text

if __name__ == '__main__':
  if len(sys.argv) < 2:
    sys.exit('Usage: %s article-title' % sys.argv[0])

  title = sys.argv[1]
  article = search(title)
  print "The Wikipedia text for", title, "is"
  print article
