require "application_system_test_case"

class CardProjectPickerTest < ApplicationSystemTestCase
  test "assigning and removing a project from the card picker" do
    card = cards(:text)
    project = projects(:website_redesign)
    milestone = milestones(:design_signoff)
    sign_in_as(users(:jz))

    visit card_url(card)
    click_on "Add to project"

    assert_selector "dialog[open] turbo-frame##{dom_id(card, :project_picker)}"
    assert_current_path card_path(card)

    trigger_rect, dialog_rect = page.evaluate_script(<<~JS)
      (() => {
        const trigger = document.querySelector(".card-project-badge__edit").getBoundingClientRect()
        const dialog = document.querySelector("dialog[open]").getBoundingClientRect()

        return [
          { left: trigger.left, bottom: trigger.bottom },
          { left: dialog.left, top: dialog.top, width: dialog.width }
        ]
      })()
    JS
    assert_in_delta trigger_rect.fetch("left"), dialog_rect.fetch("left"), 1
    assert_in_delta trigger_rect.fetch("bottom"), dialog_rect.fetch("top"), 1
    assert_operator dialog_rect.fetch("width"), :>, 260

    send_keys :escape
    assert_no_selector "dialog[open]"

    send_keys "r"
    within "dialog[open]" do
      fill_in "Filter…", with: milestone.name
      find("button", text: milestone.name).click
    end

    assert_no_selector "dialog[open]"
    assert_current_path card_path(card)
    within "##{dom_id(card, :project_badges)}" do
      assert_text project.name
      assert_text milestone.name
    end

    page.driver.browser.manage.window.resize_to(390, 844)
    send_keys "r"

    dialog_rect = page.evaluate_script(<<~JS)
      (() => {
        const rect = document.querySelector("dialog[open]").getBoundingClientRect()
        return { left: rect.left, right: rect.right }
      })()
    JS
    viewport_width = page.evaluate_script("window.innerWidth")
    assert_operator dialog_rect.fetch("left"), :>=, 0
    assert_operator dialog_rect.fetch("right"), :<=, viewport_width

    within "dialog[open]" do
      click_on "Remove from project"
    end

    assert_no_selector "dialog[open]"
    assert_current_path card_path(card)
    within "##{dom_id(card, :project_badges)}" do
      assert_text "Add to project"
      assert_no_selector ".card-project-badge--project"
    end
  ensure
    page.driver.browser.manage.window.resize_to(1200, 1000)
  end

  test "assigning a project from a draft picker" do
    card = boards(:writebook).cards.create!(creator: users(:jz), status: :drafted)
    project = projects(:website_redesign)
    milestone = milestones(:design_signoff)
    sign_in_as(users(:jz))

    visit card_draft_url(card)
    click_on "Add to project"

    within "dialog[open] turbo-frame##{dom_id(card, :project_picker)}" do
      assert_text project.name
      assert_text milestone.name
      assert_no_selector ".turbo-frame-error"
      find("button", text: milestone.name).click
    end

    assert_no_selector "dialog[open]"
    assert_current_path card_draft_path(card)
    within "##{dom_id(card, :project_badges)}" do
      assert_text project.name
      assert_text milestone.name
    end
  end

  test "clicking outside closes the card picker" do
    card = cards(:text)
    sign_in_as(users(:jz))

    visit card_url(card)
    send_keys "r"
    assert_selector "dialog[open]"

    find("footer.card__footer").click

    assert_no_selector "dialog[open]"
    assert_current_path card_path(card)
  end

  test "assigning a project from the full-page fallback returns to the card" do
    card = cards(:text)
    milestone = milestones(:design_signoff)
    sign_in_as(users(:jz))

    visit edit_card_project_url(card)
    find("button", text: milestone.name).click

    assert_current_path card_path(card)
    assert_text milestone.name
  end
end
