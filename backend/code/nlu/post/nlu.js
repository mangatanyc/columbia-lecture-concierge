'use strict';

exports = module.exports = {};

const randomizeHello = function() {
  let helloArray = [
    'Hi! How can I help?',
    'Hi there! Need help?',
    'Hello! Let me know what I can help with today',
    'Hi there.'
  ];
  let randomNumber = Math.floor(Math.random() * 4);

  return helloArray[randomNumber];
};

const randomizeGoodbye = function() {
  let goodbyeArray = [
    'Bye!',
    'See you soon.',
    'Goodbye.',
    'Thanks for stopping by.'
  ];
  let randomNumber = Math.floor(Math.random() * 4);

  return goodbyeArray[randomNumber];
};

const randomizeWelcome = function() {
  let welcomeArray = [
    'You\'re welcome',
    'Welcome!',
    'Anytime!',
    'Happy to help.'
  ];
  let randomNumber = Math.floor(Math.random() * 4);

  return welcomeArray[randomNumber];
};

exports.buildUnstructuredMessage = function(text) {
  return {
    type: 'unstructured',
    unstructured: {
      text: text,
      timestamp: new Date().toISOString()
    }
  }
};

exports.buildBuyFlowersStructuredMessage = function() {
  return {
    type: 'structured',
    structured: {
      text: 'I have just the right bouquet. Check it out:',
      type: 'product',
      payload: {
        imageUrl: 'https://....',
        buttonLabel: 'Order',
        clickAction: 'checkout',
        productId: '1234567890'
      },
      timestamp: new Date().toISOString()
    }
  }
};

const disambiguate = function(text) {
  let responses = [];

  if (text.match(/(hi|hello|hey)/gi)) {
    responses.push(exports.buildUnstructuredMessage(randomizeHello()));
  } else if (text.match(/(thanks|thank you|thx)/gi)) {
    responses.push(exports.buildUnstructuredMessage(randomizeWelcome()));
  } else if (text.match(/(goodbye|bye|see you)/gi)) {
    responses.push(exports.buildUnstructuredMessage(randomizeGoodbye()));
  } else if (text.match(/(buy flower|flower|get flower)/gi)) {
    responses.push(exports.buildBuyFlowersStructuredMessage());
  }

  return responses;
};

exports.call = function(messages) {
  console.log('calling NLU');

  let responses = [];

  for (const message of messages) {
    // TODO: implement the capability to respond
    // to structured messages (ex. button presses)
    if (message.type === 'structured') {
      console.log('unhandled');
    } else if (message.type === 'unstructured') {
      let retVal = disambiguate(message.unstructured.text);
      responses = responses.concat(retVal);
    }
  }

  return responses;
};
