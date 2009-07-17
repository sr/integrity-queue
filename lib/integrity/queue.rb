module Integrity
  module Queue
    class Buildable < Integrity::BuildableProject
      def build
        @project.commits.first_or_create({:identifier => @commit},
          {:project_id => @project.id})
      end
    end

    class Builder
      def self.build
        # TODO: Use SQL instead of Enumerable :-)
        if commit = Commit.all.detect { |commit| commit.pending? }
          BuildableProject.new(commit.project, commit.identifier).build
        end
      end
    end
  end
end
