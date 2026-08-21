class Milestone < ApplicationRecord
  belongs_to :account, default: -> { project.account }
  belongs_to :project, touch: true

  has_many :cards, dependent: :nullify

  validates :name, :due_on, presence: true
  validate :account_matches_project

  after_save_commit -> { cards.touch_all }, if: :saved_change_to_name?
  after_destroy_commit :touch_board_cards, unless: :destroyed_by_association

  scope :chronologically, -> { order(:due_on).order("lower(milestones.name)") }

  delegate :board, :color, to: :project

  private
    def account_matches_project
      if account && project && account != project.account
        errors.add :account, "must match the project account"
      end
    end

    def touch_board_cards
      board.cards.touch_all
    end
end
