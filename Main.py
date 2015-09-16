import wikiscrape
import sys
import re
import regex
import code
from pymongo import MongoClient

client = MongoClient()
db = client.artist_graph

# import psycopg2
#
# try:
#     conn = psycopg2.connect("dbname='template1' user='dbuser' host='localhost' password='dbpass'")
# except:
#     exit("I am unable to connect to postgres.")


def parseField(article_text, label):
    all_acts = []
    big_acts = []

    # code.interact(local=locals())
    if label in article_text:
      matches = regex.search(r''+label+'.*\n(\*.*\n)+', article_text)
      if matches == None:
        # print article_text
        matches = [s.strip() for s in regex.search(r''+label+'.*\n', article_text).group().split('=')[1].split(',')]
      else:
        matches = [regex.search(r'\* *(.*)', m).group() for m in matches.group().split('\n')[1:] if len(m) > 0];
      # print matches

      if matches == None:
        print "WARNING: unhandled parsing situation for article '"+ artist_name +"'"

      act_list = matches

      print act_list
      for a in act_list:
        # print a
        nolink_filter = re.compile(r'\[\[(.*)\]\]')
        filtered = nolink_filter.findall(a)
        print a, '-->', filtered
        if len(filtered) > 0:
          filtered = filtered[0]
          code.interact(local=locals())
          print filtered
          # exit()
          big_acts.append(filtered)
          all_acts.append(filtered)
        else:
          if a.startswith('*'):
            a = a[1:].strip()
          print a
          all_acts.append(a)

      print all_acts
      code.interact(local=locals())
      return (all_acts, big_acts)

def associatedActs(artist_name):
  article_text = wikiscrape.search(artist_name)
  print article_text
  code.interact(local=locals())
  if article_text == None:
    return ([], [], [], [])

  acts = parseField(article_text, 'associated_acts')
  members = parseField(article_text, '[c|C]urrent_members')

  print acts, members
  return (acts[0], acts[1], members[0], members[1])

  all_members = []
  big_members = []
  if 'current_members' in article_text:
    matches = regex.search(r'current_members.*\n(\*.*\n)+', article_text)
    # code.interact(local=locals())
    if matches == None:
      matches = regex.search(r'current_members *=(.*)', article_text)
      matches = matches.group().split('=')[1]

      if '<br' in matches:
        matches = re.split(r'\<br[/ ]*\>', matches)
      else:
        matches = matches.split(',')

      matches = [s.strip() for s in matches]

    if matches == None:
      print "WARNING: unhandled parsing situation for article '"+ artist_name +"'"

    members_list = matches

    for a in members_list:
      # print a
      nolink_filter = regex.findall(r'\[\[(.*)\]\]', a)

      if len(nolink_filter) > 0:
        big_members.append(nolink_filter[0])
      all_filter = regex.findall(r'\[*(.*)\]*', a)

      if len(all_filter) > 0:
        all_members.append(all_filter)

  return (all_acts, big_acts, all_members, big_members)

  # line_regex = re.compile(r'\[\[(.*)\]\]');
  # results = line_regex.search(article_text).group()
  # # print results
  # print results
  # return [r[0] for r in results if r != []]

crawled = []
def crawl(artist, prefix=''):
  crawled.append(artist)

  all_acts, big_acts, all_members, big_members = associatedActs(artist)
  print 'all_acts =', all_acts
  print 'big_acts =', big_acts
  print 'all_members =', all_members
  print 'big_members =', big_members

  if len(all_acts) == 0 and len(all_members) == 0:
    return
  db.artist_graph.insert({'artist' : artist, 'associated' : all_acts, 'members' : all_members})

  if len(big_acts) == 0 and len(big_members) == 0:
    return

  if len(big_members) > 0:
    print prefix + artist + ' is a member of:'
    m_prefix = prefix + ' '
    for a in big_acts:
      print m_prefix + a
      if a not in crawled:
        crawl(a, m_prefix)
      crawled.append(a)
  if len(big_acts) > 0:
    print prefix + artist + ' is associated with:'
    a_prefix = prefix + ' '
    for a in big_acts:
      print a_prefix + a
      if a not in crawled:
        crawl(a, a_prefix)
      crawled.append(a)

if __name__ == '__main__':
  if len(sys.argv) < 2:
    sys.exit('Usage: %s article-title' % sys.argv[0])

  article_title = sys.argv[1]

  crawl(article_title)
