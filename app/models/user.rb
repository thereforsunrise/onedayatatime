class User < ActiveRecord::Base
  has_secure_password
  has_secure_password :recovery_password, validations: false

  has_many :entries

  validates :username, presence: true, uniqueness: true, length: { minimun: 3, maximum: 10 }

  def self.login(username, password)
    return nil if username.empty? || password.empty?

    User.find_by(username: username).try(:authenticate, password)
  end
end
