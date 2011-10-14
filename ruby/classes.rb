class GAProcessor

  def initialize
  
    @TRACKING_SCRIPT = File.read("files/ga/ga_tracking_script.txt")
    rescue
      puts "Couldn't open  GA tracking file."
      abort
    end
  
  def addTrackingCode (file_in_webhelp, its_html, webhelp_file_type)
  
    begin
    
      tracking_script = String.new(@TRACKING_SCRIPT)
     
      tracking_script.sub!("HELP_SYSTEM_NAME", $hSettings["product"])
      tracking_script.sub!("WEB_PROPERTY_ID", $hSettings["web_property_id"])
      tracking_script.sub!("HELP_SYSTEM_PAGE_TYPE", webhelp_file_type) 
      
      its_html.gsub!(/<\/head>/i, tracking_script) 

    rescue Exception => e

      puts "Couldn't add GA script. File: " + file_in_webhelp
      puts "Exception: " + e.to_s
 
    end  

  end #addTrackingCode

end  #GAProcessor

class FeedbackFormProcessor

  def setFeedbackForm (lang)
  
    @FEEDBACK_FORM = File.read("files/ff/" + lang.downcase + "_help_feedback_form.htm")
    #update the product name.
    @FEEDBACK_FORM["<medidata-product-name>"] = $hSettings["product"]
  
  end
  
  
  def addFeedbackForm (file_in_webhelp, its_html)
    
    begin

      its_html.gsub!(/<\/body>/i, @FEEDBACK_FORM)  

    rescue Exception=> e

      puts "Couldn't add feedback form. File: " + file_in_webhelp
      puts "Exception: " + e.to_s

    end  


  end

end

class ShowmeProcessor

  
  def loadFiles (lang, settings_file_root)
  
    @LIST_TEMPLATE = File.read("files/sm/list_link_template_" + lang + ".txt")
    @CONTEXT_TEMPLATE = File.read("files/sm/context_link_template_" + lang + ".txt")
    @SHOWMES = IO.readlines("files/sm/" + settings_file_root + "_showmes_" + lang + ".txt")
    
  
  end
  
  def copyContextualIcon(webhelp_path)
  
    begin
    
    FileUtils.cp "files/sm/i_help_video.png", webhelp_path + "/i_help_video.png"
  
    rescue Exception => e

      #puts e.to_s

    end
  
  end

  
  def addShowmeLinks (webhelp_file_in_contents_folder, html_of_webhelp_file_in_contents_folder, lang)
  
    s3_bucket = String.new($hSettings["s3_bucket"])
    s3_bucket.gsub!("<LANG>", lang)

    @SHOWMES.each do |row_in_showmes_file|
 
      #get rid of the newline character that IO.readlines adds to the end of every line.	 
      row_in_showmes_file.chomp!
       
      #skip to the next line if the current line is a comment.
      next if row_in_showmes_file[0,1] == "#"
  
      #get all the bits from the current line.
      #there can be an abitrary number of tabs between the bits.
      text_where_link_goes, wrapper_file_for_showme, page_where_link_goes, showme_width, showme_height = row_in_showmes_file.split(/\t+/)
      
      #skip to the next line in the list of showmes if the current line doesn't match the webhelp file we're looking at.
      next if !(webhelp_file_in_contents_folder == page_where_link_goes)

      #use the default height and width if there are no height and width specified in the showme list.
      showme_width = showme_width.nil? ? $hSettings["default_showme_width"] : showme_width
      showme_height = showme_height.nil? ? $hSettings["default_showme_height"] : showme_height
      
      #build the URL to put into the link text.
      url_in_link = s3_bucket + wrapper_file_for_showme
  
      #check whether the file we're looking at is the file that contains the list of showmes, or a file
      #that contains contextual links from within its text.
      #the text we use to build the link is different in these cases.
      if webhelp_file_in_contents_folder == $hSettings["showme_list_" + lang]
    
        #it's the file that contains the list of showmes;
        #we wrap the link around the text_where_link_goes
        link_text_to_add = String.new(@LIST_TEMPLATE)
        link_text_to_add["<LINK_TEXT>"] = text_where_link_goes
             
      else

        #it's a file that contains contextual links;
        #the link comes immediately after the text_where_link_goes
        link_text_to_add = String.new(@CONTEXT_TEMPLATE)
        link_text_to_add = text_where_link_goes + link_text_to_add
	  
      end  # is it the showme list or a contextual file?
     
      #set the height and width of the showme popup.
	  
      link_text_to_add["<WIDTH>"] = showme_width.to_s
      link_text_to_add["<HEIGHT>"] = showme_height.to_s
	 
      #finish building the link text by adding the URL of the wrapper file.
      link_text_to_add["<URL>"] = url_in_link
	  
      #update the HTML of the webhelp file with the link.
      begin
        html_of_webhelp_file_in_contents_folder[text_where_link_goes] = link_text_to_add
      rescue Exception => e
        #puts e.message
      end

    end  #@SHOWMES.each
    
  end  #addShowmeLinks

end #ShowmeProcessor


class AboutboxProcessor


  def UpdateAboutBox (webhelp_path, lang, settings_file_root)

    files_root = "files/ab/"
    source_banner = settings_file_root + "_whskin_banner_" + lang + ".htm"
    target_banner = "whskin_banner.htm"
    source_javascript = settings_file_root + "_whtbar_" + lang + ".js"
    target_javascript = "whtbar.js"
    image = $hSettings["link_image"]
    
    begin

      #copy 'whskin_banner_<LANG>.htm' to the WebHelp system as 'whskin_banner.htm'.
      FileUtils.cp files_root + source_banner, webhelp_path + "/" + target_banner 
      #copy the JavaScript file.
      FileUtils.cp files_root + source_javascript, webhelp_path + "/" + target_javascript 
      #copy the image.
      FileUtils.cp files_root + image, webhelp_path + "/" + image

    rescue Exception => e

      puts e.message

    end

  end #updateAboutBox

end #Aboutbox processor


class TableIconProcessor

  def copyIcons(webhelp_path)
    
    begin

      FileUtils.cp "files/ti/lightbulb_d.png", webhelp_path + "/lightbulb_d.png" 
      FileUtils.cp "files/ti/pushpin_d.png", webhelp_path + "/pushpin_d.png"
      FileUtils.cp "files/ti/triangle_d.png", webhelp_path + "/triangle_d.png"
    
    rescue Exception => e

      puts e.to_s 

    end  

  end #copyIcons


  def addIcons(html_of_webhelp_page)

    note_icon_text = '<p class="IconNote">'
    note_icon_image = "<img src='../../pushpin_d.png'/>" 
    
    important_icon_text = '<p class="IconImportant">'
    important_icon_image = "<img src='../../triangle_d.png'/>"
 
    tip_icon_text = '<p class="IconTip">' 
    tip_icon_image = "<img src='../../lightbulb_d.png'/>"

    html_of_webhelp_page.gsub!(note_icon_text, note_icon_text + note_icon_image)
    html_of_webhelp_page.gsub!(important_icon_text, important_icon_text + important_icon_image)
    html_of_webhelp_page.gsub!(tip_icon_text, tip_icon_text + tip_icon_image)

  end  #add Icons



end # TableIconProcessor


def writeFile(file_in_webhelp, its_html)

  begin
    f = File.open(file_in_webhelp, 'w')
    f.write(its_html)
    f.close
  rescue Exception
    puts ("Problem reading/writing " + file_in_webhelp) if $hSettings["show_onscreen_progress"]
  end

end


def openFile(fileInWebHelp)

  begin
    return File.read(fileInWebHelp)
  rescue
    puts "Couldn't open " + fileInWebHelp if $hSettings["show_onscreen_progress"]
  end

end


def parseWebHelpFile (webhelp_path_and_file, lang)

  webhelp_path_and_file.gsub!("<LANG>", lang)
  webhelp_path, webhelp_file_only = splitPathAndFile(webhelp_path_and_file)
  
  
  if $hSettings["webhelp_content_folder"] == "default"
    
    webhelp_content_folder = webhelp_path + "/" + File.basename(webhelp_file_only, '.htm') + "/"
  
  else

    webhelp_content_folder = String.new($hSettings["webhelp_content_folder"])
    webhelp_content_folder.gsub!("<LANG>", lang) 
  
  end  

  return webhelp_path, webhelp_file_only, webhelp_content_folder

end  

def splitPathAndFile (strWebHelp)

    #split a dir + file string into dir and file and return them

    #get the file name from the end of the string, by:
    #putting the string into an array,
    aWebHelp = strWebHelp.split("/")
  
    #then getting the last element (i.e. the file name).
    strFile = aWebHelp[aWebHelp.length-1]
  
    #now get rid of the last element (the file name) from the array,
    aWebHelp.delete_at(aWebHelp.length-1)
  
    #then build a string from what's left (to give the path)
    strPath = aWebHelp.join("/")
  
    return strPath, strFile
  
end

def getFile (strWebHelp)

    #get the file name from the end of the string, by:
    #putting the string into an array,
    aWebHelp = strWebHelp.split("/")
  
    #then getting the last element (i.e. the file name).
    strFile = aWebHelp[aWebHelp.length-1]
  
    return strFile
  
end

def removeFileExtension (strFile)

    return File.basename(strFile)

end

def checkLanguage()

  if $hSettings["language"].nil?
    puts "No language specified."
    abort
  end
  
  aLangs = $hSettings["language"].split(",")

  if aLangs.length > 1 and !($hSettings["webhelp"].include? "<LANG>")
    puts "No <LANG> in WebHelp path but multiple languages specified."
    abort
  end
  
  return aLangs
  
end

def getScaffoldingFiles (tracked_scaffolding_files)

    s = Array.new() 
    tracked_scaffolding_files.split(",").each {|kv| s << kv.split("=")}
    
    return Hash[*s.flatten]


end

def showVersionInformation (stop_after_this)

  puts " "
  puts "**********************"
  puts "Help processing script"
  puts "Version: 1.0"
  puts "Date:    <date>"
  puts "**********************"
  puts " "

  abort if stop_after_this

end

###########################################################################
  #I could never get this working so abandoned it to start again.
  #At some point I need to understand why: 
  
  def OldaddShowmeLinks(webhelp_file_in_contents_folder, its_html, lang)
    
    bucket=String.new($hSettings["s3_bucket"])
	bucket["<LANG>"] = lang
	
	
	puts webhelp_file_in_contents_folder
	
 	@SHOWMES.each do |this_showme|
 
     
      	
	  #get rid of the newline character that IO.readlines adds to each line.
	  this_showme.chomp!
	   
	  #jump to the next line in the showmes file if the current line is a comment.
	  #next if this_showme[0]=="#" 
	  
	  link_text, wrapper_file, webhelp_file_that_needs_showmes = this_showme.split("\t")
	  
	  puts webhelp_file_that_needs_showmes, webhelp_file_in_contents_folder
	  puts "MATCH " if webhelp_file_in_contents_folder == webhelp_file_that_needs_showmes
	  #jump to the next line if the file doesn't need to have links added.
	  next if !webhelp_file_in_contents_folder == webhelp_file_that_needs_showmes   
	  
	  #if we're here, the file needs to have showme links added,
	  #so find out whether it's the file containing the list of showmes (and set up the link text accordingly),
	  if webhelp_file_in_contents_folder == $hSettings["showme_list"]
		puts "SHOWME_LIST!"
		link_to_add = String.new(@LIST_TEMPLATE)
		link_to_add["<LINK_TEXT>"] = link_text
		
	  #or a file that needs contextual links in the flow of its text.
	  else
		
		link_to_add = String.new(@CONTEXT_TEMPLATE)
 		link_to_add = (link_text + link_template + " ") 
		
      end #list v contextual
	
      #finish preparing the link text,	
	  url = bucket + wrapper_file
	  link_to_add["<URL>"] = url
	  
	  #then add it to the html of the webhelp file.
	  its_html[link_text] = link_to_add
	 
	end #@SHOWMES.each
	
  end #addShowmeLinks
