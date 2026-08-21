module Project::Colored
  extend ActiveSupport::Concern

  DEFAULT_COLOR = Color::COLORS.first

  included do
    before_validation :set_default_color
    validate :color_is_from_palette
  end

  def color
    Color.for_value(super) || DEFAULT_COLOR
  end

  private
    def set_default_color
      self[:color] ||= DEFAULT_COLOR.value
    end

    def color_is_from_palette
      unless Color::COLORS.any? { |color| color.value == self[:color] }
        errors.add :color, "is not in the palette"
      end
    end
end
