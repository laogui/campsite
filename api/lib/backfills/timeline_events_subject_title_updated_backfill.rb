# frozen_string_literal: true

module Backfills
  class TimelineEventsSubjectTitleUpdatedBackfill
    def self.run(dry_run: true)
      scope = TimelineEvent.where(action: :post_title_updated)
      count = dry_run ? scope.count : scope.update_all(action: :subject_title_updated)

      "#{dry_run ? "Would have updated" : "Updated"} #{count} TimelineEvent #{"record".pluralize(count)}"
    end
  end
end
