'use strict';

let AWS = require('aws-sdk');
let sns = new AWS.SNS({
  region: 'us-east-1'
});
let stripe = require('./stripe.js');

const sendSmsNotification = function(message) {
  console.log('sending SMS notification');

  return new Promise((resolve, reject) => {
    sns.publish({
      Message: message,
      PhoneNumber: process.env.phoneNumber
    }, (err) => err ? reject(err) : resolve());
  });
};

exports.handler = (event, context, callback) => {
  console.log('checkout process start');

  let request = {
    userId: '',
    productId: '',
    deliveryAddress: '',
    deliveryDate: ''
  };

  try {
    // if (event.userId) {
    //   request.userId = event.userId;
    // } else {
    //   throw new Error('unauthorized');
    // }

    if (event.productId) {
      request.productId = event.productId;
    } else {
      throw new Error('bad request: missing productId key');
    }

    if (event.deliveryAddress) {
      request.deliveryAddress = event.deliveryAddress;
    } else {
      throw new Error('bad request: missing deliveryAddress key');
    }

    if (event.deliveryDate) {
      request.deliveryDate = event.deliveryDate;
    } else {
      throw new Error('bad request: missing deliveryDate key');
    }

    let statusMessage = '';
    let success = false;
    stripe.checkout(request)
      .then((result) => {
        success = result.success;

        if (result.success) {
          statusMessage = 'Your order has been placed successfully. I\'ll send you a confirmation soon.';
        } else {
          statusMessage = 'I experienced some issues while processing your order. Please try again later';
        }

        return sendSmsNotification('Thank you for your order! Your confirmation number is '+(Math.floor(1000000+Math.random()*9000000))+'. We\'ll send you another email once it shipped.');
      })
      .then((result) => {
        console.log('responding with status message', statusMessage);

        callback(null, {
          success: success,
          message: statusMessage
        });
      });
  } catch (error) {
    console.log(error);
    callback(error);
  }
};
