//This is to be able to use offsetX in firefox
var normalizeEvent = function(event) 
{
  if(!event.offsetX) {
    event.offsetX = (event.pageX - $(event.target).offset().left);
    event.offsetY = (event.pageY - $(event.target).offset().top);
  }
  return event;
};