require "test_helper"

class WalkNotesControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in users(:mika)
    @walk = walks(:evening)
  end

  test "shows the moods as check buttons" do
    get edit_walk_notes_path(@walk)
    assert_response :success
    assert_select "input[type='checkbox'].btn-check", Walk::MOODS.size
  end

  test "saves several moods and a comment" do
    patch walk_notes_path(@walk), params: { walk: { moods: [ "", "energetic", "annoying" ], comment: "A tiré en laisse" } }
    assert_redirected_to walk_path(@walk)
    assert_equal [ %w[energetic annoying], "A tiré en laisse" ], @walk.reload.values_at(:moods, :comment)
    follow_redirect!
    assert_select ".alert-success.flash[data-controller='flash']", "Notes enregistrées."
    assert_select ".section-header a.small-action[href='#{edit_walk_notes_path(@walk)}']", "✏️ Modifier"
  end

  test "unchecking every mood empties the list" do
    @walk.update!(moods: %w[calm])
    patch walk_notes_path(@walk), params: { walk: { moods: [ "" ] } }
    assert_empty @walk.reload.moods
  end

  test "refuses an unknown mood" do
    patch walk_notes_path(@walk), params: { walk: { moods: %w[grumpy] } }
    assert_response :unprocessable_content
    assert_select "li", "Humeur n'est pas dans la liste"
  end

  test "cannot edit the notes of another account's walk" do
    get edit_walk_notes_path(walks(:strangers_walk))
    assert_response :not_found
  end
end
