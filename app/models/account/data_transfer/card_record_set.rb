class Account::DataTransfer::CardRecordSet < Account::DataTransfer::RecordSet
  def initialize(account)
    super(account: account, model: ::Card)
  end

  private
    def check_record(file_path)
      super

      card = load(file_path)
      board = load_archive_record(::Board, card["board_id"])
      check_board(card, board)
      check_project(card) if card["project_id"].present?
      check_milestone(card) if card["milestone_id"].present?
    end

    def check_board(card, board)
      unless card["account_id"] == board["account_id"]
        raise IntegrityError, "Card record #{card['id']} account does not match Board #{board['id']}"
      end
    end

    def check_project(card)
      project = load_archive_record(::Project, card["project_id"])

      unless project["board_id"] == card["board_id"] && project["account_id"] == card["account_id"]
        raise IntegrityError, "Card record #{card['id']} does not match Project #{project['id']}"
      end
    end

    def check_milestone(card)
      unless card["project_id"].present?
        raise IntegrityError, "Card record #{card['id']} has a Milestone without a Project"
      end

      milestone = load_archive_record(::Milestone, card["milestone_id"])

      unless milestone["project_id"] == card["project_id"] && milestone["account_id"] == card["account_id"]
        raise IntegrityError, "Card record #{card['id']} does not match Milestone #{milestone['id']}"
      end
    end
end
