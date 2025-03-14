// This code handles suricata-y stuff
$(document).ready(() => {
  // Note: can't use the level variable yet, since it's not populated
  let rule = localStorage.getItem(`rule-${ $("#id").val() }`);
  if(rule) {
    console.log('Loaded rule from localStorage!');
    $('#rule').val(rule);
  }

  $('#reset').on('click', () => {
    if (confirm("Are you sure you want to reset?")) {
      $('#rule').val(level['base_rule']);
      localStorage.removeItem(`rule-${ level['id'] }`);
    }
  });

  $('#send').on('click', () => {
    $.ajax({
      type: 'POST',
      url: `/api/suricata/${ level['id'] }`,
      data: JSON.stringify({
        'rule': $('#rule').val(),
      }),
      contentType: 'application/json; charset=utf-8',
      dataType: 'json',
      success: function(data) {
        //$('#response').html(hljs.highlight(atob(data['response']), { language: 'html' }).value);
        //
        //if(data['completed'] == true) {
        //  complete_level(level['id'], level['name']);
        //}
        console.log('Response received:', data);
      },
      error: function(xhr, status, error) {
        toastr.error(`Error: ${ error }`);
        console.error(`Error: ${ error }`);
      }
    });
  });

  // Save the rule to localStorage every keypress
  $('#rule').on('keyup', () => {
    localStorage.setItem(`rule-${ level['id'] }`, $('#rule').val());
  });
});
