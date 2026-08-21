class Account::DataTransfer::ProjectRecordSet < Account::DataTransfer::RecordSet
  def initialize(account)
    super(account: account, model: ::Project)
  end

  private
    def check_record(file_path)
      super

      project = load(file_path)
      board = load_archive_record(::Board, project["board_id"])

      unless project["account_id"] == board["account_id"]
        raise IntegrityError, "Project record #{project['id']} account does not match Board #{board['id']}"
      end

      unless Color::COLORS.any? { |color| color.value == project["color"] }
        raise IntegrityError, "Project record #{project['id']} has an invalid color"
      end
    end
end
