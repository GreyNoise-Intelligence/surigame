const highlight_completed_levels = () => {
  let progress = JSON.parse(localStorage.getItem('progress') || '{}');

  for (let key in progress) {
    if (progress.hasOwnProperty(key) && progress[key] == true) {
      $(`#completed-${ key }`).css('display', 'inline-flex');
    }
  }
};

const complete_level = (id, name) => {
  let progress = JSON.parse(localStorage.getItem('progress') || '{}');
  progress[id] = true;
  localStorage.setItem('progress', JSON.stringify(progress));

  if(name) {
    toastr.success(`Completed level: ${ name }`);
  }
  highlight_completed_levels();
};

const add_result = (text, cls, icon, scroll_target) => {
  const new_div = $('<div class="status">')
  new_div.text(text);
  new_div.addClass(cls);
  new_div.append(`<i class="fa ${ icon } status-icon"></i>`);

  if(scroll_target) {
    new_div.mouseover(function() {
      scroll_target.addClass("highlight");
    });

    new_div.mouseout(function() {
      scroll_target.removeClass("highlight");
    });

    new_div.click(function() {
      scroll_target[0].scrollIntoView({
        behavior: 'smooth',
        block: 'center'
      });

      let count = 0;
      function blink() {
        if (count < 4) { // Double the times for fadeOut and fadeIn
          scroll_target.fadeOut(200, function() {
            scroll_target.fadeIn(200, blink);
          });
          count++;
        }
      }
      blink();
    });
  }

  $('#results-list').append(new_div);
};


let level;
$(document).ready(() => {
  if ($("#id").length) {
    // Load the level object
    $.getJSON(`/api/levels/${ $("#id").val() }`)
      .done((data) => {
        level = data;
      })
      .fail((xhr, status, error) => {
        console.error(`Error: ${ error }`);
        toastr.error(`Error: ${ error }`);
      });

    // Highlight completed levels
    highlight_completed_levels();

    // Highlight the current level
    $(`#${ $("#id").val() }`).addClass('current-level');

    // Make the clear button work
    $('#clear').on('click', () => {
      if(confirm("Are you sure you want to clear your progress?")) {
        localStorage.removeItem(`progress`);
        location.reload();
      }
    });
  }
});
