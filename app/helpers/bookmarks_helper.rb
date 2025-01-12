module BookmarksHelper
  def bookmarklet_javascript(username)
    js = <<~JS
      javascript:(function(){
        var w = 600;
        var h = 500;
        var left = (screen.width/2)-(w/2);
        var top = (screen.height/2)-(h/2);
        window.open('#{new_user_bookmark_url(username)}?url=' +
          encodeURIComponent(window.location.href) +
          '&title=' + encodeURIComponent(document.title) +
          '&popup=true',
          'Add Bookmark',
          'toolbar=no,location=no,directories=no,status=no,menubar=no,scrollbars=yes,resizable=yes,width='+w+',height='+h+',top='+top+',left='+left
        );
      })();
    JS

    "javascript:#{js.gsub("\n", ' ').strip}"
  end
end
