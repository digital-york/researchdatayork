@plural = (str, num) ->
  if (num > 1) 
    returnString = str + 's'
  else 
    returnString = str
  

$(document).ready ->
  $('#browse').browseEverything().done( 
    (data) -> 
      $('#browse_everything_status').html(data.length.toString() + " " + plural("file", data.length) + " selected")
  )
    
