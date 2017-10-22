# app/controllers/concerns/show_dip.rb
module ShowDip
  extend ActiveSupport::Concern

  require 'nokogiri'
  require 'zip'
  require 'open-uri'

  included do
    attr_reader :dip
  end

  def dip_directory_structure (dataset)
    # set up the return variable
    dip_structure = {}
    # if the dataset has a dip with downloadable files
    if dataset.dips && !dataset.dips.empty?
      # get the dip from the dataset
      dip = dataset.aips[0]
      dip_folder = File.join(ENV['DIP_LOCATION'], dip.dip_current_path)
      # look for the METS file in the dip folder
      mets_files = Dir[File.join(dip_folder, "METS*.xml")]
      if !mets_files.empty?
        # get Nokogiri to parse it
        mets_doc = Nokogiri::XML(open(mets_files[0]))
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
          file_path = dip_file_paths[filecounter].to_s.sub(/^.*?objects\/([a-z0-9]{9}\/)?/, "")
          # look for this file in the dip location
          dip_files = Dir[File.join(dip_folder, "objects", file_id + "*")]
          if !dip_files.empty?
            # replace the file name in the file path with the file name from the real dip file
            # - the file name from METS might be .wav whereas dip might be .mp3 for example
            file_path = file_path.sub(File.basename(file_path), File.basename(dip_files[0]).sub(file_id + "-", "")) 
            # add these to the return array
            dip_structure[file_id] = { file_path: file_path, file_path_abs: dip_files[0] }
          end
          filecounter += 1
        end
        # sort the resulting dip structure by file path
        dip_structure = dip_structure.sort_by { |file_id, file_details| file_details[:file_path].downcase }.to_h
      end
    end  
    dip_structure
  rescue => e
    handle_exception(e, "Unable to present DIP files for download, failed to parse METS.xml",
                     "Given dataset: " + dataset.id, true)
    return {}
  end

  # given a dataset, generate an in-memory zip file of the dataset's dip files (with the correct directory structure)
  # and return the zip filestream (so that it can be written to user's browser as a zip file in the controller)
  def dip_as_zip_filestream(dataset)
    # first of all, get the structure of the dip files
    dip_structure = dip_directory_structure(dataset)
    # set up a new zip file in-memory with files sorted alphabetically
    ::Zip.sort_entries = true
    file_stream = Zip::OutputStream.write_buffer do |zip|
      # for each file in the dip
      dip_structure.each do |_file_id, file_details|
        # get the contents of the file
        file = open(file_details[:file_uri], &:read)
        # create this file in the zip
        zip.put_next_entry(file_details[:file_path])
        zip.write(file)
      end
    end
    file_stream.rewind
    file_stream
  end

  # LEGACY IMPLEMENTATION
  # given a dataset, find its METS.xml file, parse it and return an array containing the file names
  #   and paths of all files in the DIP
  def dip_directory_structure_using_fedora(dataset)
    # set up the return variable
    dip_structure = {}
    # if the dataset has a dip with downloadable files
    if dataset.dips && !dataset.dips.empty?
      # get the dip from the dataset
      dip = dataset.aips[0]
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
            file_path = dip_file_paths[filecounter].to_s.sub(/^.*?objects\/([a-z0-9]{9}\/)?/, "")
            # add these to the return array
            dip_structure[file_id] = { file_path: file_path }
            filecounter += 1
          end
          # no need to continue looping now that we've dealt with METS.xml
          break
        end
      end
      # now loop over the Dataset files using the file id to find the uri of the stored file and add that
      #   to the return structure
      dataset.members.each do |f|
        if f.respond_to?(:preflabel)
          # get the file id of this stored file
          file_id = f.preflabel[/^([-a-z0-9]{36})/, 1]
          if dip_structure.key?(file_id)
            # the original file is in f.original_file - if it has a thumbnail, that's in f.thumbnail
            dip_structure[file_id][:file_uri] = f.original_file.uri.to_s
            dip_structure[file_id][:thumbnail_uri] = f.thumbnail.uri.to_s
            dip_structure[file_id][:file_path_abs] = File.join(ENV['DIP_LOCATION'], dip.dip_current_path, "objects", f.preflabel)
          end
        end
      end
      # sort the resulting dip structure by file path
      dip_structure.sort_by { |file_id, file_details| file_details[:file_path].downcase }.to_h
    end
    dip_structure
  rescue => e
    handle_exception(e, "Unable to present DIP files for download, failed to parse METS.xml",
                     "Given dataset: " + dataset.id, true)
    return {}
  end

end

