from flask import Flask, request, render_template
import logging

app = Flask(__name__)
app.debug = True

@app.route('/test2/')
def index():
    return render_template('index.html')
