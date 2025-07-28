#!/usr/bin/env python3
"""
Test file for security suggestions feature
This file contains various insecure patterns that should trigger suggestions
"""

import os
import pickle
import random
import subprocess

# Test eval() usage - should suggest ast.literal_eval()
user_input = "{'key': 'value'}"
result = eval(user_input)

# Test exec() usage - should suggest avoiding exec()
code = "print('hello')"
exec(code)

# Test pickle.loads() - should suggest json.loads()
data = b"some_pickled_data"
obj = pickle.loads(data)

# Test os.system() - should suggest subprocess.run()
command = "ls -la"
os.system(command)

# Test subprocess with shell=True - should suggest shell=False
subprocess.run("echo hello", shell=True)

# Test random.random() for crypto - should suggest secrets.SystemRandom()
secret_key = str(random.random())

print("This file demonstrates insecure patterns for testing suggestions")