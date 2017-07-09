module Exceptions
  extend ActiveSupport::Concern

  # handle errors/exceptions/non-happy-path-events in a systematic way
  def handle_exception (e, msg_to_user="", msg_to_log="", send_email=false)
    # create pretty error message
    error_msg = "=====\n"
    error_msg += "Error\n"
    error_msg += "=====\n\n"
    error_msg += "Script(s)\n"
    error_msg += "---------\n"
    error_msg += e.backtrace.select{ |i| i.include?(Rails.root.to_s) }.join("\n") + "\n\n"
    error_msg += "Message\n"
    error_msg += "-------\n"
    error_msg += e.message + "\n\n"
    error_msg += "Additional info\n---------------\n" + msg_to_log + "\n\n" unless msg_to_log.empty?
    if current_user and current_user.email
      error_msg += "User\n----\n" + current_user.email + "\n\n" 
    end
    # log the error
    Rails.logger.error error_msg
    # present the user with an error message
    flash[:error] = msg_to_user
    # send an error email if appropriate
    if send_email
      begin
        RdMailer.notify_admin_about_error(error_msg).deliver_later
      rescue => e2
        # if there's an error in the mail routine, just log that there was an error
        Rails.logger.error "Also an error sending the error email: " + e2.message
      end
    end
  end

end
