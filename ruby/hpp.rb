load 'classes.rb'
require 'fileutils.rb'
require 'yaml'

$hSettings = YAML.load_file 'hpp.yml'
$hScaffolding = getScaffoldingFiles($hSettings["tracked_scaffolding_files"])

#check the language and filespec keys in the ini file.
#if everything's OK the array will contain all the languages we're processing.
aLangs = checkLanguage()

ga = GAProcessor.new
ff = FeedbackFormProcessor.new
sm = ShowmeProcessor.new
ab = AboutboxProcessor.new
ti = TableIconProcessor.new

aLangs.each do |lang|

  #get the WebHelp path/file and the contents folder if specified.
  webhelp = String.new($hSettings["webhelp"])

  #extract all the various bits we need from the WebHelp path/file.
  webhelp_path, webhelp_file, webhelp_content_folder = parseWebHelpFile(webhelp, lang)

  hScaffolding = getScaffoldingFiles($hSettings["tracked_scaffolding_files"] + "," + webhelp_file + "=Root")
  
  #update the About box.
  ab.UpdateAboutBox(webhelp_path, lang) if $hSettings["do_aboutbox"]

  #copy the table icons to the WebHelp system.
  ti.copyIcons(webhelp_path) if $hSettings["do_tableicons"]
  
  #tell the feedback form processor to build the text of the form.
  ff.setFeedbackForm(lang) if $hSettings["do_feedbackforms"]
  
  #load the files for the showme links.
  sm.loadFiles(lang) if $hSettings["do_showmes"]
  
  #copy the icon for the contextual links.
  sm.copyContextualIcon(webhelp_path) if $hSettings["do_showmes"]
  
  #find all the HTML files in all the folders and subfolders. 
  aFiles = Dir[webhelp_path + "/**/*.htm"]
  puts "File: " + webhelp if $hSettings["show_onscreen_progress"]
  print "Working" if $hSettings["show_onscreen_progress"]
  
  #loop around them.
  aFiles.each do |file_in_webhelp|

    #are we in the contents directory tree? if so:
    # - tag everything with the GA code,
    # - add the help feedback form, 
    # - add the showme links,
    # - add the icons to the Note, Warning and Tip tables,
    # - write the modified file to disk.
    if file_in_webhelp.include? webhelp_content_folder
    
      its_html = openFile(file_in_webhelp)
      next if its_html.nil?
    
      its_original_html = String.new(its_html)
  
      print "."  if $hSettings["show_onscreen_progress"]
      ga.addTrackingCode(file_in_webhelp, its_html, "Content") if $hSettings["do_analytics"]
      ff.addFeedbackForm(file_in_webhelp, its_html) if $hSettings["do_feedbackforms"]
      sm.addShowmeLinks(getFile(file_in_webhelp), its_html, lang) if $hSettings["do_showmes"]
      ti.addIcons(its_html) if $hSettings["do_tableicons"]
      writeFile(file_in_webhelp, its_html) if its_html != its_original_html

    else  

      #we're not in the contents folder, so tag the scaffolding files with GA code.
      its_html = openFile(file_in_webhelp)

      #loop through the scaffolding files
      hScaffolding.each do |sf, sf_type|
      
        #is the current file a scaffolding file?
        if file_in_webhelp.include? sf
        
          #yes, so tag it with the GA code.
          its_html = openFile(file_in_webhelp) 
      
          begin
        
            print "."  if $hSettings["show_onscreen_progress"]
            ga.addTrackingCode(file_in_webhelp, its_html, sf_type) if $hSettings["do_analytics"]
            writeFile(file_in_webhelp, its_html)
        
          rescue
  
          end 
	 
        end #is the current file a scaffolding file?
    
      end #scaffolding files do loop
 
    end  #contents folder/scaffolding files folder if check
	
  end #loop around WebHelp files
  
  print "Done!\r\n" if $hSettings["show_onscreen_progress"]

end #language loop
