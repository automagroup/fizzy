class Project < ApplicationRecord
  include Colored, Filterable

  belongs_to :account, default: -> { board.account }
  belongs_to :board, touch: true

  has_many :milestones, dependent: :destroy
  has_many :cards, dependent: :nullify

  validates :name, :due_on, presence: true
  validate :account_matches_board

  after_save_commit -> { cards.touch_all }, if: -> { saved_change_to_name? || saved_change_to_color? }
  after_destroy_commit -> { board.cards.touch_all }

  scope :chronologically, -> { order(:due_on).order("lower(projects.name)") }

  private
    def account_matches_board
      if account && board && account != board.account
        errors.add :account, "must match the board account"
      end
    end
end
