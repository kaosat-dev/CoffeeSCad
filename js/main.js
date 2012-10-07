$.extend({
  getUrlVars: function()
  {
    var vars = [], hash;
    var hashes = window.location.href.slice(window.location.href.indexOf('?') + 1).split('&');
    for(var i = 0; i < hashes.length; i++)
    {
      hash = hashes[i].split('=');
      vars.push(hash[0]);
      vars[hash[0]] = hash[1];
    }
    //console.log("Vars");
    //console.log(vars);
    return vars;
  },
  getUrlVar: function(name){
    return $.getUrlVars()[name];
  }
});


//experimentation with git api etc
 /*var code = $.getUrlVar('code');
    console.log("CODE retrieved: "+code);
    
   $('#gitHubLogin').click(function () {
    window.open('https://github.com' + 
        '/login/oauth/authorize' + 
        '?client_id=xx' +
        '&scope=gist');
    });
    
    $.ajax(
    {
        type:"POST",
        url: "https://github.com/login/oauth/access_token?"+
        "?client_id=xx"+
        '&scope=gist'+
        "&client_secret=xx",
        error: function(xhr, error)
        {
            console.log("ERROR:")
            console.log(xhr); console.log(error);
        },
         success: function(result)
         {
            console.log("QUery result:"+result)
         }
 
    });*/
    
    /*
        "https://github.com/login/oauth/access_token?"+
        "client_id=...&"+
        "redirect_uri=http://www.example.com/oauth_redirect&"+
        "client_secret=...&"+
        "code=..."
    */

