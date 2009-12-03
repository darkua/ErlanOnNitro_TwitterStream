var heightWindow = null;
var widthWindow = null;

var cloudWidth = null;
var cloudHeight = null;


var cloud= null;

$(document).ready(function(){
    cloud = $('#cloud');
    heightWindow = $(window).height(); 
    widthWindow = $(window).width();
    cloudWidth = widthWindow = $(window).width();
    cloudHeight = heightWindow-$('#content').height();
    cloud.css({'height':cloudHeight,'width':cloudWidth});
});

$(window).resize(function(){
    heightWindow = $(window).height(); 
    cloudWidth = widthWindow = $(window).width();
    cloudHeight = heightWindow-$('#content').height();
    
    cloud.css({'height':cloudHeight,'width':cloudWidth});
    
});




buildTweet = function(tweet){
   var x = Math.floor(Math.random()*cloudWidth);
   var y = Math.floor(Math.random()*cloudHeight);

   cloud.append(
       $('<img/>').attr("src",tweet.picture).css({
           width:tweet.size+'px',
           height:tweet.size+'px',
           left:x+'px',
           top:y+'px'
       }).click(function(){
           $.growl(tweet.screen_name,tweet.text);
       })
   )
}