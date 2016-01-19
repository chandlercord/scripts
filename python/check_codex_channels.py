#!/usr/bin/python

import sys, time, subprocess
import argparse, json
from Crypto.Cipher import Blowfish
from struct import pack



def get_args():
    parser = argparse.ArgumentParser()
    parser.add_argument('-c', '--callsign', dest='callsign', required=True, default = None)
    parser.add_argument('-j', '--json_file', dest='json_file', required=True, default=None, help="name json file to read key and iv from")
    args = parser.parse_args()
    
    return args


# get meta.json for the callsign
def get_meta(callsign, key, iv, video_url):
    url = "callsign/%s/meta.json" % (callsign)
    
    try:
        bs = Blowfish.block_size
        cipher = Blowfish.new(key, Blowfish.MODE_CBC, iv)
        plen = bs - divmod(len(url),bs)[1]
        padding = [plen]*plen
        padding = pack('b'*plen, *padding)
        msg = cipher.encrypt(url + padding)
    except Exception as e:
        sys.stderr.write("Could not mangle url %s; got: %s" % (url, e))
        return -1
    url =  video_url + msg.encode('hex_codec')
    cmd = 'curl "%s"' % (url)
    p = subprocess.Popen(cmd, stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.PIPE, shell = True)
    ret = p.wait()
    stdoutdata, stderrdata = p.communicate()
    if ret:
        sys.stderr.write("Error: could not get duration for channel %s; got error %s\n" % (callsign, stderrdata))
    try:
        meta = json.loads(stdoutdata)
        return  int(meta["duration"])
    except Exception:
        sys.stderr.write("Error: could not get duration for channel %s; meta json output: %s\n" % (callsign, stdoutdata))
        return -1

if __name__ == "__main__":
    args = get_args()
    args.callsign = args.callsign.strip() # this is because Zabbix adds spaces
    with open(args.json_file.strip()) as fd:
        config = json.load(fd)
    key  = config["streaming_server"]["key"].decode("hex")
    iv  = config["streaming_server"]["iv"].decode("hex")
    url = config["videoUrl"]
    duration1 = get_meta(args.callsign, key, iv, url) # get the duration
    time.sleep(2)
    duration2 = get_meta(args.callsign, key, iv, url) 
    if duration2 <= duration1 or duration2 < 0 or duration1 < 0:
        sys.stdout.write("1")
        sys.stderr.write("Error: duration not increasing for channel %s\n" % args.callsign)
        sys.exit(1)
    sys.stdout.write("0")