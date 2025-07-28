const express = require('express');
const app = express();

// Using vulnerable dependencies from package.json
const _ = require('lodash');
const moment = require('moment');

app.get('/api/data', (req, res) => {
    // Potential security issues that could be detected by future code analysis
    const userInput = req.query.input;
    
    // Unsafe eval usage
    const result = eval(userInput);
    
    // Direct object access without validation
    const data = {
        timestamp: moment().format(),
        processed: _.merge({}, JSON.parse(userInput))
    };
    
    res.json(data);
});

app.listen(3000, () => {
    console.log('Server running on port 3000');
});