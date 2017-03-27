'use strict';

// import the NLU library
const nlu = require('./nlu.js');

exports.handler = (event, context, callback) => {
  console.log('request for disambiguation');

  let messages = null;

  try {
    if ('messages' in event && event.messages.length > 0) {
      messages = event.messages;
    } else {
      throw new Error('bad request: missing messages key');
    }

    let responseMessages = nlu.call(messages);

    if (responseMessages.length === 0) {
      responseMessages.push(nlu.buildUnstructuredMessage('Sorry, I\'m not sure what you mean. Can you rephrase?'));
    }

    console.log('responding with messages', responseMessages);

    callback(null, {
      messages: responseMessages
    });
  } catch (error) {
    console.log(error);
    // using JSON.stringify, so that API Gateway
    // can use regex to detect the error pattern
    callback(JSON.stringify(error));
  }
};
