module MoneyConvertible
  extend ActiveSupport::Concern

  class_methods do
    def money_field(*fields)
      fields.each do |field|
        define_method(field) do
          cents = send(:"#{field}_cents")
          return nil if cents.nil?
          cents / 100.0
        end
      end
    end
  end
end
