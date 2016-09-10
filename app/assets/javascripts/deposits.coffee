# function for pluralising a string if the given number is greater than 1
@plural = (num) ->
  if (num == 1) 
    str = "file"
  else 
    str = "files"
  returnStr = num + " " + str + " selected"
  

ready = ->
  # bind the "choose files" buttons to the actual file upload button elements (this is a workaround so that the file upload button can be styled)
  $('#file_upload_btn').click ->
    $('#real_file_btn').click()
  $('#dir_upload_btn').click ->
    $('#real_dir_btn').click()
  # update "choose files" status messages once files have been chosen
  $('#real_file_btn').change ->
    $('#file_upload_status').html(plural($(@)[0].files.length)) 
  $('#real_dir_btn').change ->
    $('#dir_upload_status').html(plural($(@)[0].files.length))

# call "ready" when document is loaded - includes workaround for turbolinks
# (http://stackoverflow.com/questions/20252530/coffeescript-jquery-on-click-only-working-when-page-is-refreshed)
$(document).ready(ready)
$(document).on('turbolinks:load', ready);     
