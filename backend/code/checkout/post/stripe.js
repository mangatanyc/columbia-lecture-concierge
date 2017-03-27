'use strict';

exports = module.exports = {};

exports.checkout = function(request) {
  console.log('checking out with Stripe');

  // TODO: integrate with Stripe here
  // out of scope for the demo

  return new Promise((resolve, reject) => {
    resolve({
      success: true
    });
  });
};
