module ApplicationHelper
  # Round back button at the top left of a page, next to its title.
  # The arrow is a small SVG drawing (not the "←" character): a font places its characters
  # slightly off-center, a drawing is exactly centered in the circle.
  # The label is read by screen readers and shown when hovering with a mouse.
  def back_button(path, label: "Retour")
    link_to path, class: "back-button", title: label, aria: { label: label } do
      tag.svg(width: 22, height: 22, viewBox: "0 0 24 24", fill: "none", stroke: "currentColor",
              "stroke-width": 2.5, "stroke-linecap": "round", "stroke-linejoin": "round", aria: { hidden: true }) do
        tag.path(d: "M19 12H5M11 5l-7 7 7 7")
      end
    end
  end
end
