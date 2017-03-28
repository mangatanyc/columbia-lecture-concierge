'use strict';

const AWS = require('aws-sdk');

const SNS = new AWS.SNS({ region: process.env.stage });
const SQS = new AWS.SQS({ apiVersion: '2012-11-05' });
const Lambda = new AWS.Lambda({ apiVersion: '2015-03-31' });


// Your queue URL stored in the queueUrl environment variable
const QUEUE_URL = process.env.queueUrl;
const PROCESS_MESSAGE = 'process-message';


function invokePoller(functionName, message) {
    const payload = {
        operation: PROCESS_MESSAGE,
        message,
    };
    const params = {
        FunctionName: functionName,
        InvocationType: 'Event',
        Payload: new Buffer(JSON.stringify(payload)),
    };
    return new Promise((resolve, reject) => {
        Lambda.invoke(params, (err) => (err ? reject(err) : resolve()));
    });
}

const sendSmsNotification = function(message) {
  console.log('sending SMS notification');

  return new Promise((resolve, reject) => {
    SNS.publish({
      Message: 'Thank you for your order! Your confirmation number is ' + (Math.floor(1000000 + Math.random() * 9000000)) + '. We\'ll send you another email once it shipped.',
      PhoneNumber: process.env.phoneNumber
    }, (err) => err ? reject(err) : resolve());
  });
};

function processMessage(message, callback) {
    console.log(message);

    // TODO process message
    sendSmsNotification(message)
        .then(() => {
            // delete message
            const params = {
                QueueUrl: QUEUE_URL,
                ReceiptHandle: message.ReceiptHandle,
            };
            SQS.deleteMessage(params, (err) => callback(err, message));
        })
        .catch((error) => {
          console.log('error', error);
        })
}

function poll(functionName, callback) {
    const params = {
        QueueUrl: QUEUE_URL,
        MaxNumberOfMessages: 10,
        VisibilityTimeout: 10,
    };
    // batch request messages
    SQS.receiveMessage(params, (err, data) => {
        if (err) {
            return callback(err);
        }
        if (!data.Messages) data.Messages = [];
        // for each message, reinvoke the function
        const promises = data.Messages.map((message) => invokePoller(functionName, message));
        // complete when all invocations have been made
        Promise.all(promises).then(() => {
            const result = `Messages received: ${data.Messages.length}`;
            console.log(result);
            callback(null, result);
        });
    });
}

exports.handler = (event, context, callback) => {
    try {
        if (event.operation === PROCESS_MESSAGE) {
            // invoked by poller
            processMessage(event.message, callback);
        } else {
            // invoked by schedule
            poll(context.functionName, callback);
        }
    } catch (err) {
        callback(err);
    }
};
