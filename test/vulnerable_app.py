#!/usr/bin/env python3
import os
import subprocess
import pickle
from flask import Flask, request

app = Flask(__name__)

# Hardcoded secret key (security issue)
app.secret_key = "hardcoded_secret_123"

@app.route('/upload', methods=['POST'])
def upload_file():
    # Unsafe deserialization
    data = request.get_data()
    obj = pickle.loads(data)  # Bandit will flag this
    return str(obj)

@app.route('/exec')
def execute_command():
    # Command injection vulnerability
    cmd = request.args.get('cmd', 'ls')
    result = os.system(cmd)  # Bandit will flag this
    return f"Command executed: {result}"

@app.route('/sql')
def sql_query():
    # SQL injection (simulated)
    user_id = request.args.get('id')
    query = f"SELECT * FROM users WHERE id = {user_id}"  # Unsafe string formatting
    return query

if __name__ == '__main__':
    # Debug mode in production (security issue)
    app.run(debug=True, host='0.0.0.0')  # Bandit will flag this