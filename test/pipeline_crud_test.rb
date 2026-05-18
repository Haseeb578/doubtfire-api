require_relative "../config/environment"
require "minitest/autorun"

class PipelineCrudTest < Minitest::Test
  def test_pipeline_can_create_read_update_and_delete_an_activity_type
    activity = ActivityType.create!(
      name: "Pipeline Test Activity",
      abbreviation: "PTA"
    )

    found = ActivityType.find(activity.id)
    assert_equal "Pipeline Test Activity", found.name

    found.update!(name: "Updated Pipeline Activity")
    assert_equal "Updated Pipeline Activity", ActivityType.find(activity.id).name

    found.destroy!
    assert_nil ActivityType.find_by(id: activity.id)
  end
end
