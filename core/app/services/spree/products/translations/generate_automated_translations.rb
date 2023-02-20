module Spree
  module Products
    module Translations
      class GenerateAutomatedTranslations
        prepend Spree::ServiceModule::Base

        def call(product:, source_locale:, target_locales:, automated_translations_provider: self.class.injected_automated_translations_provider, skip_existing: true)
          raise ArgumentError, 'Automated translations service not available' if automated_translations_provider.nil?
          raise ArgumentError, 'No locales available to translate to' if target_locales.empty?

          source_attributes = fetch_attributes_in_source_locale(product, source_locale)

          begin
            translations_to_generate(product, target_locales, skip_existing).each do |target_locale|
              translate_to_locale(automated_translations_provider, product, source_attributes, source_locale, target_locale)
            end

            success(product)
          rescue => e
            failure(e)
          end
        end

        private

        def fetch_attributes_in_source_locale(product, source_locale)
          product.translations.find_by!(locale: source_locale).attributes
        end

        def translate_to_locale(automated_translations_provider, product, source_attributes, source_locale, target_locale)
          translated_attributes_result = automated_translations_provider.call(product: product,
                                                                              source_attributes: source_attributes,
                                                                              source_locale: source_locale,
                                                                              target_locale: target_locale)

          if translated_attributes_result.success?
            translated_attributes = translated_attributes_result.value
            translation = product.translations.find_or_initialize_by(locale: target_locale)
            translation.update!(translated_attributes)
          else
            raise translated_attributes_result.value
          end
        end

        def translations_to_generate(product, target_locales, skip_existing)
          return target_locales unless skip_existing

          target_locales - product.translations.pluck(:locale).map(&:to_s)
        end

        class << self
          def enabled?
            injected_automated_translations_provider.present?
          end

          def injected_automated_translations_provider
            Spree::Dependencies.products_automated_translations_provider&.constantize
          end
        end
      end
    end
  end
end
