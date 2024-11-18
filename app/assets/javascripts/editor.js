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
  };

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
  
  $(document).ready(function() {
  // Retrieve the theme state from localStorage
  var savedTheme = localStorage.getItem('theme');
  var savedTooltipTheme = localStorage.getItem('tooltipTheme');
  const editors = CodeOceanEditor.editors;

  // Set the initial theme based on the stored state
  if (savedTheme === 'dark') {
    $('body').attr('data-bs-theme', 'dark');
    editors.forEach(editor => {
      editor.setTheme('ace/theme/tomorrow_night_eighties');
    });
    setTimeout(function() {
      setTooltipTheme('tomorrow_night_eighties');
    }, 500); // Delay the tooltip theme setting
    $('#theme-toggle i').removeClass('fa-moon').addClass('fa-sun');
  } else {
    $('body').attr('data-bs-theme', 'light');
    editors.forEach(editor => {
      editor.setTheme('ace/theme/textmate');
    });
    setTimeout(function() {
      setTooltipTheme('textmate');
    }, 500); // Delay the tooltip theme setting
    $('#theme-toggle i').removeClass('fa-sun').addClass('fa-moon');
  }

  if (savedTooltipTheme) {
    setTimeout(function() {
      setTooltipTheme(savedTooltipTheme);
    }, 500); // Delay the tooltip theme setting
  }

  function handleThemeChangeEvent(event) {
    if (CodeOceanEditor) {
      CodeOceanEditor.THEME = event.detail.currentTheme === 'dark' ? 'ace/theme/tomorrow_night' : 'ace/theme/tomorrow';
      document.dispatchEvent(new Event('theme:change:ace'));
    }
  }

  $(document).on('theme:change', handleThemeChangeEvent.bind(this));
});
  
  $('#theme-toggle').on('click', function() {
    var body = $('body');
    var icon = $(this).find('i');
    const editors = CodeOceanEditor.editors;
  
    if (body.attr('data-bs-theme') === 'dark') {
      body.attr('data-bs-theme', 'light');
      icon.removeClass('fa-sun').addClass('fa-moon');
      editors.forEach(editor => {
        editor.setTheme('ace/theme/textmate');
      });
      setTooltipTheme('textmate');
      localStorage.setItem('tooltipTheme', 'textmate');
      localStorage.setItem('theme', 'light'); // Store the theme state in localStorage
    } else {
      body.attr('data-bs-theme', 'dark');
      editors.forEach(editor => {
        editor.setTheme('ace/theme/tomorrow_night_eighties');
      });
      setTooltipTheme('tomorrow_night_eighties');
      localStorage.setItem('tooltipTheme', 'tomorrow_night_eighties');
      icon.removeClass('fa-moon').addClass('fa-sun');
      localStorage.setItem('theme', 'dark');
    }
  
    return false; // Prevent default link behavior
  });
  
  // Function to set the tooltip theme
  function setTooltipTheme(theme) {
    var tooltipElements = $('.editor.allow_ace_tooltip');
    tooltipElements.each(function(index, element) {
      var tooltipEditor = ace.edit(element);
      tooltipEditor.setTheme('ace/theme/' + theme);
    });
  
    // Store the theme in local storage
    localStorage.setItem('tooltipTheme', theme);
  }  
});
