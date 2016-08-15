# app/controllers/concerns/show_dip.rb
module ShowDip
  extend ActiveSupport::Concern

  require 'nokogiri'

  included do
    attr_reader :dip
  end

  # given a dataset, find its METS.xml file, parse it and return an array containing the file names and paths of all files in the DIP 
  def dip_directory_structure(dataset)
    # set up the return variable
    dip_structure = Hash.new
    # if the dataset has a dip with downloadable files
    if dataset.dips and dataset.dips.first and dataset.dips.first.members
      # get the dip from the dataset
      dip = dataset.dips.first
      # loop through the DIP files until we find the METS.xml one
      dip.members.each do |f|
        if f.preflabel =~ /^METS\.[-a-z0-9]{36}\.xml$/
          mets_url = f.files.first.uri.to_s  
          # get Nokogiri to parse it
          mets_doc = Nokogiri::XML(open(mets_url)) 
          # get the file ID of every file in the DIP package
          dip_file_ids = mets_doc.xpath("//mets:fileSec/mets:fileGrp[@USE='original']/mets:file/@ID")
          # get the file path of every file in the DIP package
          dip_file_paths = mets_doc.xpath("//mets:fileSec/mets:fileGrp[@USE='original']/mets:file/mets:FLocat/@xlink:href")   
          # for each file
          filecounter = 0
          dip_file_ids.each do |f|
            # get the file id as a string (need to parse out the "file-" prefix)
            file_id = f.to_s[/^file-(.*)$/, 1]
            # get the file path/name (parse out everything in the path before the DIP package id)
            file_path = dip_file_paths[filecounter].to_s[/#{dip.id}\/(.*)$/, 1]
            # add these to the return array
            dip_structure[file_id] = {:file_path => file_path}
            filecounter = filecounter + 1
          end
        end
        # no need to continue looping now that we've dealt with METS.xml
        break
      end
      # now loop over the DIP files again using the file id to find the uri of the stored file and add that to the return structure
      dip.members.each do |f|
        # get the file id of this stored file
        file_id = f.preflabel[/^([-a-z0-9]{36})/, 1]
        if dip_structure.has_key?(file_id)
          dip_structure[file_id][:file_uri] = f.files.first.uri.to_s
        end
      end
    end
    dip_structure
  end

end
