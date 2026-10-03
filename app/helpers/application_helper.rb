module ApplicationHelper
  # Round "←" button at the top left of a page, next to its title.
  # The label is read by screen readers and shown when hovering with a mouse.
  def back_button(path, label: "Retour")
    link_to "←", path, class: "back-button", title: label, aria: { label: label }
  end
end
