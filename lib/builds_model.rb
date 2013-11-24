class BuildsDatabase

  private

  class Job < Sequel::Model
    one_to_many :builds, :order => Sequel.desc(:created_at)

    def self.get_authenticated(id, token)
      first id: id, token: token
    end
  end

  class Build < Sequel::Model
    many_to_one :job

    def is_success?
      status == "success"
    end
  end

end
