'use strict';

exports = module.exports = {};

// a mock Stripe library

exports.checkout = function(request) {
  console.log('checking out with Stripe');

  // TODO: integrate with Stripe here
  // out of scope for the demo

  return new Promise((resolve, reject) => {
    setTimeout(function() {
      resolve({
        success: true
      });
    }, 2000);
  });
};
