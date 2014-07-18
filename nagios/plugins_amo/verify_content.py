#!/usr/bin/env python
import sys, os, time, httplib, urllib2, hashlib
from xml.dom.minidom import parseString

SERVER_URL = 'primary.xdev.tango.me:8080'    # local environment.

def hashfile(filename, hasher, blocksize=65536): 
  afile = open(filename, "r")
  
  buf = afile.read(blocksize)
  while len(buf) > 0:
    hasher.update(buf)
    buf = afile.read(blocksize)
    
  afile.close()
  return hasher.hexdigest()

def downloadFile(url,file_path):
  print url + " +--> " + file_path
  u = urllib2.urlopen(url)
  localFile = open(file_path, 'w')
  localFile.write(u.read())
  localFile.close()

def makeRequest(username, server_url, scenario, action, platform_code):
  connection = httplib.HTTPConnection(server_url, timeout=90)
  header = { 'Content-Type': 'text/xml', 'Charset': 'UTF-8' }
  body = scenario

  try:
    connection.request("POST", "/multimediaassetmanager/" + username + "/" + action + "/", body, header)
    response = connection.getresponse()

    data = response.read()

    if response.status == 200:
      return data
    else:
      print 'status: ' + response.status + 'response: ' + data + '\n'
      return 'FAILED'
              
  except SystemExit:
    pass
  except:
    print "Unable to make request: Unexpected error:", sys.exc_info()[0]
    sys.exit(2)            

def parseCatalog(catalog, filemap):
  dom = parseString(catalog)
  for node_asset in dom.getElementsByTagName('asset'):

    filename = None
    filesize = 0
    filechksum = None
    fileuri = None

    # only one element expected
    for node_uri in node_asset.getElementsByTagName('contentURI'):
      fileuri = node_uri.firstChild.nodeValue
      parts = fileuri.split('/')
      filename = parts[len(parts)-1] 

    if fileuri is not None:
      # only one element expected
      for node_size in node_asset.getElementsByTagName('contentLength'):
        filesize = node_size.firstChild.nodeValue

      # only one element expected
      for node_chksum in node_asset.getElementsByTagName('contentChecksum'):
        filechksum = node_chksum.firstChild.nodeValue

    # some assets (like BUNDLE) may not have content, so we skip them
    if filename is not None and filename not in filemap:
      filemap[filename]={"uri":fileuri,"size":filesize,"checksum":filechksum}

username = 'nagios'    

request_template = '<assetCatalogRequest xmlns=\"com:tango:multimedia:assetcatalog:jaxb:v1\" version=\"1.0\"><assetType>ALL</assetType><assetState>RELEASE</assetState><platformCode>%d</platformCode><locale>en_US</locale><maxResultsLimit>1000</maxResultsLimit><contentVersionMax>1.0</contentVersionMax><attributeFilter xmlns=\"com:tango:multimedia:assetcatalog:jaxb:v1\"><assetType>ANIMATION_PACK</assetType><name>ENGINE</name><value>CAFE</value></attributeFilter><attributeFilter xmlns=\"com:tango:multimedia:assetcatalog:jaxb:v1\"><assetType>ANIMATION_PACK</assetType><name>CAPABILITY</name><value>CINEMATIC</value></attributeFilter></assetCatalogRequest>'

# Android = 0 
# iOS = 1

platform_codes = [ 0, 1 ]

filemap = {}

if (len(sys.argv) > 3):
  SERVER_URL = sys.argv[1]
  SERVER_URL = SERVER_URL + ":" + str(sys.argv[2])
  OUTPUT = sys.argv[3]
else:
  print 'Usage: <server> <port> <content download directory>'
  sys.exit()

print "removing files in " + OUTPUT

# clean up
for f in os.listdir(OUTPUT):
  os.remove(os.path.join(OUTPUT,f))

for code in platform_codes:
  print 'processing platform code ' + str(code)
  request = request_template % (code)
  result = makeRequest(username, SERVER_URL, request, 'assetcatalog', code)

  parseCatalog(result, filemap)

print "downloading files..."

for filename in filemap.keys():
  downloadFile(filemap[filename]['uri'], OUTPUT + "/" + filename)

print "verifying files\' state..."

for filename in os.listdir(OUTPUT):
  ofile = os.path.join(OUTPUT,filename)
  
  if os.path.isdir(ofile) == False:   
    checksum = hashfile( ofile, hashlib.sha256() ) 
    size = os.path.getsize(ofile)

    print "  " + filename 

    if filemap[filename]['size'] == str(size):
      print "  size : OK"
    else:
      print "  size : MISMATCH"

    if filemap[filename]['checksum'] == checksum:
      print "  checksum : OK"
    else:
      print "  checksum : MISMATCH"
      print "	expected:", filemap[filename]['checksum'], " actual:", checksum

print
print "Done"
