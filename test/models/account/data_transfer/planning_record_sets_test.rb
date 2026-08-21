require "test_helper"

class Account::DataTransfer::PlanningRecordSetsTest < ActiveSupport::TestCase
  test "manifest uses planning record sets in dependency order" do
    record_sets = Account::DataTransfer::Manifest.new(Current.account).send(:record_sets)
    models = record_sets.map(&:model)

    assert_operator models.index(Board), :<, models.index(Project)
    assert_operator models.index(Project), :<, models.index(Milestone)
    assert_operator models.index(Milestone), :<, models.index(Column)
    assert_operator models.index(Column), :<, models.index(Card)
    assert_instance_of Account::DataTransfer::ProjectRecordSet, record_sets[models.index(Project)]
    assert_instance_of Account::DataTransfer::MilestoneRecordSet, record_sets[models.index(Milestone)]
    assert_instance_of Account::DataTransfer::CardRecordSet, record_sets[models.index(Card)]
  end

  test "project check accepts a project matching its archived board" do
    project = project_data
    board = board_data(id: project["board_id"])

    assert_nothing_raised do
      project_record_set.check(from: build_reader([ Project, project ], [ Board, board ]))
    end
  end

  test "project check rejects a missing board" do
    project = project_data

    error = assert_raises(integrity_error) do
      project_record_set.check(from: build_reader([ Project, project ]))
    end

    assert_match(/missing Board/, error.message)
  end

  test "project check rejects a board from another account" do
    project = project_data
    board = board_data(id: project["board_id"], account_id: new_id)

    error = assert_raises(integrity_error) do
      project_record_set.check(from: build_reader([ Project, project ], [ Board, board ]))
    end

    assert_match(/account does not match Board/, error.message)
  end

  test "project check rejects a color outside the palette" do
    project = project_data(color: "hotpink")
    board = board_data(id: project["board_id"])

    error = assert_raises(integrity_error) do
      project_record_set.check(from: build_reader([ Project, project ], [ Board, board ]))
    end

    assert_match(/invalid color/, error.message)
  end

  test "milestone check rejects a project from another account" do
    milestone = milestone_data
    project = project_data(id: milestone["project_id"], account_id: new_id)

    error = assert_raises(integrity_error) do
      milestone_record_set.check(from: build_reader([ Milestone, milestone ], [ Project, project ]))
    end

    assert_match(/account does not match Project/, error.message)
  end

  test "card check accepts matching board project and milestone" do
    project = project_data
    milestone = milestone_data(project_id: project["id"])
    card = card_data(project_id: project["id"], milestone_id: milestone["id"])
    board = board_data(id: card["board_id"])

    assert_nothing_raised do
      card_record_set.check(from: build_reader(
        [ Card, card ],
        [ Board, board ],
        [ Project, project ],
        [ Milestone, milestone ]
      ))
    end
  end

  test "card check rejects a project from another board" do
    project = project_data(board_id: new_id)
    card = card_data(project_id: project["id"])
    board = board_data(id: card["board_id"])

    error = assert_raises(integrity_error) do
      card_record_set.check(from: build_reader([ Card, card ], [ Board, board ], [ Project, project ]))
    end

    assert_match(/does not match Project/, error.message)
  end

  test "card check rejects a milestone from another project" do
    project = project_data
    milestone = milestone_data(project_id: new_id)
    card = card_data(project_id: project["id"], milestone_id: milestone["id"])
    board = board_data(id: card["board_id"])

    error = assert_raises(integrity_error) do
      card_record_set.check(from: build_reader(
        [ Card, card ],
        [ Board, board ],
        [ Project, project ],
        [ Milestone, milestone ]
      ))
    end

    assert_match(/does not match Milestone/, error.message)
  end

  test "card check rejects a milestone without a project" do
    card = card_data(project_id: nil, milestone_id: new_id)
    board = board_data(id: card["board_id"])

    error = assert_raises(integrity_error) do
      card_record_set.check(from: build_reader([ Card, card ], [ Board, board ]))
    end

    assert_match(/Milestone without a Project/, error.message)
  end

  private
    def importing_account
      @importing_account ||= Account.create!(name: "Importing Account")
    end

    def project_record_set
      Account::DataTransfer::ProjectRecordSet.new(importing_account)
    end

    def milestone_record_set
      Account::DataTransfer::MilestoneRecordSet.new(importing_account)
    end

    def card_record_set
      Account::DataTransfer::CardRecordSet.new(importing_account)
    end

    def integrity_error
      Account::DataTransfer::RecordSet::IntegrityError
    end

    def board_data(id: board_id, account_id: source_account_id)
      {
        "id" => id,
        "account_id" => account_id
      }
    end

    def project_data(**overrides)
      projects(:website_redesign).attributes.merge(
        "id" => project_id,
        "account_id" => source_account_id,
        "board_id" => board_id,
        "color" => Color::COLORS.first.value
      ).merge(overrides.stringify_keys)
    end

    def milestone_data(**overrides)
      milestones(:design_signoff).attributes.merge(
        "id" => milestone_id,
        "account_id" => source_account_id,
        "project_id" => project_id
      ).merge(overrides.stringify_keys)
    end

    def card_data(**overrides)
      cards(:buy_domain).attributes.merge(
        "id" => new_id,
        "account_id" => source_account_id,
        "board_id" => board_id,
        "creator_id" => new_id,
        "column_id" => nil,
        "project_id" => nil,
        "milestone_id" => nil
      ).merge(overrides.stringify_keys)
    end

    def build_reader(*records)
      tempfile = Tempfile.new([ "planning_import_test", ".zip" ])
      tempfile.binmode

      writer = ZipFile::Writer.new(tempfile)
      records.each do |model, data|
        writer.add_file("data/#{model.table_name}/#{data.fetch('id')}.json", data.to_json)
      end
      writer.close
      tempfile.rewind

      (@tempfiles ||= []) << tempfile
      ZipFile::Reader.new(tempfile)
    end

    def source_account_id
      @source_account_id ||= new_id
    end

    def board_id
      @board_id ||= new_id
    end

    def project_id
      @project_id ||= new_id
    end

    def milestone_id
      @milestone_id ||= new_id
    end

    def new_id
      ActiveRecord::Type::Uuid.generate
    end

    def teardown
      @tempfiles&.each { |file| file.close; file.unlink }
      @importing_account&.destroy
    end
end
