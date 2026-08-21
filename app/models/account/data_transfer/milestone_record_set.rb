class Account::DataTransfer::MilestoneRecordSet < Account::DataTransfer::RecordSet
  def initialize(account)
    super(account: account, model: ::Milestone)
  end

  private
    def check_record(file_path)
      super

      milestone = load(file_path)
      project = load_archive_record(::Project, milestone["project_id"])

      unless milestone["account_id"] == project["account_id"]
        raise IntegrityError, "Milestone record #{milestone['id']} account does not match Project #{project['id']}"
      end
    end
end
