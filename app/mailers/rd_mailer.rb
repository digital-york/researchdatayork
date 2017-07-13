class RdMailer < ApplicationMailer
  # send an email to the people who requested the data for a particular dataset
  def notify_requester(dip_id)
    # get the DIP
    @dip = Dlibhydra::Package.find(dip_id)
    # and get the dataset that contains this DIP
    @dataset = Dlibhydra::Dataset.find(@dip.package_ids[0])
    # add the recipients for this dip to the recipient list
    to = @dip.requestor_email.to_a
    # remove any duplicates from the recipient list
    to.uniq!
    # send them an email telling them that the data is ready to download
    mail(bcc: to, subject: 'Data available for dataset "' + @dataset.title[0].to_s + '"') unless to.empty?
  end

  # send an email to the RDM team to tell them that someone has requested data
  def notify_rdm_team_about_request(dataset_id, requester_email)
    # get the dataset
    @dataset = Dlibhydra::Dataset.find(dataset_id)
    # get the email address(es)
    @requester_email = requester_email
    # get the RDM team email address
    to = ENV['RDM_EMAIL']
    # send email
    mail(to: to, subject: "Data requested for dataset " + @dataset.id) unless to.nil? or to.empty?
  end

  # send an email about an error/exception that occurred
  def notify_admin_about_error(error_message)
    @error_message = error_message
    # get the admin email address
    to = ENV["ERROR_EMAIL_TO"]
    # send email
    mail(to: to, subject: "Error in RDM application") unless to.nil? or to.empty?
  end
end
