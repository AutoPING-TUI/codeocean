$(document).on('turbolinks:load', function(event) {

  //Merge all editor components.
  $.extend(
      CodeOceanEditor,
      CodeOceanEditorAJAX,
      CodeOceanEditorEvaluation,
      CodeOceanEditorFlowr,
      CodeOceanEditorSubmissions,
      CodeOceanEditorTurtle,
      CodeOceanEditorWebsocket,
      CodeOceanEditorPrompt,
      CodeOceanEditorRequestForComments
  );

  if ($('#editor').isPresent() && CodeOceanEditor && event.originalEvent.data.url.includes("/implement")) {
    // This call will (amon other things) initializeEditors and load the content except for the last line
    // It must not be called during page navigation. Otherwise, content will be duplicated!
    // Search for insertFullLines and Turbolinks reload / cache control
    CodeOceanEditor.initializeEverything();
  }

  let isMouseDownHorizontal = 0
  $('#resizerHorizontal').on('mousedown', mouseDownHorizontal)

  function mouseDownHorizontal(event) {
    isMouseDownHorizontal = 1
    document.body.addEventListener('mousemove', mouseMoveHorizontal)
    document.body.addEventListener('mouseup', mouseUpHorizontal)
  }

  function mouseMoveHorizontal(event) {
    if (isMouseDownHorizontal === 1 && event.clientX <= 0.7 * window.innerWidth && event.clientX >= 0.2 * window.innerWidth) {
      event.preventDefault();
      $('#panel-left').css('width', (event.clientX - $('#panel-left').offset().left) + "px")
      CodeOceanEditor.resizeSidebars()
      CodeOceanEditor.resizeHorizontalResizer()
    } else {
      mouseUpHorizontal()
    }
  }
  
  function mouseUpHorizontal(event) {
    isMouseDownHorizontal = 0
    document.body.removeEventListener('mouseup', mouseUpHorizontal)
    resizerHorizontal.removeEventListener('mousemove', mouseMoveHorizontal)
  }

  let isMouseDownVertical = 0
  $('#resizerVertical').on('mousedown', mouseDownVertical)

  function mouseDownVertical(event) {
    isMouseDownVertical = 1
    document.body.addEventListener('mousemove', mouseMoveVertical)
    document.body.addEventListener('mouseup', mouseUpVertical)
  }

  function mouseMoveVertical(event) {
    if (isMouseDownVertical === 1) {
      event.preventDefault();
      $('.panel-top').css('height', (event.clientY - $('.panel-top').offset().top - $('#statusbar').height()) + "px")
      $('.panel-bottom').height(CodeOceanEditor.calculateEditorHeight('.panel-bottom', false));
      CodeOceanEditor.resizeSidebars()
      CodeOceanEditor.resizeHorizontalResizer()
    } else {
      mouseUpVertical()
    }
  }

  function mouseUpVertical(event) {
    isMouseDownVertical = 0
    document.body.removeEventListener('mouseup', mouseUpVertical)
    resizerVertical.removeEventListener('mousemove', mouseMoveVertical)
  }
  
  function handleThemeChangeEvent(event) {
    if (CodeOceanEditor) {
      CodeOceanEditor.THEME = event.detail.currentTheme === 'dark' ? 'ace/theme/tomorrow_night' : 'ace/theme/tomorrow';
      document.dispatchEvent(new Event('theme:change:ace'));
    }
  }

  $(document).on('theme:change', handleThemeChangeEvent.bind(this));
});

$(document).on('click', '.ai-feedback-link', function (e) {
  e.preventDefault();

  const testrunId = $(this).data('testrun_id');
  const $button = $(this);

  if (!testrunId) {
    alert("No Testrun ID available for this feedback.");
    return;
  }

  $.ajax({
    url: `/submissions/testrun_ai_feedback`,
    type: 'POST',
    data: { testrun_id: testrunId },
    beforeSend: function () {
      $button.html(
          '<div class="spinner-border spinner-border-sm" role="status"><span class="visually-hidden">Loading...</span></div>'
      );
      $button.prop('disabled', true);
    },
    success: function (response) {
      // Find the card containing the button
      const card = $button.closest('.card');

      if (card.length) {
        // Update the feedback message in the card
        card.find('.row .col-md-9').eq(2).html(response);

        // Hide or remove the button after feedback is displayed
        $button.remove();
      } else {
        console.error("Card not found for testrun_id:", testrunId);
      }
    },
    error: function (xhr) {
      alert(`Failed to fetch feedback: ${xhr.responseText}`);
      // Re-enable the button in case of an error
      $button.html("Request Feedback from AI");
      $button.prop('disabled', false);
    },
    complete: function () {
      // No action needed here since button is removed on success
    }
  });
});