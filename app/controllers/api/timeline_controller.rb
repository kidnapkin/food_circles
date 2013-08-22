class Api::TimelineController < ApplicationController
  include PaymentCommons

  before_filter :authenticate_user!
  def show
    begin
      load_payments
      load_weekly_total
      load_reservations

      current_vouchers = Voucher.where("start_date <= ? and end_date >= ?", Time.now, Time.now)
      @total_vouchers = current_vouchers.collect{ |v| v.total }.sum
      @available_vouchers = current_vouchers.collect{ |v| v.available }.sum

      hash = {
        :weekly_total => @weekly_total,
        :total_vouchers => @total_vouchers,
        :available_vouchers => @available_vouchers,
        :payments => @payments.map { |p| 
          {
            :id => p.id,
            :state => p.state,
            :user_id => p.user_id,
            :amount => p.amount,
            :offer => [Offer.find(p.offer_id)].map { |o|
              {
                :id => o.id,
                :name => o.name,
                :details => o.details,
                :available => o.available,
                :total => o.total,
                :price => o.price,
                :venue => [Venue.find(o.venue_id)].map { |v|
                  {
                    :id => v.id,
                    :name => v.name,
                    :description => v.description                  
                  }
                }
              }
            }
          }
        },
        :reservations => @reservations.map{ |r|
          {
            :id => r.id,
            :state => r.state,
            :user => r.user.name,
            :venue => r.venue.as_json.slice(:id, :name, :city, :state, :zip, :lat, :lon, :description, :phone, :web, :tags).merge({
              :offers => r.venue.offers.map(&:name),
              :open_times => r.venue.open_times.map{|ot| "#{ot.start} - #{ot.end}"},
              :image => r.venue.timeline_image.present? ? r.venue.timeline_image.url : ''
            }),
            :offer => r.offer.as_json.slice(:id, :title, :details, :minimum_diners).merge({
              :discount_price => r.offer.price,
              :full_price => r.offer.original_price,
              :image_url => r.offer.image.present? ? r.offer.image.url : ''
            }),
            :charity => r.charity.as_json.slice(:id, :name, :description),
            :date_purchased => r.created_at
          }
        }
      }

      render :json => {:error => false, :content => hash}
    rescue Exception => e
      render :json => {:error => true, :description => "Internal Server Error."}, status: 503 and return
    end
  end

  def use_voucher
    render :json => {:error => true, :description => "There's currently no way to use this, so please tell me how should I implement it."}, status: 503 and return
  end

  def verify_payment_and_show_voucher
    # TO BE IMPLEMENTED BY THE MOBILE APP DEVELOPER
    render :json => {:error => true, :description => "To be implemented by the mobile app developer."}, status: 503 and return
  end
end
