namespace :walks do
  # Only shows the changes. To save them: APPLY=1 bin/rails walks:recompute_distances
  desc "Recompute the distance of GPS walks with the current way of measuring"
  task recompute_distances: :environment do
    apply = ENV["APPLY"] == "1"
    km = ->(meters) { format("%.2f km", meters / 1000.0).tr(".", ",") }
    before_total = after_total = 0

    Walk.where(tracked: true).order(:started_at).each do |walk|
      next unless walk.track_points.exists?

      after = walk.track_distance
      puts "#{walk.started_at.strftime('%d/%m/%Y %Hh%M')}  #{km.call(walk.distance_meters)} → #{km.call(after)}"
      before_total += walk.distance_meters
      after_total += after
      walk.update!(distance_meters: after) if apply
    end

    puts "Total : #{km.call(before_total)} → #{km.call(after_total)}"
    puts apply ? "Distances enregistrées." : "Rien n'a été modifié (ajouter APPLY=1 pour enregistrer)."
  end
end
