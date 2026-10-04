class AddFriendToEncounters < ActiveRecord::Migration[8.1]
  def change
    # Optional: a dog met can be linked to a friend of the address book. If the friend is
    # deleted, the encounter stays (with its own dog_name and breed), only the link goes.
    add_reference :encounters, :friend, foreign_key: { on_delete: :nullify }
  end
end
