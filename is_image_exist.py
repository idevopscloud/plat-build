#!/usr/bin/env python
#
# return 0:
#   the image exists
# return 1:
#   the image does not exist
# return -1:
#   other error
#
import sys
from registry import DockerRegistry

if len(sys.argv) != 4:
    print "usage: is_image_exist.py <registry_url> <image> <tag>"
    print "For example: is_image_exist.py 172.30.10.195:5000 facebookpmd_pmdr_snapshots/rulescript-services v1.1"
    sys.exit(1)

registry_url = sys.argv[1]
image_name = sys.argv[2]
tag = sys.argv[3]

ret = 0

try:
    reg = DockerRegistry(registry_url)
    if not reg.is_image_exist(image_name, tag):
        print "NG"
        ret = 1
    else:
        print "OK"
        ret = 0
except Exception, e:
    print e
    ret = -1

sys.exit(ret)

