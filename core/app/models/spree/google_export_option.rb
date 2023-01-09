module Spree
  class GoogleExportOption < Base
    belongs_to :store, class_name: "Spree::Store", foreign_key: "spree_store_id"

    validates :store, presence: true

    def enabled_keys
      keys = []

      attributes.each do |key, value|
        if value.instance_of?(TrueClass)
          keys.append(key.to_sym)
        end
      end

      keys
    end
  end
end