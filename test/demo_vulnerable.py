#!/usr/bin/env python3
"""Demo vulnerable Python file for testing"""

import os
import pickle
import subprocess
from flask import Flask, request

app = Flask(__name__)

# Hardcoded secret (Bandit will flag this)
SECRET_KEY = "hardcoded_secret_12345"
app.secret_key = SECRET_KEY

@app.route('/eval')
def unsafe_eval():
    user_code = request.args.get('code', '1+1')
    result = eval(user_code)  # Security issue
    return str(result)

@app.route('/pickle')
def unsafe_pickle():
    data = request.get_data()
    obj = pickle.loads(data)  # Security issue
    return str(obj)

@app.route('/command')
def unsafe_command():
    cmd = request.args.get('cmd', 'ls')
    result = os.system(cmd)  # Security issue
    return f"Exit code: {result}"

@app.route('/subprocess')
def unsafe_subprocess():
    cmd = request.args.get('cmd', 'echo hello')
    result = subprocess.run(cmd, shell=True, capture_output=True, text=True)
    return result.stdout

if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0', port=5000)