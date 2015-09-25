require 'gmail'

password = ""
password = ARGV[0]

begin
while true
    
    data = ""  
    
    gmail = Gmail.connect("betterstudentl@gmail.com", password)
    puts "Checking at..." + Time.now.localtime.to_s
    if gmail.logged_in?
        puts "Logged in successfully!"
        
        #gmail.inbox.emails(:unread, :from => "p-sorensen@onu.edu").each { |email|
        gmail.inbox.emails(:unread, :from => "onu-student-ld-request@lists.onu.edu").each { |email|
            puts "Processing new message at " + Time.now.localtime.to_s
            data = email.body.to_s
            email.read!
        }
    else
        puts "Could not log in..."
    end
    
    gmail.logout
    
    if data.length > 0 
        message = data.split(/----------------------------------------------------------------------(<br>)?\s\sMessage-ID:/i)
        table_of_contents = message[0].split( /Table of contents:\s\s/i)[1].split("* ")
        # remove the first value which is blank
        table_of_contents.shift
        array_of_contents = message[1].split("End of onu-student-ld Digest")[0]
        array_of_contents = array_of_contents.split(/------------------------------(<br>)?\sMessage-ID:/i)
        
        
        table_of_contents.map!{ |content|
           # put each index on one line
           content.gsub!("\n  ","")
           
           # remove the number and the contact
           sections = content.split(" - ")
           
           number = sections.slice!(0)
           contact = sections.slice!(-1)
           # put the - back in the titles
           subject = sections.join(" - ")
           
           if subject == ""
              subject = "No Subject" 
           end
           
           content = {:number => number, :subject => subject, :contact => contact}
        }
        
        
        array_of_contents.map! { |content|
            sub_message = content.split(/(?<=\n\n)/)
            header = sub_message[0]
            sub_message.shift
            sub_message = sub_message.join
            sub_message.gsub!("------------------------------*********************************************","")
            
            split_message = sub_message.split(/\n/);
            
            index = 0
            result_string = ""
            
            while index < split_message.length
                current_line = split_message[index]
                result_string += current_line
                if index + 1 < split_message.length
                    next_line = split_message[index + 1]
                    next_line = next_line.split()
                    if current_line[-1, 1] == '='
                        current_line.slice!(-1)
                        result_string.slice!(-1)
                        if next_line.length == 1
                            current_line += next_line[0]
                            result_string += next_line[0] + " "
                            index += 1
                            if index < split_message.length
                                next_line = split_message[index]
                                next_line = next_line.split
                            else
                                next_line = [""]
                            end
                        end
                    end
                    if current_line.length + 1 + next_line[0].to_s.length < 76
                        result_string += "\n" 
                    else
                        result_string += " "
                    end
                end
                
                index += 1
                
            end
            
            
            ##### BANDAID SECTION #####
            # everyting here is just patching ascii errors where things just don't work
            
            # replace links with buttons
            result_string.gsub!(/((http|ftp|https):\/\/([\w_-]+(?:(?:\.[\w_-]+)+))([\w.,@?^=%&:\/~+#-]*[\w@?^=%&\/~+#-])?)/, '<a href="\1" class="waves-effect orange waves-light btn black-text">Link</a>')
            # ugly patches
            # replace this string with the single quote
            result_string.gsub!(/=E2=80=99/,"'")
            # replace this wtring with a -
            result_string.gsub!(/=E2=80=93/,"-")
            # remove extra <> around links
            result_string.gsub!(/<(\s+)?<a/,"<a")
            result_string.gsub!(/\/a>(\s+)?>/,"/a>")
            
            content = {:header => header, :message => result_string}
            
        }
        
        html_header = 
	'<!DOCTYPE html>
          <html>
            <head>
	      <meta charset="utf-8" /> 
              <!--Import materialize.css-->
              <link href="css/prism.css" rel="stylesheet">
              <link href="css/ghpages-materialize.css" type="text/css" rel="stylesheet" media="screen,projection">
              <link type="text/css" rel="stylesheet" href="css/main.css"  media="screen,projection"/>
        
              <!--Let browser know website is optimized for mobile-->
              <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
              <link href="http://fonts.googleapis.com/css?family=Inconsolata" rel="stylesheet" type="text/css">
              <link href="https://fonts.googleapis.com/icon?family=Material+Icons" rel="stylesheet">
              <title>A Better Student L Digest</title>
              <script>
		(function(i,s,o,g,r,a,m){i["GoogleAnalyticsObject"]=r;i[r]=i[r]||function(){
		(i[r].q=i[r].q||[]).push(arguments)},i[r].l=1*new Date();a=s.createElement(o),
		m=s.getElementsByTagName(o)[0];a.async=1;a.src=g;m.parentNode.insertBefore(a,m)
		})(window,document,"script","//www.google-analytics.com/analytics.js","ga");

		ga("create", "UA-67474823-1", "auto");
		ga("send", "pageview");
	      </script>
	    </head>
	    <body>
	    <header>
            <nav class="top-nav orange flow-text">
                <div class="container">
                  <div class="nav-wrapper">
		    <a class="page-title black-text"><strong>A Better Student L</strong></a>
		  </div>
                </div>
              </nav>
              <div class="container">
                <a href="#" id="menu-btn" data-activates="nav-mobile" class="button-collapse top-nav full hide-on-large-only"><i class="mdi-navigation-menu"></i></a>
              </div>
            <ul id="nav-mobile" class="side-nav fixed">'
              
        html_sidebar = ""
        
        table_of_contents.map{ |content|
            html_sidebar += '<li class="waves-effect waves-orange no-padding side-item"><a class="truncate" href="#'+content[:number]+'">'+content[:subject]+'</a></li>'
        }
          
        html_middle_part = 
	   '</ul>
            </header>
          <main>
            <div class="container">
              <div class="row">
                  <div class="col s12 offset-l2 l8">
                    <ul id="staggered-test">
                      <li>
		                <div class="card grey lighten-1 hoverable">
                          <div class="card-content">
                            <p>Last Updated at: '+Time.now.localtime.to_s+'</p>
                          </div>
                        </div>
		              </li>'
                    
                    
        html_content = ''            
        
        
        array_of_contents.map.with_index { |this_message, i|
            content = table_of_contents.at(i);
            html_content += 
	        '<li>
		   <div id="'+content[:number]+'" class="card hoverable">
            	     <div class="card-title black-text orange center-align">
	               <span>'+content[:subject]+'</span>
            	     </div>
                     <div class="card-content">
                       <p>'+this_message[:message]+'</p>
                     </div>
                   </div>
		 </li>'
        }
                    
                    
        
        html_footer = 
		   '</ul>
		  </div>
                </div>
              </div>
                </main>
                <!--Import jQuery before materialize.js-->
                <script type="text/javascript" src="https://code.jquery.com/jquery-2.1.1.min.js"></script>
                <script src="js/jquery.timeago.min.js"></script>
                <script src="js/prism.js"></script>
                <script src="js/materialize.js"></script>
                <script src="js/init.js"></script>
                <script type="text/javascript">
                  // Initialize collapse button
                  //$(".button-collapse").sideNav();
                  $(document).ready(function(){
                    $(".side-item").click(function(){
                      // Hide sideNav
                      $(".button-collapse").sideNav("hide");
                    });
                    Materialize.showStaggeredList("#staggered-test")
                  });
                </script>
              </body>
            </html>'
          
            html = html_header + html_sidebar + html_middle_part + html_content + html_footer
          
          #File.open("index.html", 'w') { |file| file.write(html) }
          File.open("/var/www/html/index.html", 'w') { |file| file.write(html) }
    end
    
    sleep(60)
end
rescue Errno::ENETUNREACH
    puts "NETWORK IS UNREACHABLE"
    retry
rescue Net::IMAP::ByeResponseError
    puts "ByeResponseError"
    retry
rescue => e
    puts e
end
