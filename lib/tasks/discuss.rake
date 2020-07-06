namespace :discuss do
  desc "Creates x discussions for your first project, create a project if non exists. 'x' can be set as a rake option (rake discuss:generate_discussions[4]"
  task :generate_discussions, [:number, :author_id] => :environment do |task, args|
    project = Project.first
    project ||= Project.create(name: "Project with sample discussions")

    if args[:author_id].present?
      user = User.find(args[:author_id])
    else
      user = User.first
    end

    args[:number].to_i.times do |i|
      discussion = project.discussions.create(subject: "Discussion #{i}", author_id: user.id)
      if discussion.errors.any?
        p discussion.errors.full_messages
        raise "Errors while saving discussion, look at above errors"
      end
    end

    puts "Successfully generated #{args[:number]} discussions"
  end
end
