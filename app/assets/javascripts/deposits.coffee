# function for pluralising a string if the given number is greater than 1
@plural = (num) ->
  if (num == 1) 
    str = "file"
  else 
    str = "files"
  returnStr = num + " " + str + " selected"
  

$(document).ready ->
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
  # update the "browse_everything_status" element after browse_everything has finished
  $('#google_drive_btn').browseEverything().done( 
    (data) -> 
      $('#google_drive_status').html(plural(data.length))
  )
    
