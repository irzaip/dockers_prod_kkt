from flask import Flask

app = Flask(__name__)

@app.route('/')
def index():
	return "<span style='color:red'>Hello from flask (uwsgi)</span>"