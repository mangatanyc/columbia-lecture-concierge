$(document).ready(function() {
  var sdk = apigClientFactory.newClient();
  var $messages = $('.messages-content'),
    d, h, m,
    i = 0;

  $(window).load(function() {
    $messages.mCustomScrollbar();
    setTimeout(function() {
      fakeMessage();
    }, 100);
  });

  function updateScrollbar() {
    $messages.mCustomScrollbar("update").mCustomScrollbar('scrollTo', 'bottom', {
      scrollInertia: 10,
      timeout: 0
    });
  }

  function setDate(){
    d = new Date()
    if (m != d.getMinutes()) {
      m = d.getMinutes();
      $('<div class="timestamp">' + d.getHours() + ':' + m + '</div>').appendTo($('.message:last'));
    }
  }

  function callNluApi(message) {
    // params, body, additionalParams
    return sdk.nluPost({}, {
      messages: [{
        type: 'unstructured',
        unstructured: {
          text: message
        }
      }]
    }, {});
  }

  function insertMessage() {
    msg = $('.message-input').val();
    if ($.trim(msg) == '') {
      return false;
    }
    $('<div class="message message-personal">' + msg + '</div>').appendTo($('.mCSB_container')).addClass('new');
    setDate();
    $('.message-input').val(null);
    updateScrollbar();

    callNluApi(msg)
      .then((response) => {
        console.log(response);
        var data = response.data;

        if (data.messages && data.messages.length > 0) {
          console.log('received '+data.messages.length+' messages');

          var messages = data.messages;

          for (var message of messages) {
            if (message.type === 'unstructured') {
              insertUnstructuredMessage(message.unstructured.text);
            } else {
              console.log('not implemented');
            }
          }
        } else {
          insertUnstructuredMessage('Oops, something went wrong. Please try again.');
        }
      })
      .catch((error) => {
        console.log('an error occurred', error);
        insertUnstructuredMessage('Oops, something went wrong. Please try again.');
      });

    // setTimeout(function() {
    //   fakeMessage();
    // }, 1000 + (Math.random() * 20) * 100);
  }

  $('.message-submit').click(function() {
    insertMessage();
  });

  $(window).on('keydown', function(e) {
    if (e.which == 13) {
      insertMessage();
      return false;
    }
  })

  function insertUnstructuredMessage(text) {
    $('<div class="message loading new"><figure class="avatar"><img src="http://flask.com/wp-content/uploads/dos-equis-most-interesting-guy-in-the-world-300x300.jpeg" /></figure><span></span></div>').appendTo($('.mCSB_container'));
    updateScrollbar();

    setTimeout(function() {
      $('.message.loading').remove();
      $('<div class="message new"><figure class="avatar"><img src="http://flask.com/wp-content/uploads/dos-equis-most-interesting-guy-in-the-world-300x300.jpeg" /></figure>' + text + '</div>').appendTo($('.mCSB_container')).addClass('new');
      setDate();
      updateScrollbar();
      i++;
    }, 1000 + (Math.random() * 20) * 100);
  }

  /*
  var Fake = [
    'Hi there, I\'m your personal Concierge. How can I help?',
    'Great. I can help you with that.',
    'Not too bad, thanks',
    'What do you do?',
    'That\'s awesome',
    'Codepen is a nice place to stay',
    'I think you\'re a nice person',
    'Why do you think that?',
    'Can you explain?',
    'Anyway I\'ve gotta go now',
    'It was a pleasure chat with you',
    'Time to make a new codepen',
    'Bye',
    ':)'
  ]

  function fakeMessage() {
    if ($('.message-input').val() != '') {
      return false;
    }
    $('<div class="message loading new"><figure class="avatar"><img src="http://flask.com/wp-content/uploads/dos-equis-most-interesting-guy-in-the-world-300x300.jpeg" /></figure><span></span></div>').appendTo($('.mCSB_container'));
    updateScrollbar();

    setTimeout(function() {
      $('.message.loading').remove();
      $('<div class="message new"><figure class="avatar"><img src="http://flask.com/wp-content/uploads/dos-equis-most-interesting-guy-in-the-world-300x300.jpeg" /></figure>' + Fake[i] + '</div>').appendTo($('.mCSB_container')).addClass('new');
      setDate();
      updateScrollbar();
      i++;
    }, 1000 + (Math.random() * 20) * 100);

  }
  */

});
