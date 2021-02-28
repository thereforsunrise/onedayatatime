class Feature < ActiveRecord::Base
  def self.is_feature_enabled?(feature)
    Feature.find_by(feature: feature).enabled
  end
end
