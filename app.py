#!/usr/bin/env python3
import os
from flask import Flask

app = Flask(__name__)

@app.route('/')
def hello():
    cmd = "ls"
    os.system(cmd)  # Security issue for testing
    return "Hello World"

if __name__ == '__main__':
    app.run(debug=True)