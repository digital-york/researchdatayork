class RdMailer < ApplicationMailer
  # send an email to the people who requested the data for a particular dataset
  def notify_requester(dataset_id)
    # get the dataset
    @dataset = Dlibhydra::Dataset.find(dataset_id)
    # set up a recipient list
    to = []
    # for each DIP in the dataset
    @dataset.dips.each do |dip|
      # add the recipients for this dip to the recipient list
      to += dip.requestor_email
    end
    # remove any duplicates from the recipient list
    to.uniq!
    # send them an email telling them that the data is ready to download
    mail(to: to, subject: 'Data available for dataset "' + @dataset.preflabel + '"') unless to.empty?
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
    mail(to: to, subject: 'Data requested for dataset ' + @dataset.id) unless to.empty?
  end
end
