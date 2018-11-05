#from flask import Flask, request
from pprint import pprint
import uwsgi
import os

#app = Flask(__name__)
#app.debug = True

#@app.route('/')
#def index():
#	return "<span style='color:red'>Hello from flask (uwsgi)</span>"

def xsendfile(e, sr):
    sr('200 OK', [('Content-Type', 'image/png'), ('X-Sendfile', os.path.abspath('logo_uWSGI.png'))])
    return b''


def serve_logo(e, sr):
    sr('200 OK', [('Content-Type', 'image/png')])
    return uwsgi.sendfile('logo_uWSGI.png')


def serve_config(e, sr):
    sr('200 OK', [('Content-Type', 'text/html')])
    for opt in uwsgi.opt.keys():
        body = "{opt} = {optvalue}<br/>".format(opt=opt, optvalue=uwsgi.opt[opt].decode('ascii'))
        yield bytes(body.encode('ascii'))

routes = {}
routes['/test/xsendfile'] = xsendfile
routes['/test/logo'] = serve_logo
routes['/test/config'] = serve_config


def application(env, start_response):

    if env['PATH_INFO'] in routes:
        return routes[env['PATH_INFO']](env, start_response)

    start_response('200 OK', [('Content-Type', 'text/html')])

    body = """
<img src="/test/logo"/> version {version}<br/>
<hr size="1"/>

Configuration<br/>
<iframe src="/test/config"></iframe><br/>

<br/>

    """.format(version=uwsgi.version.decode('ascii'))

    return bytes(body.encode('ascii'))
