module ProjectsHelper
  def project_cards_grouped_by_milestone(cards, closed:)
    cards
      .select { |card| card.closed? == closed }
      .sort_by { |card| project_card_order_key(card) }
      .group_by(&:milestone_id)
  end

  def project_card_stage(card)
    if card.closed?
      "Done"
    elsif card.postponed?
      "Not Now"
    elsif card.awaiting_triage?
      "Maybe"
    else
      card.column.name
    end
  end

  private
    def project_card_order_key(card)
      if card.closed?
        [ 3, 0, 0, -card.closed_at.to_f, card.id ]
      elsif card.postponed?
        [ 0, 0, 0, -card.last_active_at.to_f, card.id ]
      elsif card.awaiting_triage?
        [ 1, 0, card.golden? ? 0 : 1, -card.last_active_at.to_f, card.id ]
      else
        [ 2, card.column.position, card.golden? ? 0 : 1, -card.last_active_at.to_f, card.id ]
      end
    end
end
