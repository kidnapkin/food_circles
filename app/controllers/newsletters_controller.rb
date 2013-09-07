class NewslettersController < ApplicationController

  # TODO: display the errors and messages somewhere on the page
  def subscribe
    begin
      result = if current_user || params[:email].present?
        gb = Gibbon::API.new
        list_id = gb.lists.list(:filters => {:list_name => Rails.configuration.mailchimp_list_name})["data"][0]["id"]
        api_result = gb.lists.batch_subscribe(:id => list_id, :batch => [{:email => {:email => current_user ? current_user.email : params[:email]}}])
        if api_result["errors"].any?
          partial = current_user ? 'user_subscription_error' : 'subscription_error'
          Rails.logger.debug('Newsletter Controller :13' + api_result["errors"].map{|error| error["error"]}.to_sentence})
          {:error => true, :description => api_result["errors"].map{|error| error["error"]}.to_sentence}
        else
          partial = current_user ? 'user_subscription_success' : 'subscription_success'
          {:success => true, :description => "You've subscribed to our list. You'll soon receive an email to confirm your subscription."}
        end
      else
        Rails.logger.debug('Newsletter Controller :19 sign up')
        partial = 'subscription_error'
        {:error => true, :description => "You need to sign up"}
      end
      respond_to do |format|
        format.json { render :json => result }
        format.js   { render partial: partial }
      end
    rescue Timeout::Error => e
      render :json => {:error => true, :description => "Couldn't reach MailChimp in a timely fashion."}
    end
  end
end
