class BackfillUserNameCompanyFromAppConfig < ActiveRecord::Migration[7.1]
  def up
    say_with_time "Backfilling users.name and users.company from AppConfig" do
      User.find_each do |user|
        begin
          name = AppConfig.get(user, 'customer_name')
          company = AppConfig.get(user, 'company_name')
          updates = {}
          updates[:name] = name if user.respond_to?(:name) && user.name.blank? && name.present?
          updates[:company] = company if user.respond_to?(:company) && user.company.blank? && company.present?
          user.update_columns(updates) if updates.any?
        rescue => e
          Rails.logger.error "[BackfillUserNameCompany] user_id=#{user.id} error: #{e.class} #{e.message}"
        end
      end
    end
  end

  def down
    # no-op
  end
end


