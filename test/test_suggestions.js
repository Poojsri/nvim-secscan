// Test file for JavaScript security suggestions

// Test eval() usage - should suggest JSON.parse()
const userInput = '{"key": "value"}';
const result = eval(userInput);

// Test innerHTML usage - should suggest textContent
document.getElementById('content').innerHTML = userInput;

// Test document.write() - should suggest DOM manipulation
document.write('<p>Hello World</p>');

console.log('This file demonstrates insecure JavaScript patterns');