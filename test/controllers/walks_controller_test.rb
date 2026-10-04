require "test_helper"

class WalksControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in users(:mika)
  end

  test "lists my walks, with a map picture for tracked ones" do
    get walks_path
    assert_response :success
    assert_select "h2", "Octobre 2026"
    assert_select "img[src^='https://api.mapbox.com/'][loading='lazy']", 1
    assert_select "span[aria-label='Balade sans trajet GPS']", 1
    assert_select ".navbar-bottom a.active[aria-current='page']", /Balades/
    # Bootstrap's py-3 (!important) once hid the end of pages under the tab bar.
    assert_select "main.with-navbar-bottom:not(.py-3):not(.pb-3)"
  end

  test "shows a walk with its GPS track on the map" do
    get walk_path(walks(:evening))
    assert_response :success
    assert_select "[data-controller='map'][data-map-track-value='[[1.5012,48.4206],[1.502,48.4211]]']"
  end

  test "shows the dogs met on the map, numbered in time order" do
    get walk_path(walks(:evening))
    markers = JSON.parse(css_select("[data-controller='map']").first["data-map-encounters-value"])
    assert_equal [ { "label" => "1", "times" => [ "18h12" ], "coordinates" => [ 1.5015, 48.4208 ] } ], markers
  end

  test "shows the play and swim phases of a walk" do
    get walk_path(walks(:evening))
    assert_select "p", "🎾 12 min de jeu"
    assert_select "p", "💦 1 baignade (8 min)"
    markers = JSON.parse(css_select("[data-controller='map']").first["data-map-activities-value"])
    assert_equal [ { "icon" => "🎾", "times" => "18h10–18h22", "coordinates" => [ 1.5016, 48.4209 ] } ], markers
  end

  test "lists the dogs met, with a link to add details" do
    get walk_path(walks(:evening))
    first = css_select("a.encounter-card[href='#{edit_walk_encounter_path(walks(:evening), encounters(:first))}']").first
    assert_equal [ "1", "18h12", "Sid, Malinois" ],
                 [ ".encounter-number", "strong", ".encounter-details" ].map { |selector| first.at_css(selector).text.strip }
    assert_select ".encounter-list .encounter-card", 2
    assert_select ".encounter-card .encounter-no-position", "Position inconnue"
  end

  test "congratulates right after finishing a tracked walk" do
    get walk_path(walks(:evening), finished: true)
    assert_select "strong", "Bravo ! Balade terminée 🎉"
    assert_select "h2", "Rencontres (facultatif)"
  end

  test "lists the play and swim phases, each with a delete button" do
    get walk_path(walks(:evening))
    assert_select ".item-card", 2
    assert_select ".item-card", /Baignade\s+18h20 → 18h28\s+· 8 min/
    assert_select "form[action='#{walk_activity_path(walks(:evening), activities(:swim))}'] button.item-card-delete"
  end

  test "invites to add notes when there are none" do
    get walk_path(walks(:evening))
    assert_select "a[href='#{edit_walk_notes_path(walks(:evening))}']", /Ajouter des notes/
  end

  test "shows the moods and the comment of a walk" do
    walks(:evening).update!(moods: %w[happy annoying], comment: "Très joueur")
    get walk_path(walks(:evening))
    assert_equal [ "😊 Joyeux", "😤 Chiant" ], css_select(".walk-mood-tag").map { |tag| tag.text.strip }
    assert_select ".walk-comment", "Très joueur"
  end

  test "shows a walk entered by hand without a map nor cut link" do
    get walk_path(walks(:morning))
    assert_response :success
    assert_select "[data-controller='map']", count: 0
    assert_select ".walk-action", text: /Couper la fin/, count: 0
    assert_select ".walk-action", 2
  end

  test "offers to cut the end of a tracked walk" do
    get walk_path(walks(:evening))
    assert_select "a.walk-action[href='#{edit_walk_trim_path(walks(:evening))}']", /Couper la fin/
    assert_select ".walk-action", 3
    assert_select ".title-row a.back-button[href='#{walks_path}'][aria-label='Retour'] svg"
  end

  test "creates a walk entered by hand" do
    assert_difference "Walk.count", 1 do
      post walks_path, params: { walk: { started_at: "2026-10-02T18:05", duration_minutes: "35",
                                         distance_km: "2,3", dogs_met_count: "4" } }
    end
    walk = Walk.last
    assert_redirected_to walk_path(walk)
    assert_equal 2300, walk.distance_meters
    assert_not walk.tracked
  end

  test "does not create a walk without a duration" do
    assert_no_difference "Walk.count" do
      post walks_path, params: { walk: { started_at: "2026-10-02T18:05", duration_minutes: "" } }
    end
    assert_response :unprocessable_content
    assert_select "li", "Durée doit être rempli(e)"
  end

  test "updates a walk" do
    patch walk_path(walks(:evening)), params: { walk: { dogs_met_count: "5" } }
    assert_redirected_to walk_path(walks(:evening))
    assert_equal 5, walks(:evening).reload.dogs_met_count
  end

  test "deletes a walk" do
    assert_difference "Walk.count", -1 do
      delete walk_path(walks(:evening))
    end
    assert_redirected_to walks_path
  end

  test "cannot open the walk of another account" do
    get walk_path(walks(:strangers_walk))
    assert_response :not_found
  end
end
