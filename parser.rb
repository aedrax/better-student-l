require 'gmail'

while true
    
    data = ""
    
    
    gmail = Gmail.connect("betterstudentl@gmail.com", "passwordgoeshere")
    puts "Checking at..." + Time.now.to_s
    if gmail.logged_in?
        puts "Logged in successfully!"
        
         #gmail.inbox.emails(:unread, :from => "p-sorensen@onu.edu").each { |email|
        gmail.inbox.emails(:unread, :from => "onu-student-ld-request@lists.onu.edu").each { |email|
            puts "Processing new message at " + Time.now.to_s
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
           subject = sections.join
           
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
            
            # replace links with buttons
            result_string.gsub!(/((http|ftp|https):\/\/([\w_-]+(?:(?:\.[\w_-]+)+))([\w.,@?^=%&:\/~+#-]*[\w@?^=%&\/~+#-])?)/, '<a href="\1" class="waves-effect orange waves-light btn black-text">This Link</a>')
            # ugly patches
            # replace this string with the single quote
            result_string.gsub!(/=E2=80=99/,"'")
            
            content = {:header => header, :message => result_string}
            
        }
        
        html_header = 
	'<!DOCTYPE html>
          <html>
            <head>
              <!--Import materialize.css-->
              <link type="text/css" rel="stylesheet" href="css/materialize.min.css"  media="screen,projection"/>
              <link type="text/css" rel="stylesheet" href="css/main.css"  media="screen,projection"/>
        
              <!--Let browser know website is optimized for mobile-->
              <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
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
	    <header>
              <nav class="top-nav orange flow-text">
                <div class="container">
                  <div class="nav-wrapper">
		    <a class="page-title black-text"><strong>A Better Student L Digest</strong></a>
		  </div>
                </div>
              </nav>
	    </header>
            <ul id="slide-out" class="side-nav fixed">'
              
        html_sidebar = ""
        
        table_of_contents.map{ |content|
            html_sidebar += '<li class="waves-effect waves-orange no-padding"><a class="truncate" href="#'+content[:number]+'">'+content[:subject]+'</a></li>'
        }
          
        html_middle_part = 
	   '</ul>
            <a href="#" data-activates="slide-out" class="button-collapse"><i class="medium material-icons"></i></a>
          
            <div class="container">
              <div class="row">
                <div class="col s0 l3">&nbsp</div>
                  <div class="col s12 l6">
                    <ul id="staggered-test">'
                    
                    
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
        
              <body>
                <!--Import jQuery before materialize.js-->
                <script type="text/javascript" src="https://code.jquery.com/jquery-2.1.1.min.js"></script>
                <script type="text/javascript" src="js/materialize.min.js"></script>
                <script type="text/javascript">
                  // Initialize collapse button
                  $(".button-collapse").sideNav();
                  $(document).ready(function(){
                    $("a").click(function(){
                      // Hide sideNav
                      $(".button-collapse").sideNav("hide");
                    });
                    Materialize.showStaggeredList("#staggered-test")
                  });
                </script>
              </body>
            </html>'
          
            html = html_header + html_sidebar + html_middle_part + html_content + html_footer
          
          File.open("/var/www/html/index.html", 'w') { |file| file.write(html) }
    end
    
    sleep(60)
end
